import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_admin_dashboard/core/providers/member_provider.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/scheduled_bookings/widgets/booking_timeline.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// BookingDetailDialog
// Admin Panel - Click කළ booking card ගෙ full detail + live map popup
// ═══════════════════════════════════════════════════════════════════════════════

class BookingDetailDialog extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  const BookingDetailDialog({super.key, required this.bookingData});

  @override
  Widget build(BuildContext context) {
    final String bookingId = bookingData['id'] ?? '';

    if (bookingId.isEmpty) {
      return _buildDialogContent(context, bookingData);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('all_bookings')
          .doc(bookingId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildDialogContent(context, bookingData);
        }
        final Map<String, dynamic> liveData =
            snapshot.data!.data() as Map<String, dynamic>;
        liveData['id'] = snapshot.data!.id;

        return _buildDialogContent(context, liveData);
      },
    );
  }

  Widget _buildDialogContent(BuildContext context, Map<String, dynamic> data) {
    final String status = (data['status'] ?? '').toString().toLowerCase();

    // ── Parse coordinates ──────────────────────────────────────────────────
    LatLng? pickupPoint;
    LatLng? dropPoint;

    final pickupLoc = data['pickupLocation'];
    if (pickupLoc is Map) {
      final lat = _toDouble(pickupLoc['latitude'] ?? pickupLoc['lat']);
      final lng = _toDouble(pickupLoc['longitude'] ?? pickupLoc['lng']);
      if (lat != 0 && lng != 0) pickupPoint = LatLng(lat, lng);
    } else {
      final lat = _toDouble(data['startLat'] ?? data['pickupLat']);
      final lng = _toDouble(data['startLng'] ?? data['pickupLng']);
      if (lat != 0 && lng != 0) pickupPoint = LatLng(lat, lng);
    }

    final dropLoc = data['dropLocation'];
    if (dropLoc is Map) {
      final lat = _toDouble(dropLoc['latitude'] ?? dropLoc['lat']);
      final lng = _toDouble(dropLoc['longitude'] ?? dropLoc['lng']);
      if (lat != 0 && lng != 0) dropPoint = LatLng(lat, lng);
    } else {
      final lat = _toDouble(data['endLat'] ?? data['dropLat']);
      final lng = _toDouble(data['endLng'] ?? data['dropLng']);
      if (lat != 0 && lng != 0) dropPoint = LatLng(lat, lng);
    }

    // ── Driver membership number (acceptedBy = driver's member doc ID) ──────
    final String? driverMemberId = (data['acceptedBy'] ?? data['driverId'])
        ?.toString();

    final String tripId = data['tripId'] ?? data['bookingId'] ?? 'N/A';
    final String cancelReason = data['cancelReason'] ?? 'No reason provided';
    final String cancelledBy = data['cancelledBy'] ?? 'Unknown';
    final String passengerName = data['memberName'] ?? data['memberId'] ?? '';
    final String driverName = data['driverName'] ?? driverMemberId ?? '';

    debugPrint(
      '📦 BookingDetailDialog: status=$status driverId=$driverMemberId '
      'pickup=$pickupPoint drop=$dropPoint',
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: SizedBox(
          height: 640,
          child: Column(
            children: [
              // ── Title bar ────────────────────────────────────────────────
              _TitleBar(
                tripId: tripId,
                status: status,
                passengerName: passengerName,
                driverName: driverName,
              ),

              // ── Info banners ─────────────────────────────────────────────
              if (status == 'cancelled')
                _Banner(
                  color: Colors.red,
                  icon: Icons.cancel_outlined,
                  text: 'Cancelled by $cancelledBy  •  Reason: $cancelReason',
                ),

              // ── Main Content Area ─────────────────────────────────────────
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: Row(
                    children: [
                      BookingTimeline(data: data),
                      Expanded(
                        child: _buildMapForStatus(
                          status: status,
                          pickupPoint: pickupPoint,
                          dropPoint: dropPoint,
                          driverMemberId: driverMemberId,
                          data: data,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapForStatus({
    required String status,
    required LatLng? pickupPoint,
    required LatLng? dropPoint,
    required String? driverMemberId,
    required Map<String, dynamic> data,
  }) {
    // Ongoing Pickup → Live tracking map
    if (status == 'ongoing pickup' &&
        driverMemberId != null &&
        driverMemberId.isNotEmpty &&
        pickupPoint != null) {
      return _OngoingPickupMap(
        driverMemberId: driverMemberId,
        passengerLocation: pickupPoint,
        dropLocation: dropPoint,
        data: data,
      );
    }

    // Ongoing Drop → Live tracking to drop point
    if (status == 'ongoing drop' &&
        driverMemberId != null &&
        driverMemberId.isNotEmpty &&
        dropPoint != null) {
      return _OngoingPickupMap(
        driverMemberId: driverMemberId,
        passengerLocation: pickupPoint,
        dropLocation: dropPoint,
        isDropPhase: true,
        data: data,
      );
    }

    // Completed → Static route + time taken
    if (status == 'completed') {
      return _HistoricalMapView(
        pickupPoint: pickupPoint,
        dropPoint: dropPoint,
        data: data,
      );
    }

    // Default static map
    return _HistoricalMapView(
      pickupPoint: pickupPoint,
      dropPoint: dropPoint,
      data: data,
    );
  }

  static double _toDouble(dynamic v) =>
      double.tryParse(v?.toString() ?? '0') ?? 0.0;
}

// ─── Coordinate parser: handles double / int / String / GeoPoint ──────────────
double _parseCoord(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  // Firestore GeoPoint stored as object with latitude / longitude getters
  try {
    final lat = (v as dynamic).latitude;
    if (lat is double) return lat;
    if (lat is int) return lat.toDouble();
  } catch (_) {}
  try {
    final lng = (v as dynamic).longitude;
    if (lng is double) return lng;
    if (lng is int) return lng.toDouble();
  } catch (_) {}
  return double.tryParse(v.toString()) ?? 0.0;
}

// ═══════════════════════════════════════════════════════════════════════════════
// 🟢 _OngoingPickupMap
// Live tracking: Driver → Passenger (Ongoing Pickup) or Driver → Drop (Ongoing Drop)
// Features:
//   • Driver marker moving live
//   • Passenger / Drop marker static
//   • Blue route polyline (Directions API)
//   • Grey breadcrumb trail (driver's travelled path)
//   • ETA overlay (distance + time, updates with each position change)
//   • Camera auto-follows driver
// ═══════════════════════════════════════════════════════════════════════════════

class _OngoingPickupMap extends StatefulWidget {
  final String driverMemberId;
  final LatLng? passengerLocation;
  final LatLng? dropLocation;
  final bool isDropPhase;
  final Map<String, dynamic> data;

  const _OngoingPickupMap({
    required this.driverMemberId,
    required this.passengerLocation,
    this.dropLocation,
    this.isDropPhase = false,
    required this.data,
  });

  @override
  State<_OngoingPickupMap> createState() => _OngoingPickupMapState();
}

class _OngoingPickupMapState extends State<_OngoingPickupMap> {
  // ── Route & Map state ─────────────────────────────────────────────────────
  GoogleMapController? _mapController;

  BitmapDescriptor? _driverIcon;

  Future<void> _loadDriverIcon() async {
    final String vc =
        (widget.data['vehicleCategory'] ??
                (widget.data['vehicle'] != null
                    ? widget.data['vehicle']['name']
                    : 'mini'))
            .toString()
            .toLowerCase();

    String assetPath = 'assets/vehicle_icons/mini_marker.png';
    if (vc.contains('budget'))
      assetPath = 'assets/vehicle_icons/budget_marker.png';
    else if (vc.contains('sedan'))
      assetPath = 'assets/vehicle_icons/sedan_marker.png';
    else if (vc.contains('6'))
      assetPath = 'assets/vehicle_icons/mini_van_marker.png';
    else if (vc.contains('9'))
      assetPath = 'assets/vehicle_icons/flatRoof_marker.png';
    else if (vc.contains('14'))
      assetPath = 'assets/vehicle_icons/highRoof_marker.png';

    final icon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      assetPath,
    );
    if (mounted) setState(() => _driverIcon = icon);
  }

  @override
  void initState() {
    super.initState();
    _loadDriverIcon();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  // Live route to destination (from Directions API)
  List<LatLng> _routeToDestination = [];
  bool _routeFetched = false;
  bool _fetchingRoute = false;

  // Breadcrumb trail of driver's travelled positions
  final List<LatLng> _breadcrumb = [];
  LatLng? _lastDriverPos;

  // For ETA calculation
  double _distanceKm = 0;
  int _etaMins = 0;

  static const String _apiKey = 'AIzaSyD2ZaITIFYTcb1fThVzChQYJ-cHm0aZ2iE';

  LatLng get _targetPoint => widget.isDropPhase
      ? (widget.dropLocation ?? const LatLng(7.8731, 80.7718))
      : (widget.passengerLocation ?? const LatLng(7.8731, 80.7718));

  // ── Fetch road route via Google Directions API ────────────────────────────
  Future<void> _fetchRoute(LatLng origin) async {
    if (_fetchingRoute || _routeFetched) return;
    _fetchingRoute = true;

    final targetUrl =
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${_targetPoint.latitude},${_targetPoint.longitude}'
        '&mode=driving'
        '&key=$_apiKey';

    final url = Uri.parse(
      'https://api.allorigins.win/raw?url=' + Uri.encodeComponent(targetUrl),
    );

    debugPrint('🗺️ Requesting route (CORS proxy): $url');

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      debugPrint('🗺️ Directions status: ${res.statusCode}');
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final apiStatus = body['status'] as String? ?? '';
        debugPrint('🗺️ Route API status: $apiStatus');
        if (apiStatus == 'OK') {
          final routes = body['routes'] as List;
          if (routes.isNotEmpty) {
            final polyStr = routes[0]['overview_polyline']['points'] as String;
            final decoded = _decodePoly(polyStr);
            debugPrint('🗺️ Decoded ${decoded.length} route points');
            if (mounted) {
              setState(() {
                _routeToDestination = decoded;
                _routeFetched = true;
              });
              // Fit camera to show driver + destination
              _fitBounds([origin, _targetPoint]);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('🗺️ Route fetch error: $e');
    } finally {
      _fetchingRoute = false;
    }
  }

  // ── Camera: fit to show all relevant markers ───────────────────────────────
  void _fitBounds(List<LatLng> pts) {
    if (_mapController == null || pts.isEmpty) return;
    final minLat = pts.map((p) => p.latitude).reduce(min);
    final maxLat = pts.map((p) => p.latitude).reduce(max);
    final minLng = pts.map((p) => p.longitude).reduce(min);
    final maxLng = pts.map((p) => p.longitude).reduce(max);
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.005, minLng - 0.005),
          northeast: LatLng(maxLat + 0.005, maxLng + 0.005),
        ),
        60,
      ),
    );
  }

  // ── Google encoded polyline decoder ───────────────────────────────────────
  List<LatLng> _decodePoly(String poly) {
    final pts = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < poly.length) {
      int b, shift = 0, result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      shift = 0;
      result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      pts.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return pts;
  }

  // ── Haversine distance in km ───────────────────────────────────────────────
  double _haversine(LatLng a, LatLng b) {
    const p = pi / 180.0;
    final dlat = (b.latitude - a.latitude) * p;
    final dlng = (b.longitude - a.longitude) * p;
    final hav =
        sin(dlat / 2) * sin(dlat / 2) +
        cos(a.latitude * p) *
            cos(b.latitude * p) *
            sin(dlng / 2) *
            sin(dlng / 2);
    return 12742 * asin(sqrt(hav));
  }

  @override
  Widget build(BuildContext context) {
    // ── Resolve Firebase UID from MemberProvider (already in memory) ──────
    //    MemberProvider stores all members. Each has:
    //      data['membershipNo'] = membership number OR doc.id as fallback
    //      data['doc_id']       = Firebase UID (actual Firestore document ID)
    //    We use doc_id to stream the live-location document directly.
    String? driverFirebaseUid;
    try {
      final members = Provider.of<MemberProvider>(
        context,
        listen: false,
      ).allMembersList;
      final match = members.firstWhere(
        (m) =>
            m['membershipNo']?.toString() == widget.driverMemberId ||
            m['doc_id']?.toString() == widget.driverMemberId,
        orElse: () => {},
      );
      if (match.isNotEmpty) {
        driverFirebaseUid = match['doc_id']?.toString();
        debugPrint(
          '🔑 Resolved ${widget.driverMemberId} → UID=$driverFirebaseUid',
        );
      } else {
        debugPrint(
          '⚠️ Could not find member in provider for ${widget.driverMemberId}',
        );
      }
    } catch (e) {
      debugPrint('⚠️ Provider lookup failed: $e');
    }

    // Choose stream: direct by UID (fast) or query by membershipNo (fallback)
    final Stream<QuerySnapshot> locationStream = driverFirebaseUid != null
        ? FirebaseFirestore.instance
              .collection('member')
              .where(FieldPath.documentId, isEqualTo: driverFirebaseUid)
              .limit(1)
              .snapshots()
        : FirebaseFirestore.instance
              .collection('member')
              .where('membershipNo', isEqualTo: widget.driverMemberId)
              .limit(1)
              .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: locationStream,
      builder: (context, snap) {
        LatLng? driverPos;
        double heading = 0;

        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          final d = snap.data!.docs.first.data() as Map<String, dynamic>;

          debugPrint('🟢 Live location doc keys: ${d.keys.toList()}');
          debugPrint(
            '🔍 lat=${d['latitude']}  lng=${d['longitude']}  '
            'bearing=${d['bearing']}  heading=${d['heading']}',
          );

          final dLat = _parseCoord(
            d['latitude'] ?? d['currentLat'] ?? d['lat'],
          );
          final dLng = _parseCoord(
            d['longitude'] ?? d['currentLng'] ?? d['lng'],
          );
          heading =
              double.tryParse(
                d['bearing']?.toString() ?? d['heading']?.toString() ?? '0',
              ) ??
              0.0;

          debugPrint('🔍 parsed → dLat=$dLat  dLng=$dLng');

          if (dLat != 0 && dLng != 0) {
            driverPos = LatLng(dLat, dLng);
          }
        } else {
          debugPrint(
            '⚠️ Live location snap: hasData=${snap.hasData}  '
            'docCount=${snap.data?.docs.length}  error=${snap.error}',
          );
        }

        // ── Update breadcrumb + ETA when driver moves ─────────────────────
        if (driverPos != null) {
          final isNew =
              _lastDriverPos == null ||
              _haversine(_lastDriverPos!, driverPos) > 0.005; // >5m moved

          if (isNew) {
            // Accumulate breadcrumb
            if (_breadcrumb.isEmpty || _breadcrumb.last != driverPos) {
              _breadcrumb.add(driverPos);
            }
            _lastDriverPos = driverPos;

            // Recalculate distance & ETA
            _distanceKm = _haversine(driverPos, _targetPoint);
            _etaMins = (_distanceKm * 2.4).ceil(); // ~25 km/h urban average

            // Fetch route once we have driver position
            if (!_routeFetched && !_fetchingRoute) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fetchRoute(driverPos!);
              });
            }

            // Camera: follow driver smoothly
            if (_mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: driverPos, zoom: 15, tilt: 30),
                ),
              );
            }
          }
        }

        // ── Build markers ─────────────────────────────────────────────────
        final Set<Marker> markers = {};

        if (driverPos != null) {
          markers.add(
            Marker(
              markerId: const MarkerId('driver'),
              position: driverPos,
              rotation: heading,
              flat: true,
              anchor: const Offset(0.5, 0.5),
              icon:
                  _driverIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
              infoWindow: InfoWindow(
                title: '🚗 Driver',
                snippet: widget.driverMemberId,
              ),
              zIndexInt: 3,
            ),
          );
        }

        if (widget.passengerLocation != null) {
          markers.add(
            Marker(
              markerId: const MarkerId('passenger'),
              position: widget.passengerLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
              infoWindow: const InfoWindow(
                title: '📍 Passenger',
                snippet: 'Pickup location',
              ),
              zIndexInt: 2,
            ),
          );
        }

        if (widget.dropLocation != null) {
          markers.add(
            Marker(
              markerId: const MarkerId('drop'),
              position: widget.dropLocation!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              infoWindow: const InfoWindow(
                title: '🏁 Drop-off',
                snippet: 'Destination',
              ),
              zIndexInt: 1,
            ),
          );
        }

        // ── Build polylines ────────────────────────────────────────────────
        final Set<Polyline> polylines = {};

        // Grey breadcrumb: driver's travelled path
        if (_breadcrumb.length > 1) {
          polylines.add(
            Polyline(
              polylineId: const PolylineId('breadcrumb'),
              points: List.from(_breadcrumb),
              color: Colors.grey.shade500,
              width: 3,
              patterns: [PatternItem.dot, PatternItem.gap(8)],
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
        }

        // Blue route: driver → destination (from Directions API)
        if (_routeToDestination.isNotEmpty) {
          polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: List.from(_routeToDestination),
              color: const Color(0xFF1565C0),
              width: 5,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
          );
        }

        final LatLng initialPos =
            driverPos ??
            widget.passengerLocation ??
            const LatLng(7.8731, 80.7718);

        return Stack(
          children: [
            // ── Google Map ─────────────────────────────────────────────────
            GoogleMap(
              key: ValueKey('map_ongoing_${widget.data['bookingId']}'),
              initialCameraPosition: CameraPosition(
                target: initialPos,
                zoom: 14,
              ),
              markers: markers,
              polylines: polylines,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              compassEnabled: true,
              trafficEnabled: true,
              onMapCreated: (controller) {
                _mapController = controller;
                // Initial camera fit
                Future.delayed(const Duration(milliseconds: 500), () {
                  final pts = <LatLng>[
                    ...?(driverPos != null ? [driverPos] : null),
                    if (widget.passengerLocation != null)
                      widget.passengerLocation!,
                  ];
                  if (pts.length > 1) _fitBounds(pts);
                });
              },
            ),

            // ── ETA / Distance overlay ─────────────────────────────────────
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _EtaCard(
                isDropPhase: widget.isDropPhase,
                distanceKm: _distanceKm,
                etaMins: _etaMins,
                hasFix: driverPos != null,
                acceptedTime:
                    widget.data['acceptedAt']?.toString() ??
                    widget.data['acceptedTime']?.toString(),
              ),
            ),

            // ── No driver location warning ────────────────────────────────
            if (driverPos == null)
              const Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: _Chip(
                    icon: Icons.gps_not_fixed,
                    label: 'Waiting for driver location…',
                    color: Colors.orange,
                  ),
                ),
              ),

            // ── Route status chip ─────────────────────────────────────────
            Positioned(
              bottom: 12,
              left: 12,
              child: _Chip(
                icon: _routeFetched
                    ? Icons.route
                    : (_fetchingRoute
                          ? Icons.hourglass_top
                          : Icons.route_outlined),
                label: _routeFetched
                    ? 'Route loaded'
                    : (_fetchingRoute ? 'Fetching route…' : 'Route pending'),
                color: _routeFetched ? Colors.green : Colors.grey,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ETA Card Overlay
// ═══════════════════════════════════════════════════════════════════════════════

class _EtaCard extends StatelessWidget {
  final bool isDropPhase;
  final double distanceKm;
  final int etaMins;
  final bool hasFix;
  final String? acceptedTime;

  const _EtaCard({
    required this.isDropPhase,
    required this.distanceKm,
    required this.etaMins,
    required this.hasFix,
    this.acceptedTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDropPhase ? Colors.blue.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDropPhase
                    ? Colors.blue.shade200
                    : Colors.orange.shade200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDropPhase ? Icons.flag_outlined : Icons.person_pin_circle,
                  size: 14,
                  color: isDropPhase
                      ? Colors.blue.shade700
                      : Colors.orange.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  isDropPhase ? 'Heading to Drop-off' : 'Heading to Passenger',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDropPhase
                        ? Colors.blue.shade800
                        : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),

          if (acceptedTime != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Acc: ${DateTime.tryParse(acceptedTime!)?.toLocal().toString().substring(11, 16) ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    Builder(
                      builder: (ctx) {
                        final dt = DateTime.tryParse(acceptedTime!);
                        if (dt == null) return const SizedBox.shrink();
                        final diff = DateTime.now().difference(dt);
                        return Text(
                          '${diff.inMinutes} mins ago',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

          const Spacer(),
          if (hasFix) ...[
            // Distance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Distance',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  '${distanceKm.toStringAsFixed(2)} km',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            // ETA
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'ETA',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  '$etaMins min',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ] else
            const Text(
              'Locating driver…',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Historical Map - Completed / Cancelled / Pending trips
// ═══════════════════════════════════════════════════════════════════════════════

class _HistoricalMapView extends StatefulWidget {
  final LatLng? pickupPoint;
  final LatLng? dropPoint;
  final Map<String, dynamic> data;

  const _HistoricalMapView({
    required this.pickupPoint,
    required this.dropPoint,
    required this.data,
  });

  @override
  State<_HistoricalMapView> createState() => _HistoricalMapViewState();
}

class _HistoricalMapViewState extends State<_HistoricalMapView> {
  GoogleMapController? _ctrl;
  static const String _apiKey = 'AIzaSyD2ZaITIFYTcb1fThVzChQYJ-cHm0aZ2iE';

  List<LatLng> _routePoints = [];
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    if (widget.pickupPoint != null && widget.dropPoint != null) {
      _fetchRoute();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  Future<void> _fetchRoute() async {
    if (_fetching) return;
    _fetching = true;

    final targetUrl =
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${widget.pickupPoint!.latitude},${widget.pickupPoint!.longitude}'
        '&destination=${widget.dropPoint!.latitude},${widget.dropPoint!.longitude}'
        '&mode=driving'
        '&key=$_apiKey';

    final url = Uri.parse(
      'https://api.allorigins.win/raw?url=' + Uri.encodeComponent(targetUrl),
    );

    try {
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['status'] == 'OK') {
          final routes = body['routes'] as List;
          if (routes.isNotEmpty) {
            final polylineString =
                routes[0]['overview_polyline']['points'] as String;
            final decoded = _decodePoly(polylineString);
            if (mounted) {
              setState(() {
                _routePoints = decoded;
              });
            }
          }
        }
      }
    } catch (_) {}
    _fetching = false;
  }

  // ── Google encoded polyline decoder ───────────────────────────────────────
  List<LatLng> _decodePoly(String poly) {
    final pts = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < poly.length) {
      int b, shift = 0, result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      shift = 0;
      result = 0;
      do {
        b = poly.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      pts.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return pts;
  }

  String _timeTaken() {
    final acceptedTime =
        widget.data['acceptedAt'] ?? widget.data['acceptedTime'];
    final arrivedTime =
        widget.data['arrivedAt'] ??
        widget.data['arrivedTime'] ??
        widget.data['tripEndTime'];
    if (acceptedTime == null || arrivedTime == null) return 'N/A';
    try {
      final a = acceptedTime is Timestamp
          ? acceptedTime.toDate()
          : DateTime.parse(acceptedTime.toString());
      final b = arrivedTime is Timestamp
          ? arrivedTime.toDate()
          : DateTime.parse(arrivedTime.toString());
      final d = b.difference(a);
      return '${d.inMinutes} min ${d.inSeconds % 60} sec';
    } catch (_) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final Set<Marker> markers = {};
    if (widget.pickupPoint != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: widget.pickupPoint!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: '📍 Pickup'),
        ),
      );
    }
    if (widget.dropPoint != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: widget.dropPoint!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: '🏁 Drop-off'),
        ),
      );
    }

    final Set<Polyline> polylines = {};
    if (widget.pickupPoint != null && widget.dropPoint != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('trip'),
          points: _routePoints.isNotEmpty
              ? _routePoints
              : [widget.pickupPoint!, widget.dropPoint!],
          color: Colors.blue.shade700,
          width: 5,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }

    final center = widget.pickupPoint ?? const LatLng(7.8731, 80.7718);

    final status = (widget.data['status'] ?? '').toString().toLowerCase();

    return Stack(
      children: [
        GoogleMap(
          key: ValueKey('map_historical_${widget.data['bookingId']}'),
          initialCameraPosition: CameraPosition(target: center, zoom: 13),
          markers: markers,
          polylines: polylines,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: true,
          onMapCreated: (c) {
            _ctrl = c;
            Future.delayed(const Duration(milliseconds: 500), () {
              if (widget.pickupPoint != null && widget.dropPoint != null) {
                _ctrl?.animateCamera(
                  CameraUpdate.newLatLngBounds(
                    LatLngBounds(
                      southwest: LatLng(
                        min(
                          widget.pickupPoint!.latitude,
                          widget.dropPoint!.latitude,
                        ),
                        min(
                          widget.pickupPoint!.longitude,
                          widget.dropPoint!.longitude,
                        ),
                      ),
                      northeast: LatLng(
                        max(
                          widget.pickupPoint!.latitude,
                          widget.dropPoint!.latitude,
                        ),
                        max(
                          widget.pickupPoint!.longitude,
                          widget.dropPoint!.longitude,
                        ),
                      ),
                    ),
                    60,
                  ),
                );
              }
            });
          },
        ),
        if (status == 'completed')
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Trip Completed',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.timer_outlined,
                    color: Colors.grey,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Duration: ${_timeTaken()}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tiny reusable widgets
// ═══════════════════════════════════════════════════════════════════════════════

class _TitleBar extends StatelessWidget {
  final String tripId;
  final String status;
  final String passengerName;
  final String driverName;

  const _TitleBar({
    required this.tripId,
    required this.status,
    required this.passengerName,
    required this.driverName,
  });

  Color _statusColor() {
    switch (status) {
      case 'ongoing pickup':
      case 'ongoing drop':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sc = _statusColor();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tripId,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (passengerName.isNotEmpty)
                      _pill(Icons.person, passengerName, Colors.teal),
                    if (passengerName.isNotEmpty && driverName.isNotEmpty)
                      const SizedBox(width: 6),
                    if (driverName.isNotEmpty)
                      _pill(Icons.drive_eta, driverName, Colors.indigo),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: sc.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sc.withValues(alpha: 0.4)),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: sc,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _Banner({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
