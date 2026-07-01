import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // 💡 pubspec.yaml එකට එකතු කළ පසු මේ import එකේ error එක නැති වේවි

class CanceledTripsPanel extends StatefulWidget {
  final VoidCallback onBack;
  const CanceledTripsPanel({super.key, required this.onBack});

  @override
  State<CanceledTripsPanel> createState() => _CanceledTripsPanelState();
}

class _CanceledTripsPanelState extends State<CanceledTripsPanel> {
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
                      'Canceled Rides Audit Log',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    SizedBox(height: 4),
                    // 💡 Fixed Typo: In word 'reasonings' to 'reasons'
                    Text('Analysis logs on driver-side vs rider-side cancellation reasons', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ==========================================================
            // 🔎 SECTION 2: SEARCH UTILITY
            // ==========================================================
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search canceled rides by Driver, Passenger or Reason...',
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
            // 📊 SECTION 3: REAL-TIME CANCELED TRIPS STREAM
            // ==========================================================
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('trips')
                    .where('status', isEqualTo: 'canceled')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.red));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading logs: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }

                  final tripDocs = snapshot.data?.docs ?? [];

                  final filteredTrips = tripDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final driver = (data['driverName'] ?? '').toString().toLowerCase();
                    final passenger = (data['passengerName'] ?? '').toString().toLowerCase();
                    final reason = (data['cancelReason'] ?? '').toString().toLowerCase();
                    final query = _searchQuery.toLowerCase();
                    return driver.contains(query) || passenger.contains(query) || reason.contains(query);
                  }).toList();

                  if (filteredTrips.isEmpty) {
                    return const Center(
                      child: Text('No canceled ride logs found inside the query tracking.', style: TextStyle(color: Colors.grey, fontSize: 16)),
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
                              headingRowColor: WidgetStateProperty.all(Colors.red.withValues(alpha: 0.02)),
                              dataRowMinHeight: 60,
                              dataRowMaxHeight: 60,
                              columns: const [
                                DataColumn(label: Text('Trip ID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                                DataColumn(label: Text('Driver Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                                DataColumn(label: Text('Passenger', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                                DataColumn(label: Text('Canceled By', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                                DataColumn(label: Text('Reason Specification', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                                DataColumn(label: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
                              ],
                              rows: filteredTrips.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final String canceledBy = data['canceledBy'] ?? 'Rider';
                                final bool isDriverCanceled = canceledBy.toLowerCase() == 'driver';

                                String timeText = 'N/A';
                                if (data['timestamp'] != null) {
                                  final Timestamp t = data['timestamp'];
                                  timeText = DateFormat('MM/dd hh:mm a').format(t.toDate());
                                }

                                return DataRow(cells: [
                                  DataCell(Text(doc.id.substring(0, doc.id.length > 6 ? 6 : doc.id.length).toUpperCase(), style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold))),
                                  DataCell(Text(data['driverName'] ?? 'No Driver')),
                                  DataCell(Text(data['passengerName'] ?? 'Passenger')),
                                  DataCell(Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDriverCanceled ? Colors.orange.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      canceledBy.toUpperCase(),
                                      style: TextStyle(color: isDriverCanceled ? Colors.orange.shade800 : Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  )),
                                  DataCell(Text(data['cancelReason'] ?? 'Change of mind', maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  DataCell(Text(timeText, style: const TextStyle(fontSize: 12))),
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