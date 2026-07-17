import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'package:aiaprtd_admin_dashboard/core/providers/member_provider.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/active_members_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/canceled_trips_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/complaints_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/inactive_members_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/offline_members_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/ongoing_trips_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/online_members_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/today_complete_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/total_members_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/upcoming_bookings_panel.dart';
import 'package:aiaprtd_admin_dashboard/core/utils/status_helpers.dart';

class DriversOverviewPanel extends StatefulWidget {
  const DriversOverviewPanel({super.key});

  @override
  State<DriversOverviewPanel> createState() => _DriversOverviewPanelState();
}

class _DriversOverviewPanelState extends State<DriversOverviewPanel> {
  int _currentViewIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MemberProvider>(
        context,
        listen: false,
      ).startListeningToMembers();
    });
  }

  void _navigateToDashboard() {
    setState(() => _currentViewIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentViewIndex,
      children: [
        _buildMainDashboard(context),
        TotalMembersPanel(onBack: _navigateToDashboard),
        ActiveMembersPanel(onBack: _navigateToDashboard),
        InactiveMembersPanel(onBack: _navigateToDashboard),
        OnlineMembersPanel(onBack: _navigateToDashboard),
        OfflineMembersPanel(onBack: _navigateToDashboard),
        OngoingTripsPanel(onBack: _navigateToDashboard),
        TodayCompletePanel(onBack: _navigateToDashboard),
        CanceledTripsPanel(onBack: _navigateToDashboard),
        ComplaintsPanel(onBack: _navigateToDashboard),
        UpcomingBookingsPanel(onBack: _navigateToDashboard),
      ],
    );
  }

  Widget _buildMainDashboard(BuildContext context) {
    final memberProvider = Provider.of<MemberProvider>(context);
    final allDrivers = memberProvider.allMembersList;

    final totalMembers = allDrivers.length;
    final activeMembers = allDrivers.where((d) {
      final statusResult = calculateMemberStatus(d);
      return statusResult['isActive'] == true;
    }).length;
    final inactiveMembers = allDrivers.where((d) {
      final statusResult = calculateMemberStatus(d);
      return statusResult['isActive'] == false;
    }).length;
    final onlineMembers = allDrivers.where(_isOnline).length;
    final offlineMembers = totalMembers - onlineMembers;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _DriverOverviewHeader(),
            const SizedBox(height: 20),
            _buildSectionHeading('DRIVER REGISTRY LOGS'),
            const SizedBox(height: 12),
            _ResponsiveMetricGrid(
              children: [
                _metricCard(
                  'Total Registered',
                  totalMembers.toString(),
                  Icons.group_rounded,
                  const Color(0xFF2563EB),
                  1,
                ),
                _metricCard(
                  'Active Verified',
                  activeMembers.toString(),
                  Icons.verified_user_rounded,
                  const Color(0xFF4F46E5),
                  2,
                ),
                _metricCard(
                  'Dormant/Inactive',
                  inactiveMembers.toString(),
                  Icons.no_accounts_rounded,
                  const Color(0xFFF59E0B),
                  3,
                ),
                _metricCard(
                  'Live Online',
                  onlineMembers.toString(),
                  Icons.sensors_rounded,
                  const Color(0xFF059669),
                  4,
                ),
                _metricCard(
                  'Offline Members',
                  offlineMembers.toString(),
                  Icons.cloud_off_rounded,
                  const Color(0xFF64748B),
                  5,
                ),
              ],
            ),
            const SizedBox(height: 22),
            _buildSectionHeading('VEHICLE CATEGORY LIVE MAP'),
            const SizedBox(height: 12),
            const _VehicleCategoryMap(),
            const SizedBox(height: 22),
            _buildSectionHeading('REALTIME JOB DISPATCH MATRIX'),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('trips')
                  .snapshots(),
              builder: (context, tripsSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('complaints')
                      .snapshots(),
                  builder: (context, complaintsSnapshot) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('all_bookings')
                          .snapshots(),
                      builder: (context, bookingsSnapshot) {
                        var ongoingTrips = 0;
                        var todayCompleted = 0;
                        var canceledTrips = 0;
                        final activeComplaints =
                            complaintsSnapshot.data?.docs.length ?? 0;
                        var upcomingBookings = 0;

                        if (tripsSnapshot.hasData) {
                          for (final doc in tripsSnapshot.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            final status =
                                data['status']?.toString().toLowerCase() ?? '';

                            if (status == 'ongoing') ongoingTrips++;
                            if (status == 'canceled' || status == 'cancelled')
                              canceledTrips++;

                            if (status == 'completed' &&
                                data['timestamp'] is Timestamp) {
                              final timestamp = data['timestamp'] as Timestamp;
                              if (timestamp.toDate().isAfter(startOfToday)) {
                                todayCompleted++;
                              }
                            }
                          }
                        }

                        if (bookingsSnapshot.hasData) {
                          for (final doc in bookingsSnapshot.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            final status =
                                data['status']?.toString().toLowerCase() ?? '';
                            if (status == 'pending') upcomingBookings++;
                          }
                        }

                        return _ResponsiveMetricGrid(
                          children: [
                            _metricCard(
                              'Upcoming Bookings',
                              upcomingBookings.toString(),
                              Icons.event_available_rounded,
                              const Color(0xFFEA580C),
                              10,
                            ),
                            _metricCard(
                              'Ongoing Rides',
                              ongoingTrips.toString(),
                              Icons.local_taxi_rounded,
                              const Color(0xFF7C3AED),
                              6,
                            ),
                            _metricCard(
                              'Completed Trips',
                              todayCompleted.toString(),
                              Icons.check_circle_rounded,
                              const Color(0xFF0D9488),
                              7,
                            ),
                            _metricCard(
                              'Canceled Audits',
                              canceledTrips.toString(),
                              Icons.cancel_rounded,
                              const Color(0xFFDC2626),
                              8,
                            ),
                            _metricCard(
                              'Support Tickets',
                              activeComplaints.toString(),
                              Icons.assignment_late_rounded,
                              const Color(0xFFE11D48),
                              9,
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isOnline(Map<String, dynamic> driver) {
    return driver['isOnline'] == true || driver['onlineStatus'] == 'online';
  }

  Widget _buildSectionHeading(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: Color(0xFF64748B),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _metricCard(
    String title,
    String value,
    IconData icon,
    Color accentColor,
    int targetIndex,
  ) {
    return InkWell(
      onTap: () => setState(() => _currentViewIndex = targetIndex),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: accentColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverOverviewHeader extends StatelessWidget {
  const _DriverOverviewHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF263244)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Color(0xFF111827),
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Drivers Overview Center',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Live category map, registry health, and dispatch diagnostics for the full driver fleet.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveMetricGrid extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveMetricGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final count = width > 1280
            ? 5
            : (width > 920 ? 3 : (width > 560 ? 2 : 1));
        return GridView.count(
          crossAxisCount: count,
          shrinkWrap: true,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: count == 1 ? 4.5 : 3.8,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}

class _VehicleCategoryMap extends StatefulWidget {
  const _VehicleCategoryMap();

  @override
  State<_VehicleCategoryMap> createState() => _VehicleCategoryMapState();
}

class _VehicleCategoryMapState extends State<_VehicleCategoryMap> {
  static const LatLng _sriLankaCenter = LatLng(7.8731, 80.7718);
  static const _allKey = 'all';

  final Map<String, BitmapDescriptor> _icons = {};
  var _selectedCategory = _allKey;
  var _iconsReady = false;

  final List<_VehicleCategory> _categories = const [
    _VehicleCategory(
      key: 'budget',
      label: 'Budget',
      assetPath: 'assets/vehicle_icons/budget_marker.png',
      icon: Icons.local_taxi_rounded,
      color: Color(0xFF2563EB),
    ),
    _VehicleCategory(
      key: 'mini',
      label: 'Mini',
      assetPath: 'assets/vehicle_icons/mini_marker.png',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF059669),
    ),
    _VehicleCategory(
      key: 'sedan',
      label: 'Sedan',
      assetPath: 'assets/vehicle_icons/sedan_marker.png',
      icon: Icons.time_to_leave_rounded,
      color: Color(0xFF4F46E5),
    ),
    _VehicleCategory(
      key: '6_seater',
      label: '6 Seater',
      assetPath: 'assets/vehicle_icons/mini_van_marker.png',
      icon: Icons.airport_shuttle_rounded,
      color: Color(0xFFF59E0B),
    ),
    _VehicleCategory(
      key: '9_seater',
      label: '9 Seater',
      assetPath: 'assets/vehicle_icons/flatRoof_marker.png',
      icon: Icons.airport_shuttle_rounded,
      color: Color(0xFF7C3AED),
    ),
    _VehicleCategory(
      key: '14_seater',
      label: '14 Seater',
      assetPath: 'assets/vehicle_icons/highRoof_marker.png',
      icon: Icons.directions_bus_rounded,
      color: Color(0xFFDC2626),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  Future<void> _loadIcons() async {
    for (final category in _categories) {
      try {
        // ignore: deprecated_member_use
        _icons[category.key] = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(45, 45)),
          category.assetPath,
        );
      } catch (e) {
        debugPrint(
          'Driver overview map icon load failed for ${category.key}: $e',
        );
      }
    }

    if (mounted) {
      setState(() => _iconsReady = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_iconsReady) {
      return const _MapShell(
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('member')
          .where('onlineStatus', isEqualTo: 'online')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _MapShell(
            child: _MapMessage(
              icon: Icons.error_outline_rounded,
              title: 'Map data blocked',
              subtitle: snapshot.error.toString(),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const _MapShell(
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          );
        }

        return FutureBuilder<List<_DriverMapItem>>(
          future: _loadDrivers(snapshot.data!.docs),
          builder: (context, driversSnapshot) {
            if (driversSnapshot.hasError) {
              return _MapShell(
                child: _MapMessage(
                  icon: Icons.error_outline_rounded,
                  title: 'Vehicle data blocked',
                  subtitle: driversSnapshot.error.toString(),
                ),
              );
            }

            final drivers = driversSnapshot.data ?? const <_DriverMapItem>[];
            final counts = _categoryCounts(drivers);
            final visibleDrivers = _selectedCategory == _allKey
                ? drivers
                : drivers
                      .where((d) => d.categoryKey == _selectedCategory)
                      .toList();
            final markers = visibleDrivers.map(_markerFor).toSet();

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF111827).withValues(alpha: 0.04),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.map_rounded,
                                color: Color(0xFF2563EB),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Live Vehicle Category Map',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Select one category to see only those online drivers on the map.',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _TotalOnlineBadge(
                              total: drivers.length,
                              visible: visibleDrivers.length,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _CategoryChip(
                              label: 'All',
                              count: drivers.length,
                              icon: Icons.grid_view_rounded,
                              color: const Color(0xFF111827),
                              selected: _selectedCategory == _allKey,
                              onTap: () =>
                                  setState(() => _selectedCategory = _allKey),
                            ),
                            for (final category in _categories)
                              _CategoryChip(
                                label: category.label,
                                count: counts[category.key] ?? 0,
                                icon: category.icon,
                                color: category.color,
                                selected: _selectedCategory == category.key,
                                onTap: () => setState(
                                  () => _selectedCategory = category.key,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  SizedBox(
                    height: 460,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                            ),
                            child: GoogleMap(
                              initialCameraPosition: const CameraPosition(
                                target: _sriLankaCenter,
                                zoom: 7.45,
                              ),
                              mapType: MapType.normal,
                              zoomControlsEnabled: true,
                              myLocationEnabled: false,
                              myLocationButtonEnabled: false,
                              markers: markers,
                            ),
                          ),
                        ),
                        Container(width: 1, color: const Color(0xFFE5E7EB)),
                        SizedBox(
                          width: 300,
                          child: visibleDrivers.isEmpty
                              ? const _MapMessage(
                                  icon: Icons.local_taxi_outlined,
                                  title: 'No online drivers',
                                  subtitle:
                                      'No live members found for this category right now.',
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: visibleDrivers.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) =>
                                      _DriverMiniCard(
                                        driver: visibleDrivers[index],
                                      ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<_DriverMapItem>> _loadDrivers(
    List<QueryDocumentSnapshot> docs,
  ) async {
    final items = <_DriverMapItem>[];

    for (final doc in docs) {
      final memberData = doc.data() as Map<String, dynamic>;
      final lat =
          double.tryParse(memberData['latitude']?.toString() ?? '') ?? 0;
      final lng =
          double.tryParse(memberData['longitude']?.toString() ?? '') ?? 0;

      if (lat == 0 || lng == 0) continue;

      var categoryKey = _normalizeCategory(
        memberData['primaryVehicle'] ?? memberData['vehicleType'],
      );
      var plateNumber = memberData['vehicleNumber']?.toString() ?? '-';
      var modelName = memberData['vehicleType']?.toString() ?? '-';

      try {
        final vehicleDoc = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(doc.id)
            .get();
        final vehicleData = vehicleDoc.data();

        if (vehicleData != null) {
          categoryKey = _normalizeCategory(
            vehicleData['selectedCategory'] ?? categoryKey,
          );
          final details = vehicleData['details'];
          if (details is Map) {
            plateNumber = details['plateNumber']?.toString() ?? plateNumber;
            modelName = details['model']?.toString() ?? modelName;
          }

          final documents = vehicleData['documents'];
          if ((plateNumber == '-' || plateNumber.isEmpty) &&
              documents is List &&
              documents.length > 2) {
            final regBook = documents[2];
            if (regBook is Map && regBook['reviewData'] is Map) {
              plateNumber =
                  regBook['reviewData']['Plate Number']?.toString() ??
                  plateNumber;
            }
          }
        }
      } catch (e) {
        debugPrint('Driver overview vehicle read failed for ${doc.id}: $e');
      }

      items.add(
        _DriverMapItem(
          id: doc.id,
          name: memberData['fullName']?.toString() ?? 'Unknown Driver',
          membershipNo: memberData['membershipNo']?.toString() ?? doc.id,
          phone: memberData['mobile']?.toString() ?? '-',
          position: LatLng(lat, lng),
          heading:
              double.tryParse(
                memberData['bearing']?.toString() ??
                    memberData['heading']?.toString() ??
                    '',
              ) ??
              0,
          categoryKey: categoryKey,
          categoryLabel: _labelFor(categoryKey),
          plateNumber: plateNumber.isEmpty ? '-' : plateNumber,
          modelName: modelName.isEmpty ? '-' : modelName,
          available: memberData['isAvailable'] != false,
        ),
      );
    }

    items.sort((a, b) => a.categoryLabel.compareTo(b.categoryLabel));
    return items;
  }

  Marker _markerFor(_DriverMapItem driver) {
    return Marker(
      markerId: MarkerId(driver.id),
      position: driver.position,
      rotation: driver.heading,
      flat: true,
      anchor: const Offset(0.5, 0.5),
      icon: _icons[driver.categoryKey] ?? BitmapDescriptor.defaultMarker,
      infoWindow: InfoWindow(
        title: driver.name,
        snippet:
            '${driver.categoryLabel} | ${driver.plateNumber} | ${driver.available ? 'AVAILABLE' : 'ON TRIP'}',
      ),
    );
  }

  Map<String, int> _categoryCounts(List<_DriverMapItem> drivers) {
    final counts = {for (final category in _categories) category.key: 0};
    for (final driver in drivers) {
      counts[driver.categoryKey] = (counts[driver.categoryKey] ?? 0) + 1;
    }
    return counts;
  }

  String _normalizeCategory(Object? raw) {
    final value = raw?.toString().toLowerCase().trim() ?? '';
    final normalized = value
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    if (normalized.contains('budget')) return 'budget';
    if (normalized.contains('mini_van') ||
        normalized == '6' ||
        normalized.contains('6_seater') ||
        normalized.contains('6seat'))
      return '6_seater';
    if (normalized.contains('flat') ||
        normalized == '9' ||
        normalized.contains('9_seater') ||
        normalized.contains('9seat'))
      return '9_seater';
    if (normalized.contains('high') ||
        normalized == '14' ||
        normalized.contains('14_seater') ||
        normalized.contains('14seat'))
      return '14_seater';
    if (normalized.contains('sedan') || normalized.contains('car'))
      return 'sedan';
    if (normalized.contains('mini')) return 'mini';

    return 'budget';
  }

  String _labelFor(String key) {
    return _categories
        .firstWhere(
          (category) => category.key == key,
          orElse: () => _categories.first,
        )
        .label;
  }
}

class _VehicleCategory {
  final String key;
  final String label;
  final String assetPath;
  final IconData icon;
  final Color color;

  const _VehicleCategory({
    required this.key,
    required this.label,
    required this.assetPath,
    required this.icon,
    required this.color,
  });
}

class _DriverMapItem {
  final String id;
  final String name;
  final String membershipNo;
  final String phone;
  final LatLng position;
  final double heading;
  final String categoryKey;
  final String categoryLabel;
  final String plateNumber;
  final String modelName;
  final bool available;

  const _DriverMapItem({
    required this.id,
    required this.name,
    required this.membershipNo,
    required this.phone,
    required this.position,
    required this.heading,
    required this.categoryKey,
    required this.categoryLabel,
    required this.plateNumber,
    required this.modelName,
    required this.available,
  });
}

class _MapShell extends StatelessWidget {
  final Widget child;

  const _MapShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 520,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: selected ? color : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: selected ? Colors.white : color),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF111827),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: .18)
                    : Colors.white,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalOnlineBadge extends StatelessWidget {
  final int total;
  final int visible;

  const _TotalOnlineBadge({required this.total, required this.visible});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sensors_rounded, color: Color(0xFF059669), size: 16),
          const SizedBox(width: 6),
          Text(
            '$visible / $total live',
            style: const TextStyle(
              color: Color(0xFF166534),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverMiniCard extends StatelessWidget {
  final _DriverMapItem driver;

  const _DriverMiniCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  driver.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: driver.available
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFEA580C),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            driver.categoryLabel,
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${driver.plateNumber} | ${driver.modelName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            '${driver.membershipNo} | ${driver.phone}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _MapMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _MapMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF94A3B8), size: 34),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
