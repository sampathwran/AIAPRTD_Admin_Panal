import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/scheduled_bookings/widgets/admin_booking_card.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/scheduled_bookings/widgets/admin_empty_booking_state.dart';

class UpcomingBookingsPanel extends StatefulWidget {
  final VoidCallback onBack;
  const UpcomingBookingsPanel({super.key, required this.onBack});

  @override
  State<UpcomingBookingsPanel> createState() => _UpcomingBookingsPanelState();
}

class _UpcomingBookingsPanelState extends State<UpcomingBookingsPanel> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
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
                        'Upcoming Bookings (Scheduled)',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage all advance and scheduled bookings',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // TAB BAR
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.orange.shade700,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Ongoing'),
                    Tab(text: 'Completed'),
                    Tab(text: 'Cancelled'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tab Content
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('all_bookings')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.orange),
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
                                color: Colors.orange,
                              ),
                            );
                          }
                          if (!fallbackSnapshot.hasData ||
                              fallbackSnapshot.data!.docs.isEmpty) {
                            return _buildEmptyStateForAllTabs();
                          }
                          return _buildTabBarView(fallbackSnapshot.data!.docs);
                        },
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyStateForAllTabs();
                    }

                    return _buildTabBarView(snapshot.data!.docs);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateForAllTabs() {
    return const TabBarView(
      children: [
        AdminEmptyBookingState(
          title: "No Upcoming Bookings",
          subtitle: "There are no upcoming scheduled rides.",
        ),
        AdminEmptyBookingState(
          title: "No Ongoing Bookings",
          subtitle: "There are no ongoing rides currently.",
        ),
        AdminEmptyBookingState(
          title: "No Completed Bookings",
          subtitle: "There are no completed rides to show.",
        ),
        AdminEmptyBookingState(
          title: "No Cancelled Bookings",
          subtitle: "There are no cancelled rides.",
        ),
      ],
    );
  }

  Widget _buildTabBarView(List<QueryDocumentSnapshot> allDocs) {
    // Filter docs by status
    final upcomingDocs = allDocs.where((doc) {
      final status =
          (doc.data() as Map<String, dynamic>)['status']
              ?.toString()
              .toLowerCase() ??
          '';
      return status == 'pending';
    }).toList();

    final ongoingDocs = allDocs.where((doc) {
      final status =
          (doc.data() as Map<String, dynamic>)['status']
              ?.toString()
              .toLowerCase() ??
          '';
      return status == 'ongoing' || status == 'accepted';
    }).toList();

    final completedDocs = allDocs.where((doc) {
      final status =
          (doc.data() as Map<String, dynamic>)['status']
              ?.toString()
              .toLowerCase() ??
          '';
      return status == 'completed' || status == 'collected';
    }).toList();

    final cancelledDocs = allDocs.where((doc) {
      final status =
          (doc.data() as Map<String, dynamic>)['status']
              ?.toString()
              .toLowerCase() ??
          '';
      return status == 'cancelled';
    }).toList();

    return TabBarView(
      children: [
        _buildBookingGrid(
          upcomingDocs,
          "No Upcoming Bookings",
          "There are no upcoming scheduled rides.",
        ),
        _buildBookingGrid(
          ongoingDocs,
          "No Ongoing Bookings",
          "There are no ongoing rides currently.",
        ),
        _buildBookingGrid(
          completedDocs,
          "No Completed Bookings",
          "There are no completed rides to show.",
        ),
        _buildBookingGrid(
          cancelledDocs,
          "No Cancelled Bookings",
          "There are no cancelled rides.",
        ),
      ],
    );
  }

  Widget _buildBookingGrid(
    List<QueryDocumentSnapshot> docs,
    String emptyTitle,
    String emptySubtitle,
  ) {
    if (docs.isEmpty) {
      return AdminEmptyBookingState(title: emptyTitle, subtitle: emptySubtitle);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1200
            ? 3
            : (constraints.maxWidth > 800 ? 2 : 1);

        return GridView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: crossAxisCount == 1 ? 2.0 : 1.6,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            // Add ID for AdminBookingCard
            final cardData = Map<String, dynamic>.from(data);
            cardData['bookingId'] = docs[index].id;

            return AdminBookingCard(data: cardData);
          },
        );
      },
    );
  }
}
