import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveTrackingMap extends StatefulWidget {
  const LiveTrackingMap({super.key});

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> {
  // Asset Icons Caching System: ලෝඩ් කරගන්නා PNG අයිකන් මෙමරියේ සුරැකීමට
  final Map<String, BitmapDescriptor> _cachedVehicleIcons = {};
  bool _isEngineReady = false;

  static const LatLng _sriLankaCenter = LatLng(7.8731, 80.7718);

  @override
  void initState() {
    super.initState();
    _loadVehicleAssetIcons();
  }

  // =========================================================================
  // 🗂️ ASSET IMAGE LOADER ENGINE: PNG පින්තූර ලෝඩ් කරගැනීම (v2.17.1 Compatible)
  // =========================================================================
  Future<void> _loadVehicleAssetIcons() async {
    // 💡 FIXED: ඩේටාබේස් එකෙන් හැදෙන '6_seater' වගේ කීස් කෙලින්ම ඔයාගේ අලුත් පින්තූර වලට ලින්ක් කළා මචං!
    final Map<String, String> iconPaths = {
      'budget': 'assets/vehicle_icons/budget_marker.png',
      'mini': 'assets/vehicle_icons/mini_marker.png',
      'sedan': 'assets/vehicle_icons/sedan_marker.png',

      // 🎯 මෙන්න මෙහෙමයි තියෙන්න ඕනේ මචං. එතකොටයි යට ලොජික් එකට අහුවෙන්නේ!
      '6_seater': 'assets/vehicle_icons/mini_van_marker.png',
      '9_seater': 'assets/vehicle_icons/flatRoof_marker.png',
      '14_seater': 'assets/vehicle_icons/highRoof_marker.png',
    };

    try {
      for (var entry in iconPaths.entries) {
        // ignore: deprecated_member_use
        final BitmapDescriptor icon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(45, 45)),
          entry.value,
        );
        _cachedVehicleIcons[entry.key] = icon;
      }
      debugPrint("✅ ADMIN MAP ENGINE: මෙමරියට සාර්ථකව ලෝඩ් වුණු මුළු අයිකන්ස් ගණන: ${_cachedVehicleIcons.keys.length}");
    } catch (e) {
      debugPrint("❌ ASSET LOGO ERROR: පින්තූර ලෝඩ් වෙද්දී අවුලක් ආවා මචං: $e");
    }

    if (mounted) {
      setState(() {
        _isEngineReady = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEngineReady) {
      return const Center(child: CircularProgressIndicator(color: Colors.blueGrey, strokeWidth: 2.5));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('member')
          .where('onlineStatus', isEqualTo: 'online')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueGrey, strokeWidth: 2.5));
        }

        final docs = snapshot.data!.docs;

        return FutureBuilder<List<Marker>>(
          future: _buildDriverMarkersWithVehicles(docs),
          builder: (context, futureSnapshot) {
            final Set<Marker> mapMarkers = Set.from(futureSnapshot.data ?? []);

            return GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _sriLankaCenter,
                zoom: 7.5,
              ),
              zoomControlsEnabled: true,
              mapType: MapType.normal,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              markers: mapMarkers,
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // 🔄 REAL-TIME DYNAMIC COUPLER: /vehicles/ එකෙන් කියවා නිවැරදි Asset එක සෙට් කිරීම
  // =========================================================================
  Future<List<Marker>> _buildDriverMarkersWithVehicles(List<QueryDocumentSnapshot> memberDocs) async {
    final List<Marker> markersList = [];

    for (var doc in memberDocs) {
      final memberData = doc.data() as Map<String, dynamic>;
      final String driverId = doc.id;

      if (memberData['latitude'] != null && memberData['longitude'] != null) {
        final double lat = double.tryParse(memberData['latitude'].toString()) ?? 0.0;
        final double lng = double.tryParse(memberData['longitude'].toString()) ?? 0.0;
        final double heading = double.tryParse(memberData['bearing'].toString()) ?? double.tryParse(memberData['heading'].toString()) ?? 0.0;
        final String name = memberData['fullName'] ?? 'Unknown Driver';

        String categoryKey = 'budget';
        String plateNumber = '-';
        String modelName = '-';

        try {
          var vehicleDoc = await FirebaseFirestore.instance.collection('vehicles').doc(driverId).get();

          if (vehicleDoc.exists && vehicleDoc.data() != null) {
            final vehicleData = vehicleDoc.data()!;

            if (vehicleData['selectedCategory'] != null) {
              String rawCategory = vehicleData['selectedCategory'].toString().toLowerCase().trim();
              rawCategory = rawCategory.replaceAll(RegExp(r'\s+'), ' ');
              // 💡 ඩේටාබේස් එකේ '6 Seater' කියන එක '6_seater' වෙනවා.
              // ඒක කෙලින්ම උඩ තියෙන '6_seater' එකට මැච් වෙලා 'mini_van_marker.png' එක ලෝඩ් කරගන්නවා මචං!
              categoryKey = rawCategory.replaceAll(' ', '_');
            }

            if (vehicleData['documents'] != null && vehicleData['documents'] is List && (vehicleData['documents'] as List).length > 2) {
              var regBookMap = vehicleData['documents'][2];
              if (regBookMap['reviewData'] != null && regBookMap['reviewData']['Plate Number'] != null) {
                plateNumber = regBookMap['reviewData']['Plate Number'].toString();
              }
            }

            if (plateNumber == '-' && vehicleData['details'] != null && vehicleData['details']['plateNumber'] != null) {
              plateNumber = vehicleData['details']['plateNumber'].toString();
            }

            if (vehicleData['details'] != null && vehicleData['details']['model'] != null) {
              modelName = vehicleData['details']['model'].toString();
            }
          }
        } catch (e) {
          debugPrint("Error loading assets configuration driver map for $driverId: $e");
        }

        final BitmapDescriptor mappedIcon = _cachedVehicleIcons[categoryKey] ?? BitmapDescriptor.defaultMarker;

        if (lat != 0.0 && lng != 0.0) {
          markersList.add(
            Marker(
              markerId: MarkerId(driverId),
              position: LatLng(lat, lng),
              rotation: heading,
              flat: true,
              anchor: const Offset(0.5, 0.5),
              icon: mappedIcon,
              infoWindow: InfoWindow(
                title: name,
                snippet: "Vehicle: $plateNumber ($modelName) | Category: ${categoryKey.toUpperCase().replaceAll('_', ' ')} | Status: ${memberData['isAvailable'] == false ? 'ON TRIP' : 'AVAILABLE'}",
              ),
            ),
          );
        }
      }
    }
    return markersList;
  }
}