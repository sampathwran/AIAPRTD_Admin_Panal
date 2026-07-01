import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OngoingTripsPanel extends StatefulWidget {
  final VoidCallback onBack;
  const OngoingTripsPanel({super.key, required this.onBack});

  @override
  State<OngoingTripsPanel> createState() => _OngoingTripsPanelState();
}

class _OngoingTripsPanelState extends State<OngoingTripsPanel> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.black87),
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Ongoing Rides Tracker',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                    SizedBox(height: 4),
                    Text('Real-time tracking of passenger nodes currently in transit', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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

            // ==========================================================
            // 📊 SECTION 3: REAL-TIME ONGOING TRIPS STREAM
            // ==========================================================
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // 💡 Realtime Snapshot: Firestore එකේ 'trips' collection එකෙන් ongoing ඒවා විතරක් පෙරලා ගන්නවා
                stream: FirebaseFirestore.instance
                    .collection('trips')
                    .where('status', isEqualTo: 'ongoing')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.purple));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading trips: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }

                  final tripDocs = snapshot.data?.docs ?? [];

                  // Search filtering engine
                  final filteredTrips = tripDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final driverName = (data['driverName'] ?? '').toString().toLowerCase();
                    final passengerName = (data['passengerName'] ?? '').toString().toLowerCase();
                    final tripId = doc.id.toLowerCase();
                    final query = _searchQuery.toLowerCase();
                    return driverName.contains(query) || passengerName.contains(query) || tripId.contains(query);
                  }).toList();

                  if (filteredTrips.isEmpty) {
                    return const Center(
                      child: Text('No active rides streaming in real-time right now.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    );
                  }

                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF000000).withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 1100),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(Colors.purple.withValues(alpha: 0.02)),
                              dataRowMinHeight: 60,
                              dataRowMaxHeight: 60,
                              columns: const [
                                DataColumn(label: Text('Trip ID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                                DataColumn(label: Text('Driver Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                                DataColumn(label: Text('Passenger', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                                DataColumn(label: Text('Pickup Location', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                                DataColumn(label: Text('Destination', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                                DataColumn(label: Text('Fare Estimate', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                                DataColumn(label: Text('Live Track', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple))),
                              ],
                              rows: filteredTrips.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return DataRow(cells: [
                                  DataCell(Text(doc.id.substring(0, doc.id.length > 8 ? 8 : doc.id.length).toUpperCase(), style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold))),
                                  DataCell(Text(data['driverName'] ?? 'Assigning...')),
                                  DataCell(Text(data['passengerName'] ?? 'Customer')),
                                  DataCell(Text(data['pickupAddress'] ?? 'Point A', maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  DataCell(Text(data['dropAddress'] ?? 'Point B', maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  DataCell(Text('LKR ${data['estimatedFare'] ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.w600))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.route_rounded, size: 12, color: Colors.purple),
                                          SizedBox(width: 4),
                                          Text("IN TRANSIT", style: TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ]);
                              }).toList(),
                            ),
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
}