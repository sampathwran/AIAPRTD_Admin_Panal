import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;

class VehicleTracker {
  final String id;
  LatLng currentPosition;
  double currentHeading;
  
  // Metadata cache
  String categoryKey;
  String memberNo;
  String plateNumber;
  String modelName;
  String name;
  bool isAvailable;
  bool metadataLoaded;

  // Animation
  final AnimationController controller;
  Animation<double>? latAnimation;
  Animation<double>? lngAnimation;
  Animation<double>? headingAnimation;

  VehicleTracker({
    required this.id,
    required this.currentPosition,
    required this.currentHeading,
    required this.controller,
    this.categoryKey = 'budget',
    this.memberNo = '',
    this.plateNumber = '-',
    this.modelName = '-',
    this.name = 'Unknown Driver',
    this.isAvailable = true,
    this.metadataLoaded = false,
  });

  LatLng get interpolatedPosition {
    if (latAnimation != null && lngAnimation != null) {
      return LatLng(latAnimation!.value, lngAnimation!.value);
    }
    return currentPosition;
  }

  double get interpolatedHeading {
    if (headingAnimation != null) {
      return headingAnimation!.value;
    }
    return currentHeading;
  }
}

class LiveTrackingMap extends StatefulWidget {
  final String? selectedCategory;
  final Function(Map<String, int>)? onCountsUpdated;

  const LiveTrackingMap({super.key, this.selectedCategory, this.onCountsUpdated});

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> with TickerProviderStateMixin {
  final Map<String, BitmapDescriptor> _cachedVehicleIcons = {};
  final Map<String, BitmapDescriptor> _badgeCache = {};
  final Set<String> _generatingBadges = {};
  
  bool _isEngineReady = false;

  StreamSubscription<QuerySnapshot>? _memberSubscription;
  final Map<String, VehicleTracker> _trackers = {};
  final ValueNotifier<Set<Marker>> _markersNotifier = ValueNotifier({});

  static const LatLng _sriLankaCenter = LatLng(7.0011, 79.9497);

  @override
  void initState() {
    super.initState();
    _loadVehicleAssetIcons().then((_) {
      _startTracking();
    });
  }

  @override
  void didUpdateWidget(LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _updateMarkers();
    }
  }

  @override
  void dispose() {
    _memberSubscription?.cancel();
    for (var tracker in _trackers.values) {
      tracker.controller.dispose();
    }
    _markersNotifier.dispose();
    super.dispose();
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<void> _loadVehicleAssetIcons() async {
    final Map<String, String> iconPaths = {
      'budget': 'assets/vehicle_icons/budget_marker.png',
      'mini': 'assets/vehicle_icons/mini_marker.png',
      'sedan': 'assets/vehicle_icons/sedan_marker.png',
      '6_seater': 'assets/vehicle_icons/mini_van_marker.png',
      '9_seater': 'assets/vehicle_icons/flatRoof_marker.png',
      '14_seater': 'assets/vehicle_icons/highRoof_marker.png',
    };

    try {
      for (var entry in iconPaths.entries) {
        final Uint8List markerIcon = await _getBytesFromAsset(entry.value, 45); // Smaller icon
        final BitmapDescriptor icon = BitmapDescriptor.bytes(markerIcon);
        _cachedVehicleIcons[entry.key] = icon;
      }
      debugPrint("✅ ADMIN MAP ENGINE: Base vehicle icons ready.");
    } catch (e) {
      debugPrint("❌ ASSET LOGO ERROR: $e");
    }

    if (mounted) {
      setState(() {
        _isEngineReady = true;
      });
    }
  }

  double _calculateHeading(LatLng start, LatLng end) {
    if (start.latitude == end.latitude && start.longitude == end.longitude) return 0.0;
    final double lat1 = start.latitude * math.pi / 180.0;
    final double lng1 = start.longitude * math.pi / 180.0;
    final double lat2 = end.latitude * math.pi / 180.0;
    final double lng2 = end.longitude * math.pi / 180.0;

    final double dLng = lng2 - lng1;
    final double y = math.sin(dLng) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final double brng = math.atan2(y, x);
    return (brng * 180.0 / math.pi + 360.0) % 360.0;
  }

  void _startTracking() {
    _memberSubscription = FirebaseFirestore.instance
        .collection('member')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String id = doc.id;

        if (data['latitude'] != null && data['longitude'] != null) {
          final double lat = double.tryParse(data['latitude'].toString()) ?? 0.0;
          final double lng = double.tryParse(data['longitude'].toString()) ?? 0.0;
          double heading = double.tryParse(data['bearing'].toString()) ??
              double.tryParse(data['heading'].toString()) ?? 0.0;
          final String name = data['fullName'] ?? 'Unknown Driver';
          final String memberNo = data['membershipNo']?.toString() ?? '';
          final bool isAvailable = data['isAvailable'] ?? true;

          final newPos = LatLng(lat, lng);

          if (_trackers.containsKey(id)) {
            final tracker = _trackers[id]!;
            tracker.name = name;
            tracker.memberNo = memberNo;
            tracker.isAvailable = isAvailable;

            if (tracker.currentPosition.latitude != newPos.latitude || tracker.currentPosition.longitude != newPos.longitude) {
              tracker.latAnimation = Tween<double>(begin: tracker.currentPosition.latitude, end: newPos.latitude).animate(tracker.controller);
              tracker.lngAnimation = Tween<double>(begin: tracker.currentPosition.longitude, end: newPos.longitude).animate(tracker.controller);
              
              // Dynamically calculate heading based on movement if missing or 0
              if (heading == 0.0) {
                 heading = _calculateHeading(tracker.currentPosition, newPos);
              }

              double startHeading = tracker.currentHeading;
              double endHeading = heading;
              double diff = endHeading - startHeading;
              if (diff > 180) endHeading -= 360;
              if (diff < -180) endHeading += 360;

              tracker.headingAnimation = Tween<double>(begin: startHeading, end: endHeading).animate(tracker.controller);

              tracker.currentPosition = newPos;
              tracker.currentHeading = heading;
              
              tracker.controller.forward(from: 0.0);
            }
          } else {
            final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
            controller.addListener(_updateMarkers);

            final tracker = VehicleTracker(
              id: id,
              currentPosition: newPos,
              currentHeading: heading,
              controller: controller,
              name: name,
              memberNo: memberNo,
              isAvailable: isAvailable,
            );
            
            _trackers[id] = tracker;
            _fetchVehicleMetadata(tracker);
            _updateMarkers();
          }
        }
      }
      
      final onlineIds = snapshot.docs.map((d) => d.id).toSet();
      _trackers.removeWhere((id, tracker) {
        if (!onlineIds.contains(id)) {
          tracker.controller.dispose();
          return true;
        }
        return false;
      });
      _updateMarkers();
    });
  }

  Future<void> _fetchVehicleMetadata(VehicleTracker tracker) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('vehicles').doc(tracker.id).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['selectedCategory'] != null) {
          String raw = data['selectedCategory'].toString().toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
          tracker.categoryKey = raw.replaceAll(' ', '_');
        }
        if (data['documents'] != null && data['documents'] is List && (data['documents'] as List).length > 2) {
          var reg = data['documents'][2];
          if (reg['reviewData'] != null && reg['reviewData']['Plate Number'] != null) {
            tracker.plateNumber = reg['reviewData']['Plate Number'].toString();
          }
        }
        if (tracker.plateNumber == '-' && data['details'] != null && data['details']['plateNumber'] != null) {
          tracker.plateNumber = data['details']['plateNumber'].toString();
        }
        if (data['details'] != null && data['details']['model'] != null) {
          tracker.modelName = data['details']['model'].toString();
        }
      }
    } catch (e) {
      debugPrint("Error fetching metadata for ${tracker.id}: $e");
    }
    tracker.metadataLoaded = true;
    _updateMarkers();
  }

  BitmapDescriptor _getBadgeMarkerSync(String memberNoText) {
    final String last4 = memberNoText.length >= 4 ? memberNoText.substring(memberNoText.length - 4) : (memberNoText.isEmpty ? 'N/A' : memberNoText);
    final String cacheKey = last4;
    
    if (_badgeCache.containsKey(cacheKey)) {
      return _badgeCache[cacheKey]!;
    }
    
    _generateAndCacheBadge(last4, cacheKey);
    // Return transparent empty marker temporarily so it doesn't draw wrong things
    return BitmapDescriptor.defaultMarker; 
  }

  Future<void> _generateAndCacheBadge(String last4, String cacheKey) async {
    if (_generatingBadges.contains(cacheKey)) return;
    _generatingBadges.add(cacheKey);

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // Smaller dimensions so it scales well when zooming out
    const double width = 80;
    const double height = 100; 
    
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: last4,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.0,
      ),
    );
    textPainter.layout();
    
    final double paddingHorizontal = 8.0;
    final double paddingVertical = 4.0;
    
    final double boxWidth = textPainter.width + (paddingHorizontal * 2);
    final double boxHeight = textPainter.height + (paddingVertical * 2);
    
    final double startX = (width - boxWidth) / 2;
    final double startY = 10.0; // Space for shadow
    
    final Path tooltipPath = Path();
    final double radius = 6.0;
    final double arrowWidth = 10.0;
    final double arrowHeight = 6.0;

    tooltipPath.moveTo(startX + radius, startY);
    tooltipPath.lineTo(startX + boxWidth - radius, startY);
    tooltipPath.arcToPoint(Offset(startX + boxWidth, startY + radius), radius: Radius.circular(radius));
    tooltipPath.lineTo(startX + boxWidth, startY + boxHeight - radius);
    tooltipPath.arcToPoint(Offset(startX + boxWidth - radius, startY + boxHeight), radius: Radius.circular(radius));
    
    // Arrow pointing down
    tooltipPath.lineTo(width / 2 + (arrowWidth / 2), startY + boxHeight);
    tooltipPath.lineTo(width / 2, startY + boxHeight + arrowHeight);
    tooltipPath.lineTo(width / 2 - (arrowWidth / 2), startY + boxHeight);
    
    tooltipPath.lineTo(startX + radius, startY + boxHeight);
    tooltipPath.arcToPoint(Offset(startX, startY + boxHeight - radius), radius: Radius.circular(radius));
    tooltipPath.lineTo(startX, startY + radius);
    tooltipPath.arcToPoint(Offset(startX + radius, startY), radius: Radius.circular(radius));
    tooltipPath.close();

    // Soft shadow
    canvas.drawShadow(tooltipPath, const Color(0xFF000000), 5.0, true);
    
    // Background fill (Dark Gray/Black)
    final Paint bgPaint = Paint()..color = const Color(0xFF111827);
    canvas.drawPath(tooltipPath, bgPaint);
    
    // Border (Amber)
    final Paint borderPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(tooltipPath, borderPaint);
    
    // Draw text centered
    textPainter.paint(
      canvas, 
      Offset(startX + paddingHorizontal, startY + paddingVertical)
    );
    
    final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(width.toInt(), height.toInt());
    final ByteData? byteData = await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      final Uint8List uint8List = byteData.buffer.asUint8List();
      _badgeCache[cacheKey] = BitmapDescriptor.bytes(uint8List);
      _updateMarkers(); 
    }
    _generatingBadges.remove(cacheKey);
  }

  void _updateMarkers() {
    if (!mounted) return;
    
    final Set<Marker> newMarkers = {};
    final Map<String, int> counts = {'All': 0};

    for (var tracker in _trackers.values) {
      if (!tracker.metadataLoaded) continue;

      // Update counts
      counts['All'] = (counts['All'] ?? 0) + 1;
      counts[tracker.categoryKey] = (counts[tracker.categoryKey] ?? 0) + 1;

      if (widget.selectedCategory != null && widget.selectedCategory != 'All') {
        if (tracker.categoryKey != widget.selectedCategory) continue;
      }

      final LatLng pos = tracker.interpolatedPosition;
      final double heading = tracker.interpolatedHeading;

      // 1. Vehicle Marker (rotates correctly with heading)
      final BitmapDescriptor carIcon = _cachedVehicleIcons[tracker.categoryKey] ?? BitmapDescriptor.defaultMarker;
      newMarkers.add(
        Marker(
          markerId: MarkerId(tracker.id),
          position: pos,
          rotation: heading,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon: carIcon,
          zIndex: 1, // Use zIndex as requested despite deprecation to avoid typing issues if unsupported SDK
          infoWindow: InfoWindow(
            title: tracker.name,
            snippet: "Vehicle: ${tracker.plateNumber} (${tracker.modelName}) | Category: ${tracker.categoryKey.toUpperCase().replaceAll('_', ' ')} | Status: ${tracker.isAvailable ? 'AVAILABLE' : 'ON TRIP'}",
          ),
        ),
      );

      // 2. Badge Marker (Never rotates, hovers above)
      final BitmapDescriptor badgeIcon = _getBadgeMarkerSync(tracker.memberNo);
      newMarkers.add(
        Marker(
          markerId: MarkerId('${tracker.id}_badge'),
          position: pos,
          rotation: 0,
          flat: true,
          anchor: const Offset(0.5, 1.0), // Anchor at the very bottom of the tall transparent canvas
          icon: badgeIcon,
          zIndex: 2, 
          consumeTapEvents: true, // Don't let badge taps interfere
        ),
      );
    }
    _markersNotifier.value = newMarkers;

    if (widget.onCountsUpdated != null) {
      Future.microtask(() {
        if (mounted) widget.onCountsUpdated!(counts);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEngineReady) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.blueGrey, strokeWidth: 2.5),
      );
    }

    return ValueListenableBuilder<Set<Marker>>(
      valueListenable: _markersNotifier,
      builder: (context, markers, child) {
        return GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _sriLankaCenter,
            zoom: 13.5,
          ),
          zoomControlsEnabled: true,
          mapType: MapType.normal,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          markers: markers,
        );
      },
    );
  }
}
