import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/scheduled_bookings/widgets/admin_empty_booking_state.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/scheduled_bookings/tabs/pending_tab.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/scheduled_bookings/tabs/ongoing_pickup_tab.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/scheduled_bookings/tabs/ongoing_drop_tab.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/scheduled_bookings/tabs/completed_tab.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/scheduled_bookings/tabs/cancelled_tab.dart';

class ScheduledBookingsFullPanel extends StatefulWidget {
  final VoidCallback onBack;
  const ScheduledBookingsFullPanel({super.key, required this.onBack});

  @override
  State<ScheduledBookingsFullPanel> createState() =>
      _ScheduledBookingsFullPanelState();
}

class _ScheduledBookingsFullPanelState
    extends State<ScheduledBookingsFullPanel> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================================
              // ⬅️ SECTION 1: HEADER
              // ==========================================================
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: Colors.black87,
                    ),
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scheduled Bookings',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage and monitor all scheduled bookings',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ==========================================================
              // 🔄 SECTION 2: CONTENT (STREAM BUILDER)
              // ==========================================================
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('all_bookings')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Colors.deepOrange,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      // Fallback without orderBy if index is missing
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('all_bookings')
                            .snapshots(),
                        builder: (context, fallbackSnapshot) {
                          if (fallbackSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.deepOrange,
                              ),
                            );
                          }
                          if (!fallbackSnapshot.hasData) {
                            return _buildEmptyStateForAllTabs();
                          }
                          return _buildMainContent(fallbackSnapshot.data!.docs);
                        },
                      );
                    }

                    if (!snapshot.hasData) {
                      return _buildEmptyStateForAllTabs();
                    }

                    return _buildMainContent(snapshot.data!.docs);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(List<QueryDocumentSnapshot> allDocs) {
    // 1. Extract Unique Vehicle Categories
    final Set<String> categories = {'All'};
    for (var doc in allDocs) {
      final data = doc.data() as Map<String, dynamic>;
      String vc =
          data['vehicleCategory']?.toString() ??
          (data['vehicle'] != null
              ? data['vehicle']['name']?.toString()
              : null) ??
          'Mini';
      if (vc.isNotEmpty) categories.add(vc);
    }

    // 2. Filter Docs by Selected Category
    final categoryFilteredDocs = _selectedCategory == 'All'
        ? allDocs
        : allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            String vc =
                data['vehicleCategory']?.toString() ??
                (data['vehicle'] != null
                    ? data['vehicle']['name']?.toString()
                    : null) ??
                'Mini';
            return vc == _selectedCategory.split(' (')[0];
          }).toList();

    // Map categories to their counts for the chips
    final Map<String, int> categoryCounts = {};
    for (var doc in allDocs) {
      final data = doc.data() as Map<String, dynamic>;
      String vc =
          data['vehicleCategory']?.toString() ??
          (data['vehicle'] != null
              ? data['vehicle']['name']?.toString()
              : null) ??
          'Mini';
      if (vc.isNotEmpty) {
        categoryCounts[vc] = (categoryCounts[vc] ?? 0) + 1;
      }
    }

    // Prepare display labels for chips e.g., 'Car (12)'
    final List<String> displayCategories = ['All (${allDocs.length})'];
    for (var cat in categories.where((c) => c != 'All')) {
      displayCategories.add('$cat (${categoryCounts[cat] ?? 0})');
    }

    // Determine the actual selected category label to match against the chips
    String selectedChipLabel = displayCategories.firstWhere(
      (c) =>
          c.startsWith(_selectedCategory == 'All' ? 'All' : _selectedCategory),
      orElse: () => displayCategories[0],
    );

    // 3. Filter Docs by Status
    final pendingDocs = categoryFilteredDocs.where((doc) {
      final status =
          (doc.data() as Map<String, dynamic>)['status']
              ?.toString()
              .toLowerCase() ??
          '';
      return status == 'pending';
    }).toList();

    final ongoingPickupDocs = categoryFilteredDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status']?.toString().toLowerCase() ?? '';
      final hasStarted =
          data['startedAt'] != null || data['tripStartTime'] != null;
      return (status == 'ongoing pickup' && !hasStarted) ||
          (status == 'accepted' && !hasStarted);
    }).toList();

    final ongoingDropDocs = categoryFilteredDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status']?.toString().toLowerCase() ?? '';
      final hasStarted =
          data['startedAt'] != null || data['tripStartTime'] != null;
      return status == 'ongoing drop' ||
          status == 'arrived' ||
          status == 'ongoing' ||
          ((status == 'accepted' || status == 'ongoing pickup') && hasStarted);
    }).toList();

    final completedDocs = categoryFilteredDocs.where((doc) {
      final status =
          (doc.data() as Map<String, dynamic>)['status']
              ?.toString()
              .toLowerCase() ??
          '';
      return status == 'completed';
    }).toList();

    final cancelledDocs = categoryFilteredDocs.where((doc) {
      final status =
          (doc.data() as Map<String, dynamic>)['status']
              ?.toString()
              .toLowerCase() ??
          '';
      return status == 'cancelled';
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CATEGORY CHIPS
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: displayCategories.map((displayCat) {
              final isSelected = displayCat == selectedChipLabel;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ChoiceChip(
                  label: Text(
                    displayCat,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Colors.deepOrange,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? Colors.deepOrange
                          : Colors.grey.shade300,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        // Extract just the category name before ' ('
                        _selectedCategory = displayCat.split(' (')[0];
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // TAB BAR (With Counts)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TabBar(
            isScrollable: true,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: Colors.deepOrange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.deepOrange.shade700,
            unselectedLabelColor: Colors.grey.shade600,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: 'Pending (${pendingDocs.length})'),
              Tab(text: 'Ongoing Pickup (${ongoingPickupDocs.length})'),
              Tab(text: 'Ongoing Drop (${ongoingDropDocs.length})'),
              Tab(text: 'Completed (${completedDocs.length})'),
              Tab(text: 'Cancelled (${cancelledDocs.length})'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // TAB VIEWS
        Expanded(
          child: TabBarView(
            children: [
              PendingTab(docs: pendingDocs),
              OngoingPickupTab(docs: ongoingPickupDocs),
              OngoingDropTab(docs: ongoingDropDocs),
              CompletedTab(docs: completedDocs),
              CancelledTab(docs: cancelledDocs),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateForAllTabs() {
    return const Column(
      children: [
        SizedBox(height: 40),
        AdminEmptyBookingState(
          title: "No Data",
          subtitle: "There are no bookings available.",
        ),
      ],
    );
  }
}
