import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/scheduled_bookings/widgets/booking_detail_dialog.dart';

class DailyTripSummarySection extends StatefulWidget {
  const DailyTripSummarySection({super.key});

  @override
  State<DailyTripSummarySection> createState() => _DailyTripSummarySectionState();
}

class _DailyTripSummarySectionState extends State<DailyTripSummarySection> {
  bool _isLoading = true;
  int _totalBookings = 0;
  int _totalRoadPickups = 0;
  int _ongoingTrips = 0;
  int _cancelTrips = 0;
  double _scheduledCompletedTxns = 0;
  double _roadPickupCompletedTxns = 0;
  double _totalCompletedTxns = 0;
  double _unionIncomes = 0;
  int _transactionRequests = 0;

  List<Map<String, dynamic>> _bookingsData = [];
  List<Map<String, dynamic>> _roadPickupsData = [];

  Timer? _refreshTimer;
  List<String> _cachedMembershipNumbers = [];
  bool _membersCached = false;

  String _selectedFilterType = 'Today'; // 'Today', 'This Week', 'This Month', 'Custom Date'
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _fetchDailySummary();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) => _fetchDailySummary());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _selectCustomDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedFilterType = 'Custom Date';
        _customStartDate = DateTime(picked.year, picked.month, picked.day);
        _customEndDate = _customStartDate!.add(const Duration(days: 1));
      });
      _fetchDailySummary();
    }
  }

  void _onFilterChanged(String filter) {
    if (filter == 'Custom Date') {
      _selectCustomDate(context);
      return;
    }
    setState(() {
      _selectedFilterType = filter;
    });
    _fetchDailySummary();
  }

  Future<void> _fetchDailySummary() async {
    setState(() {
      _isLoading = true;
    });
    
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    if (_selectedFilterType == 'Today') {
      startDate = DateTime(now.year, now.month, now.day);
      endDate = startDate.add(const Duration(days: 1));
    } else if (_selectedFilterType == 'This Week') {
      // Start from Monday
      startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      endDate = startDate.add(const Duration(days: 7));
    } else if (_selectedFilterType == 'This Month') {
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 1);
    } else if (_selectedFilterType == 'Custom Date' && _customStartDate != null && _customEndDate != null) {
      startDate = _customStartDate!;
      endDate = _customEndDate!;
    } else {
      startDate = DateTime(now.year, now.month, now.day);
      endDate = startDate.add(const Duration(days: 1));
    }

    int bookings = 0;
    int roadPickups = 0;
    int ongoing = 0;
    int cancelled = 0;
    double scheduledMoney = 0;
    double roadPickupMoney = 0;
    double unionMoney = 0;
    int txnRequests = 0;
    
    List<Map<String, dynamic>> loadedBookings = [];
    List<Map<String, dynamic>> loadedRoadPickups = [];

    try {
      if (!_membersCached) {
        final memberSnap = await FirebaseFirestore.instance.collection('member').get();
        _cachedMembershipNumbers = memberSnap.docs.map((doc) {
          final data = doc.data();
          final String originalMemNo = data['membershipNo']?.toString() ?? '';
          return originalMemNo.isNotEmpty && originalMemNo != '-' ? originalMemNo : doc.id;
        }).toList();
        _membersCached = true;
      }

      final bookingsSnap = await FirebaseFirestore.instance
          .collection('all_bookings')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThan: Timestamp.fromDate(endDate))
          .get();
      bookings += bookingsSnap.docs.length;
      for (var doc in bookingsSnap.docs) {
        final data = doc.data();
        data['id'] = doc.id; // Important for BookingDetailDialog
        loadedBookings.add(data);
        
        final status = (data['status']?.toString() ?? data['tripState']?.toString() ?? '').toLowerCase();
        if (status == 'completed') {
          scheduledMoney += double.tryParse(data['actualFare']?.toString() ?? data['totalFare']?.toString() ?? data['estimateFare']?.toString() ?? '0') ?? 0;
        }
        unionMoney += double.tryParse(data['unionFee']?.toString() ?? data['commission']?.toString() ?? '0') ?? 0;
      }

      final dailyTripsSnap = await FirebaseFirestore.instance
          .collection('dayly_trips')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThan: Timestamp.fromDate(endDate))
          .get();
      bookings += dailyTripsSnap.docs.length;
      for (var doc in dailyTripsSnap.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        loadedBookings.add(data);
        
        final status = (data['status']?.toString() ?? data['tripState']?.toString() ?? '').toLowerCase();
        if (status == 'completed') {
          scheduledMoney += double.tryParse(data['actualFare']?.toString() ?? data['totalFare']?.toString() ?? data['fare']?.toString() ?? '0') ?? 0;
        }
        unionMoney += double.tryParse(data['unionFee']?.toString() ?? data['commission']?.toString() ?? '0') ?? 0;
      }

      // Generate date strings for roadpickups collection lookup
      List<String> dateStrings = [];
      for (int i = 0; i < endDate.difference(startDate).inDays; i++) {
        final d = startDate.add(Duration(days: i));
        dateStrings.add("${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}");
        dateStrings.add("${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}");
      }

      // Using a batched fetch limited by concurrent futures to avoid hanging the isolate
      List<Future<void>> pickupFutures = [];
      for (String dStr in dateStrings) {
        for (String memNo in _cachedMembershipNumbers) {
          if (memNo.isEmpty || memNo == '-') continue;
          pickupFutures.add(
            FirebaseFirestore.instance
                .collection('roadpickups_hires')
                .doc(dStr)
                .collection(memNo)
                .get()
                .then((snap) {
                  roadPickups += snap.docs.length;
                  for (var doc in snap.docs) {
                    final data = doc.data();
                    data['id'] = doc.id;
                    loadedRoadPickups.add(data);
                    
                    final rawStatus = (data['status']?.toString() ?? data['tripState']?.toString() ?? '').toLowerCase();
                    // Fallback: If it's in roadpickups_hires and has no status, it's completed (per app logic)
                    final status = rawStatus.isEmpty ? 'completed' : rawStatus;
                    
                    if (status == 'completed') {
                      roadPickupMoney += double.tryParse(data['actualFare']?.toString() ?? data['totalFare']?.toString() ?? data['fare']?.toString() ?? '0') ?? 0;
                    }
                    unionMoney += double.tryParse(data['unionFee']?.toString() ?? data['commission']?.toString() ?? '0') ?? 0;
                  }
                }).catchError((e) {})
          );
        }
      }
      
      // Batch waiting if it's too large to prevent out of memory / blocking
      for (int i = 0; i < pickupFutures.length; i += 500) {
        int end = (i + 500 < pickupFutures.length) ? i + 500 : pickupFutures.length;
        await Future.wait(pickupFutures.sublist(i, end));
      }

      // Filter trips
      final tripsSnap = await FirebaseFirestore.instance.collection('trips').get();
      for (var doc in tripsSnap.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase() ?? '';
        
        // We might want to filter ongoing/cancelled by time as well, but usually ongoing is current time, 
        // cancelled might be historical. We can use timestamp if exists. 
        if (data.containsKey('timestamp') && data['timestamp'] != null) {
           final t = (data['timestamp'] as Timestamp).toDate();
           if (t.isBefore(startDate) || t.isAfter(endDate)) continue;
        }
        
        if (status == 'ongoing') ongoing++;
        if (status == 'canceled' || status == 'cancelled' || status == 'rejected') cancelled++;
      }
      
      // Also include road pickups in the ongoing/cancelled count
      for (var data in loadedRoadPickups) {
        final rawStatus = (data['status']?.toString() ?? data['tripState']?.toString() ?? '').toLowerCase();
        final status = rawStatus.isEmpty ? 'completed' : rawStatus;
        if (status == 'ongoing' || status == 'started' || status == 'accepted' || status == 'searching') ongoing++;
        if (status == 'canceled' || status == 'cancelled' || status == 'rejected') cancelled++;
      }

      final financeSnap = await FirebaseFirestore.instance
          .collection('finance_transactions')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThan: Timestamp.fromDate(endDate))
          .get();
      for (var doc in financeSnap.docs) {
        final data = doc.data();
        final type = data['type']?.toString().toLowerCase() ?? '';
        final status = data['status']?.toString().toLowerCase() ?? '';
        
        if (type.contains('app_usage') || type.contains('membership')) {
           unionMoney += double.tryParse(data['amount']?.toString() ?? '0') ?? 0;
        }
        
        if (type.contains('withdrawal') || status == 'pending' || type.contains('request')) {
           txnRequests++;
        }
      }

      // Sort bookings loaded by newest first
      loadedBookings.sort((a, b) {
        final aTime = a['timestamp'] is Timestamp ? (a['timestamp'] as Timestamp).toDate() : DateTime(2000);
        final bTime = b['timestamp'] is Timestamp ? (b['timestamp'] as Timestamp).toDate() : DateTime(2000);
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() {
          _totalBookings = bookings;
          _bookingsData = loadedBookings;
          _totalRoadPickups = roadPickups;
          _roadPickupsData = loadedRoadPickups;
          _ongoingTrips = ongoing;
          _cancelTrips = cancelled;
          _scheduledCompletedTxns = scheduledMoney;
          _roadPickupCompletedTxns = roadPickupMoney;
          _totalCompletedTxns = scheduledMoney + roadPickupMoney;
          _unionIncomes = unionMoney;
          _transactionRequests = txnRequests;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching daily summary: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showBookingsListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        String dialogFilter = 'All'; // Local state for dialog
        String vehicleFilter = 'All Vehicles'; // Local state for vehicle category

        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            // Extract distinct vehicle categories
            Set<String> vehicleTypes = {'All Vehicles'};
            for (var b in _bookingsData) {
              final vc = (b['vehicleCategory'] ?? (b['vehicle'] != null ? b['vehicle']['name'] : 'Unknown')).toString();
              if (vc.isNotEmpty && vc != 'Unknown') {
                vehicleTypes.add(vc);
              }
            }

            // Filter the bookings
            List<Map<String, dynamic>> filteredBookings = _bookingsData.where((b) {
              // 1. Status Filter
              bool statusMatch = false;
              if (dialogFilter == 'All') {
                statusMatch = true;
              } else {
                final status = (b['status']?.toString() ?? 'unknown').toLowerCase();
                final tState = (b['tripState']?.toString() ?? 'unknown').toLowerCase();
                
                if (dialogFilter == 'Completed') {
                  statusMatch = status == 'completed' || tState == 'completed';
                } else if (dialogFilter == 'Pending') {
                  statusMatch = status == 'pending' || status == 'searching' || tState == 'searching';
                } else if (dialogFilter == 'Canceled') {
                  statusMatch = status == 'canceled' || status == 'cancelled' || status == 'rejected';
                } else if (dialogFilter == 'Expired') {
                  statusMatch = status == 'expired';
                } else if (dialogFilter == 'Ongoing') {
                  statusMatch = status == 'ongoing' || status == 'accepted' || status == 'arrived' || status == 'started';
                }
              }

              // 2. Vehicle Filter
              bool vehicleMatch = false;
              if (vehicleFilter == 'All Vehicles') {
                vehicleMatch = true;
              } else {
                final vc = (b['vehicleCategory'] ?? (b['vehicle'] != null ? b['vehicle']['name'] : 'Unknown')).toString();
                vehicleMatch = (vc == vehicleFilter);
              }

              return statusMatch && vehicleMatch;
            }).toList();

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 800,
                height: 600,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'All Bookings (${filteredBookings.length})',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(ctx),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Status Filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'All', 'Completed', 'Pending', 'Ongoing', 'Canceled', 'Expired'
                        ].map((f) {
                          final isSel = dialogFilter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(f),
                              selected: isSel,
                              selectedColor: const Color(0xFF2563EB).withValues(alpha: 0.2),
                              onSelected: (val) {
                                if (val) setDialogState(() => dialogFilter = f);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Vehicle Category Filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: vehicleTypes.map((f) {
                          final isSel = vehicleFilter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(f),
                              selected: isSel,
                              selectedColor: const Color(0xFFD97706).withValues(alpha: 0.2),
                              onSelected: (val) {
                                if (val) setDialogState(() => vehicleFilter = f);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    
                    const Divider(height: 32),
                    Expanded(
                      child: filteredBookings.isEmpty 
                        ? const Center(child: Text("No bookings found for the selected filters", style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                        itemCount: filteredBookings.length,
                        padding: const EdgeInsets.only(top: 8, bottom: 20),
                        itemBuilder: (context, index) {
                          final data = filteredBookings[index];
                          final bookingId = data['id']?.toString() ?? 'N/A';
                          final memberName = data['memberName']?.toString() ?? 'Unknown Passenger';
                          final baseDriverName = data['driverName']?.toString() ?? 'Unassigned';
                          final driverMemNo = data['acceptedBy']?.toString() ?? data['driverId']?.toString() ?? '';
                          final driverName = driverMemNo.isNotEmpty && driverMemNo != baseDriverName 
                              ? '$baseDriverName - $driverMemNo' 
                              : baseDriverName;
                          final fare = double.tryParse(data['totalFare']?.toString() ?? data['estimateFare']?.toString() ?? '0') ?? 0;
                          final status = data['status']?.toString().toUpperCase() ?? 'UNKNOWN';
                          
                          // Parse Date
                          DateTime? dateObj;
                          final val = data['createdAt'] ?? data['tripStartTime'] ?? data['pickupTime'];
                          if (val != null) {
                            if (val is Timestamp) {
                              dateObj = val.toDate();
                            } else if (val is int) {
                              dateObj = DateTime.fromMillisecondsSinceEpoch(val);
                            } else if (val is String) {
                              dateObj = DateTime.tryParse(val);
                            }
                          }
                          final dateStr = dateObj != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(dateObj.toLocal()) : 'Unknown Date';
                          final vc = (data['vehicleCategory'] ?? (data['vehicle'] != null ? data['vehicle']['name'] : 'Unknown')).toString();
                          final vcl = vc.toLowerCase();

                          IconData vehicleIcon = Icons.local_taxi;
                          if (vcl.contains('tuk')) vehicleIcon = Icons.electric_rickshaw;
                          else if (vcl.contains('van') || vcl.contains('roof')) vehicleIcon = Icons.airport_shuttle;
                          else if (vcl.contains('car') || vcl.contains('sedan') || vcl.contains('mini')) vehicleIcon = Icons.directions_car;

                          Color statusColor = Colors.grey;
                          Color statusBg = Colors.grey.withValues(alpha: 0.1);
                          if (status == 'COMPLETED') { statusColor = Colors.green.shade700; statusBg = Colors.green.withValues(alpha: 0.1); }
                          else if (status == 'ONGOING' || status == 'STARTED' || status == 'ARRIVED') { statusColor = Colors.purple.shade700; statusBg = Colors.purple.withValues(alpha: 0.1); }
                          else if (status == 'CANCELED' || status == 'CANCELLED' || status == 'REJECTED') { statusColor = Colors.red.shade700; statusBg = Colors.red.withValues(alpha: 0.1); }
                          else if (status == 'PENDING' || status == 'SEARCHING') { statusColor = Colors.orange.shade700; statusBg = Colors.orange.withValues(alpha: 0.1); }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => BookingDetailDialog(bookingData: data),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(vehicleIcon, color: Colors.blue.shade700, size: 24),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    memberName,
                                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  'Rs ${fare.toStringAsFixed(0)}',
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.confirmation_number_outlined, size: 14, color: Color(0xFF64748B)),
                                                const SizedBox(width: 4),
                                                Text(bookingId, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                                                const SizedBox(width: 12),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    vc,
                                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF64748B)),
                                                    const SizedBox(width: 4),
                                                    Text(dateStr, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                                  ],
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: statusBg,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    status,
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 0.5),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                                                const SizedBox(width: 4),
                                                Text('Driver: $driverName', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  void _showRoadPickupsListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        String dialogFilter = 'All';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            List<Map<String, dynamic>> filteredPickups = _roadPickupsData.where((b) {
              if (dialogFilter == 'All') return true;
              final rawStatus = (b['status']?.toString() ?? b['tripState']?.toString() ?? '').toLowerCase();
              final status = rawStatus.isEmpty ? 'completed' : rawStatus;
              
              if (dialogFilter == 'Completed') {
                return status == 'completed';
              } else if (dialogFilter == 'Canceled') {
                return status == 'canceled' || status == 'cancelled' || status == 'rejected';
              } else if (dialogFilter == 'Ongoing') {
                return status == 'ongoing' || status == 'accepted' || status == 'started';
              }
              return true;
            }).toList();

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 800,
                height: 600,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Road Pickups (${filteredPickups.length})',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(ctx),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'All', 'Completed', 'Ongoing'
                        ].map((f) {
                          final isSel = dialogFilter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(f),
                              selected: isSel,
                              selectedColor: const Color(0xFF059669).withValues(alpha: 0.2),
                              onSelected: (val) {
                                if (val) setDialogState(() => dialogFilter = f);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(height: 32),
                    Expanded(
                      child: filteredPickups.isEmpty 
                        ? const Center(child: Text("No road pickups found for the selected filter", style: TextStyle(color: Colors.grey)))
                        : ListView.separated(
                        itemCount: filteredPickups.length,
                        separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final data = filteredPickups[index];
                            data['isRoadPickup'] = true;
                            final bookingId = data['id']?.toString() ?? 'N/A';
                            final memberName = data['memberName']?.toString() ?? data['passengerName']?.toString() ?? 'Street Passenger';
                            final baseDriverName = data['driverName']?.toString() ?? 'Unassigned';
                            final driverMemNo = data['acceptedBy']?.toString() ?? data['driverId']?.toString() ?? '';
                            final driverName = driverMemNo.isNotEmpty && driverMemNo != baseDriverName 
                                ? '$baseDriverName - $driverMemNo' 
                                : baseDriverName;
                            final fare = double.tryParse(data['totalFare']?.toString() ?? data['estimateFare']?.toString() ?? data['fare']?.toString() ?? '0') ?? 0;
                            final status = data['status']?.toString().toUpperCase() ?? data['tripState']?.toString().toUpperCase() ?? 'UNKNOWN';
                            
                            // Parse Date
                            DateTime? dateObj;
                            final val = data['startedAt'] ?? data['tripStartTime'] ?? data['createdAt'];
                            if (val != null) {
                              if (val is Timestamp) {
                                dateObj = val.toDate();
                              } else if (val is int) {
                                dateObj = DateTime.fromMillisecondsSinceEpoch(val);
                              } else if (val is String) {
                                dateObj = DateTime.tryParse(val);
                              }
                            }
                            final dateStr = dateObj != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(dateObj.toLocal()) : 'Unknown Date';
                            final vc = (data['vehicleCategory'] ?? (data['vehicle'] != null ? data['vehicle']['name'] : 'Unknown')).toString();
                            final vcl = vc.toLowerCase();

                            IconData vehicleIcon = Icons.hail_rounded;
                            if (vcl.contains('tuk')) vehicleIcon = Icons.electric_rickshaw;
                            else if (vcl.contains('van') || vcl.contains('roof')) vehicleIcon = Icons.airport_shuttle;
                            else if (vcl.contains('car') || vcl.contains('sedan') || vcl.contains('mini')) vehicleIcon = Icons.directions_car;

                            Color statusColor = Colors.grey;
                            Color statusBg = Colors.grey.withValues(alpha: 0.1);
                            if (status == 'COMPLETED') { statusColor = Colors.green.shade700; statusBg = Colors.green.withValues(alpha: 0.1); }
                            else if (status == 'ONGOING' || status == 'STARTED' || status == 'ARRIVED') { statusColor = Colors.purple.shade700; statusBg = Colors.purple.withValues(alpha: 0.1); }
                            else if (status == 'CANCELED' || status == 'CANCELLED' || status == 'REJECTED') { statusColor = Colors.red.shade700; statusBg = Colors.red.withValues(alpha: 0.1); }
                            else if (status == 'PENDING' || status == 'SEARCHING') { statusColor = Colors.orange.shade700; statusBg = Colors.orange.withValues(alpha: 0.1); }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => BookingDetailDialog(bookingData: data),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF059669).withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(vehicleIcon, color: const Color(0xFF059669), size: 24),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      memberName,
                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Rs ${fare.toStringAsFixed(0)}',
                                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  const Icon(Icons.confirmation_number_outlined, size: 14, color: Color(0xFF64748B)),
                                                  const SizedBox(width: 4),
                                                  Text(bookingId, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                                                  if (vc != 'Unknown') ...[
                                                    const SizedBox(width: 12),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF059669).withValues(alpha: 0.1),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        vc,
                                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF64748B)),
                                                      const SizedBox(width: 4),
                                                      Text(dateStr, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                                    ],
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: statusBg,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Text(
                                                      status,
                                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 0.5),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                                                  const SizedBox(width: 4),
                                                  Text('Driver: $driverName', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          );
        }
      );
    }

  void _showTransactionsDialog(BuildContext context) {
    // Collect all completed trips
    List<Map<String, dynamic>> completedTrips = [];
    
    for (var b in _bookingsData) {
      final status = (b['status']?.toString() ?? b['tripState']?.toString() ?? '').toLowerCase();
      if (status == 'completed') {
        b['isRoadPickup'] = false;
        completedTrips.add(b);
      }
    }
    
    for (var rp in _roadPickupsData) {
      final rawStatus = (rp['status']?.toString() ?? rp['tripState']?.toString() ?? '').toLowerCase();
      final status = rawStatus.isEmpty ? 'completed' : rawStatus;
      if (status == 'completed') {
        rp['isRoadPickup'] = true;
        completedTrips.add(rp);
      }
    }

    // Sort by newest
    completedTrips.sort((a, b) {
      final aTime = a['timestamp'] is Timestamp ? (a['timestamp'] as Timestamp).toDate() : DateTime(2000);
      final bTime = b['timestamp'] is Timestamp ? (b['timestamp'] as Timestamp).toDate() : DateTime(2000);
      return bTime.compareTo(aTime);
    });

    showDialog(
      context: context,
      builder: (ctx) {
        String filter = 'All'; // All, Scheduled, Road Pickups
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            List<Map<String, dynamic>> displayTrips = completedTrips.where((t) {
              if (filter == 'Scheduled') return t['isRoadPickup'] == false;
              if (filter == 'Road Pickups') return t['isRoadPickup'] == true;
              return true;
            }).toList();

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 900,
                height: 700,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Transactions Breakdown',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(ctx),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Transaction Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildTxnSummaryCard(
                            'Total Txns (All)', 
                            _totalCompletedTxns, 
                            Icons.account_balance_wallet_rounded, 
                            const Color(0xFFD97706)
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTxnSummaryCard(
                            'Scheduled Txns', 
                            _scheduledCompletedTxns, 
                            Icons.payments_rounded, 
                            const Color(0xFF0284C7)
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTxnSummaryCard(
                            'Road Pickups Txns', 
                            _roadPickupCompletedTxns, 
                            Icons.point_of_sale_rounded, 
                            const Color(0xFF059669)
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTxnSummaryCard(
                            'App Income (3%)', 
                            _totalCompletedTxns * 0.03, 
                            Icons.monetization_on_rounded, 
                            const Color(0xFF7C3AED)
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'All', 'Scheduled', 'Road Pickups'
                        ].map((f) {
                          final isSel = filter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(f),
                              selected: isSel,
                              selectedColor: const Color(0xFFD97706).withValues(alpha: 0.2),
                              onSelected: (val) {
                                if (val) setDialogState(() => filter = f);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    
                    const Divider(height: 32),
                    
                    Expanded(
                      child: displayTrips.isEmpty 
                        ? const Center(child: Text("No transactions found", style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                        itemCount: displayTrips.length,
                        padding: const EdgeInsets.only(top: 8, bottom: 20),
                        itemBuilder: (context, index) {
                          final data = displayTrips[index];
                          final isPickup = data['isRoadPickup'] == true;
                          final bookingId = data['id']?.toString() ?? 'N/A';
                          final memberName = data['memberName']?.toString() ?? data['passengerName']?.toString() ?? 'Street Passenger';
                          final baseDriverName = data['driverName']?.toString() ?? 'Unassigned';
                          final driverMemNo = data['acceptedBy']?.toString() ?? data['driverId']?.toString() ?? '';
                          final driverName = driverMemNo.isNotEmpty && driverMemNo != baseDriverName 
                              ? '$baseDriverName - $driverMemNo' 
                              : baseDriverName;
                          final fare = double.tryParse(data['actualFare']?.toString() ?? data['totalFare']?.toString() ?? data['estimateFare']?.toString() ?? data['fare']?.toString() ?? '0') ?? 0;
                          final commission = fare * 0.03;
                          
                          // Parse Date
                          DateTime? dateObj;
                          final val = data['createdAt'] ?? data['tripStartTime'] ?? data['pickupTime'] ?? data['startedAt'];
                          if (val != null) {
                            if (val is Timestamp) {
                              dateObj = val.toDate();
                            } else if (val is int) {
                              dateObj = DateTime.fromMillisecondsSinceEpoch(val);
                            } else if (val is String) {
                              dateObj = DateTime.tryParse(val);
                            }
                          }
                          final dateStr = dateObj != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(dateObj.toLocal()) : 'Unknown Date';
                          final vc = (data['vehicleCategory'] ?? (data['vehicle'] != null ? data['vehicle']['name'] : 'Unknown')).toString();
                          final vcl = vc.toLowerCase();

                          IconData vehicleIcon = isPickup ? Icons.hail_rounded : Icons.local_taxi;
                          if (vcl.contains('tuk')) vehicleIcon = Icons.electric_rickshaw;
                          else if (vcl.contains('van') || vcl.contains('roof')) vehicleIcon = Icons.airport_shuttle;
                          else if (vcl.contains('car') || vcl.contains('sedan') || vcl.contains('mini')) vehicleIcon = Icons.directions_car;

                          Color typeColor = isPickup ? const Color(0xFF059669) : const Color(0xFF0284C7);
                          String typeLabel = vc.toUpperCase();
                          if (typeLabel.isEmpty || typeLabel == 'UNKNOWN') {
                            typeLabel = isPickup ? 'ROAD PICKUP' : 'SCHEDULED';
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => BookingDetailDialog(bookingData: data),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: typeColor.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(vehicleIcon, color: typeColor, size: 24),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    memberName,
                                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  'Rs ${fare.toStringAsFixed(0)}',
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.confirmation_number_outlined, size: 14, color: Color(0xFF64748B)),
                                                    const SizedBox(width: 4),
                                                    Text(bookingId, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                                                    const SizedBox(width: 12),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: typeColor.withValues(alpha: 0.1),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        typeLabel,
                                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: typeColor),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.monetization_on_outlined, size: 14, color: Color(0xFF10B981)),
                                                    const SizedBox(width: 4),
                                                    Text('App Fee (3%): Rs ${commission.toStringAsFixed(1)}', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF64748B)),
                                                    const SizedBox(width: 4),
                                                    Text(dateStr, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                                                    const SizedBox(width: 4),
                                                    Text('Driver: $driverName', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildTxnSummaryCard(String title, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rs ${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedFilterType == 'Custom Date' && _customStartDate != null 
                  ? 'TRIP SUMMARY (${_customStartDate!.year}-${_customStartDate!.month.toString().padLeft(2, '0')}-${_customStartDate!.day.toString().padLeft(2, '0')})'
                  : 'TRIP SUMMARY (${_selectedFilterType.toUpperCase()})',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF64748B),
                letterSpacing: 1.2,
              ),
            ),
            Row(
              children: [
                _buildFilterChip('Today'),
                const SizedBox(width: 8),
                _buildFilterChip('This Week'),
                const SizedBox(width: 8),
                _buildFilterChip('This Month'),
                const SizedBox(width: 8),
                _buildFilterChip('Custom Date'),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30.0),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 1200 ? 4 : (width > 900 ? 3 : (width > 600 ? 2 : 1));
              
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3.0,
                children: [
                  _DailyMetricCard(
                    'Total Bookings', 
                    _totalBookings.toString(), 
                    Icons.book_online_rounded, 
                    const Color(0xFF2563EB),
                    onTap: () => _showBookingsListDialog(context),
                  ),
                  _DailyMetricCard(
                    'Road Pickups',
                    _totalRoadPickups.toString(),
                    Icons.hail_rounded,
                    const Color(0xFF059669),
                    onTap: () => _showRoadPickupsListDialog(context),
                  ),
                  _DailyMetricCard('Ongoing Trips', _ongoingTrips.toString(), Icons.local_taxi_rounded, const Color(0xFF7C3AED)),
                  _DailyMetricCard('Canceled Trips', _cancelTrips.toString(), Icons.cancel_rounded, const Color(0xFFDC2626)),
                  _DailyMetricCard(
                    'Total Transactions', 
                    'Rs ${_totalCompletedTxns.toStringAsFixed(0)}', 
                    Icons.payments_rounded, 
                    const Color(0xFFD97706),
                    onTap: () => _showTransactionsDialog(context),
                  ),
                  _DailyMetricCard('Union Incomes', 'Rs ${_unionIncomes.toStringAsFixed(0)}', Icons.account_balance_rounded, const Color(0xFF4F46E5)),
                  _DailyMetricCard('Txn Requests', _transactionRequests.toString(), Icons.request_quote_rounded, const Color(0xFFE11D48)),
                ],
              );
            }
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilterType == label;
    return InkWell(
      onTap: () => _onFilterChanged(label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _DailyMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  const _DailyMetricCard(this.title, this.value, this.icon, this.accentColor, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
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
      ),
    );
  }
}
