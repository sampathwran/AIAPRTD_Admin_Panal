import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';

class RevenueOverviewTab extends StatefulWidget {
  const RevenueOverviewTab({super.key});

  @override
  State<RevenueOverviewTab> createState() => _RevenueOverviewTabState();
}

class _RevenueOverviewTabState extends State<RevenueOverviewTab> {
  bool _isLoading = true;
  String _selectedFilterType = 'This Month';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  double _scheduledTxns = 0;
  double _roadPickupTxns = 0;
  double _totalTxns = 0;
  double _appIncome = 0;

  List<String> _cachedMembershipNumbers = [];
  bool _membersCached = false;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    if (!mounted) return;
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
      startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      endDate = startDate.add(const Duration(days: 7));
    } else if (_selectedFilterType == 'This Month') {
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 1);
    } else if (_selectedFilterType == 'Custom Date' && _customStartDate != null && _customEndDate != null) {
      startDate = _customStartDate!;
      endDate = _customEndDate!;
    } else {
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 1);
    }

    double scheduledMoney = 0;
    double roadPickupMoney = 0;

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
      for (var doc in bookingsSnap.docs) {
        final data = doc.data();
        final status = (data['status']?.toString() ?? data['tripState']?.toString() ?? '').toLowerCase();
        if (status == 'completed') {
          scheduledMoney += double.tryParse(data['actualFare']?.toString() ?? data['totalFare']?.toString() ?? data['estimateFare']?.toString() ?? '0') ?? 0;
        }
      }

      final dailyTripsSnap = await FirebaseFirestore.instance
          .collection('dayly_trips')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThan: Timestamp.fromDate(endDate))
          .get();
      for (var doc in dailyTripsSnap.docs) {
        final data = doc.data();
        final status = (data['status']?.toString() ?? data['tripState']?.toString() ?? '').toLowerCase();
        if (status == 'completed') {
          scheduledMoney += double.tryParse(data['actualFare']?.toString() ?? data['totalFare']?.toString() ?? data['fare']?.toString() ?? '0') ?? 0;
        }
      }

      List<String> dateStrings = [];
      for (int i = 0; i < endDate.difference(startDate).inDays; i++) {
        final d = startDate.add(Duration(days: i));
        dateStrings.add("${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}");
        dateStrings.add("${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}");
      }

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
                  for (var doc in snap.docs) {
                    final data = doc.data();
                    final status = (data['status']?.toString() ?? data['tripState']?.toString() ?? '').toLowerCase();
                    if (status == 'completed') {
                      roadPickupMoney += double.tryParse(data['actualFare']?.toString() ?? data['totalFare']?.toString() ?? data['fare']?.toString() ?? '0') ?? 0;
                    }
                  }
                }).catchError((e) {})
          );
        }
      }
      
      for (int i = 0; i < pickupFutures.length; i += 500) {
        int end = (i + 500 < pickupFutures.length) ? i + 500 : pickupFutures.length;
        await Future.wait(pickupFutures.sublist(i, end));
      }

      if (mounted) {
        setState(() {
          _scheduledTxns = scheduledMoney;
          _roadPickupTxns = roadPickupMoney;
          _totalTxns = scheduledMoney + roadPickupMoney;
          _appIncome = _totalTxns * 0.03;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching finance summary: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AdminColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end.add(const Duration(days: 1)); // Include the end day fully
        _selectedFilterType = 'Custom Date';
      });
      _fetchSummary();
    }
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          'Today', 'This Week', 'This Month', 'Custom Date'
        ].map((filter) {
          final isSelected = _selectedFilterType == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                filter == 'Custom Date' && _selectedFilterType == 'Custom Date' && _customStartDate != null && _customEndDate != null
                    ? '${_customStartDate!.day}/${_customStartDate!.month}/${_customStartDate!.year} - ${_customEndDate!.subtract(const Duration(days: 1)).day}/${_customEndDate!.subtract(const Duration(days: 1)).month}/${_customEndDate!.subtract(const Duration(days: 1)).year}'
                    : filter,
              ),
              selected: isSelected,
              selectedColor: AdminColors.primary.withValues(alpha: 0.1),
              labelStyle: TextStyle(
                color: isSelected ? AdminColors.primary : AdminColors.muted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) {
                  if (filter == 'Custom Date') {
                    _selectCustomDateRange(context);
                  } else {
                    setState(() => _selectedFilterType = filter);
                    _fetchSummary();
                  }
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewCard(String title, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rs ${value.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
        _buildFilterChips(),
        const SizedBox(height: 24),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AdminColors.primary))
            : LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 900 ? 2 : 1;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: constraints.maxWidth > 900 ? 3.5 : 2.5,
                    children: [
                      _buildOverviewCard(
                        'Total Scheduled Bookings', 
                        _scheduledTxns, 
                        Icons.book_online_rounded, 
                        const Color(0xFF0284C7)
                      ),
                      _buildOverviewCard(
                        'Total Road Pickups', 
                        _roadPickupTxns, 
                        Icons.hail_rounded, 
                        const Color(0xFF059669)
                      ),
                      _buildOverviewCard(
                        'Combined Total Transactions', 
                        _totalTxns, 
                        Icons.account_balance_wallet_rounded, 
                        const Color(0xFFD97706)
                      ),
                      _buildOverviewCard(
                        'App Income (3% System Fee)', 
                        _appIncome, 
                        Icons.monetization_on_rounded, 
                        const Color(0xFF7C3AED)
                      ),
                    ],
                  );
                },
              ),
        ),
      ],
    );
  }
}
