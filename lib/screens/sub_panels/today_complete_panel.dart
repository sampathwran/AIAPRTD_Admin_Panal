import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TodayCompletePanel extends StatefulWidget {
  final VoidCallback onBack;
  const TodayCompletePanel({super.key, required this.onBack});

  @override
  State<TodayCompletePanel> createState() => _TodayCompletePanelState();
}

class _TodayCompletePanelState extends State<TodayCompletePanel> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // අද දවසේ මධ්‍යම රාත්‍රිය (Start of today) ගණනය කරලා අද දත්ත විතරක් ෆිල්ටර් කරන්න දානවා මචං
    final DateTime now = DateTime.now();
    final DateTime startOfToday = DateTime(now.year, now.month, now.day);

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
                      "Today's Completed Jobs",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    SizedBox(height: 4),
                    Text('Summary breakdown of successfully finished collections today', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                hintText: 'Search completed jobs by Driver or Route...',
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
            // 📊 SECTION 3: REAL-TIME COMPLETED TRIPS STREAM
            // ==========================================================
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('trips')
                    .where('status', isEqualTo: 'completed')
                    .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.teal));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading completed jobs: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }

                  final tripDocs = snapshot.data?.docs ?? [];

                  final filteredTrips = tripDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final driverName = (data['driverName'] ?? '').toString().toLowerCase();
                    final pickup = (data['pickupAddress'] ?? '').toString().toLowerCase();
                    final drop = (data['dropAddress'] ?? '').toString().toLowerCase();
                    final query = _searchQuery.toLowerCase();
                    return driverName.contains(query) || pickup.contains(query) || drop.contains(query);
                  }).toList();

                  if (filteredTrips.isEmpty) {
                    return const Center(
                      child: Text('No jobs have been completed yet today.', style: TextStyle(color: Colors.grey, fontSize: 16)),
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
                            constraints: const BoxConstraints(minWidth: 1000),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(Colors.teal.withValues(alpha: 0.02)),
                              dataRowMinHeight: 60,
                              dataRowMaxHeight: 60,
                              columns: const [
                                DataColumn(label: Text('Driver Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
                                DataColumn(label: Text('Route Matrix', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
                                DataColumn(label: Text('Time Finished', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
                                DataColumn(label: Text('Final Fare', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
                                DataColumn(label: Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
                                DataColumn(label: Text('Matrix Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))),
                              ],
                              rows: filteredTrips.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;

                                String formattedTime = 'Just Now';
                                if (data['timestamp'] != null) {
                                  final Timestamp t = data['timestamp'];
                                  formattedTime = DateFormat('hh:mm a').format(t.toDate());
                                }

                                return DataRow(cells: [
                                  DataCell(Text(data['driverName'] ?? 'Unknown Driver', style: const TextStyle(fontWeight: FontWeight.w600))),
                                  DataCell(Text('${data['pickupAddress'] ?? 'A'} ➔ ${data['dropAddress'] ?? 'B'}', maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  DataCell(Text(formattedTime)),
                                  DataCell(Text('LKR ${data['finalFare'] ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                                  DataCell(Text((data['paymentMethod'] ?? 'Cash').toString().toUpperCase())),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        "SUCCESS",
                                        style: TextStyle(color: Colors.teal, fontSize: 10, fontWeight: FontWeight.bold),
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