import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/scheduled_bookings/widgets/admin_booking_card.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/scheduled_bookings/widgets/admin_empty_booking_state.dart';

class CanceledTripsPanel extends StatefulWidget {
  final VoidCallback onBack;
  const CanceledTripsPanel({super.key, required this.onBack});

  @override
  State<CanceledTripsPanel> createState() => _CanceledTripsPanelState();
}

class _CanceledTripsPanelState extends State<CanceledTripsPanel> {
  String _searchQuery = '';

  Widget _buildGrid(List<QueryDocumentSnapshot> docs, bool isLiveTrip) {
    // Search filtering engine
    final filteredTrips = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final driverName = (data['driverName'] ?? '').toString().toLowerCase();
      final passengerName = (data['passengerName'] ?? data['memberId'] ?? '')
          .toString()
          .toLowerCase();
      final tripId = doc.id.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return driverName.contains(query) ||
          passengerName.contains(query) ||
          tripId.contains(query);
    }).toList();

    if (filteredTrips.isEmpty) {
      return const AdminEmptyBookingState(
        title: 'No Canceled Rides',
        subtitle: 'There are no canceled rides to display.',
      );
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
          itemCount: filteredTrips.length,
          itemBuilder: (context, index) {
            final doc = filteredTrips[index];
            final data = doc.data() as Map<String, dynamic>;

            Map<String, dynamic> cardData;

            if (isLiveTrip) {
              cardData = {
                'tripId': doc.id,
                'memberId': data['passengerName'] ?? 'Customer',
                'memberPhone': data['driverName'] != null
                    ? 'Driver: ${data['driverName']}'
                    : '',
                'startAddress': data['pickupAddress'],
                'endAddress': data['dropAddress'],
                'estimateFare': data['estimatedFare'],
                'pickupTime': data['timestamp'] != null
                    ? (data['timestamp'] as Timestamp)
                          .toDate()
                          .toIso8601String()
                    : null,
                'status': data['status'] ?? 'canceled',
              };
            } else {
              cardData = Map<String, dynamic>.from(data);
              cardData['bookingId'] = doc.id;
            }

            return AdminBookingCard(data: cardData);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
                        'Canceled Trips Log',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Audit log for trips canceled by driver, customer, or system',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ==========================================================
              // 🔎 SECTION 2: LIVE SEARCH
              // ==========================================================
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by Driver Name, Customer, or Trip ID...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Colors.grey,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
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
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.red.shade700,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Road Pickups (Live)'),
                    Tab(text: 'Advance Bookings'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ==========================================================
              // 📊 SECTION 3: LISTINGS
              // ==========================================================
              Expanded(
                child: TabBarView(
                  children: [
                    // TAB 1: ROAD PICKUPS
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('trips')
                          .where('status', isEqualTo: 'canceled')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: Colors.red),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        return _buildGrid(snapshot.data?.docs ?? [], true);
                      },
                    ),

                    // TAB 2: ADVANCE BOOKINGS
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('all_bookings')
                          .where('status', isEqualTo: 'cancelled')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: Colors.red),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        return _buildGrid(snapshot.data?.docs ?? [], false);
                      },
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
