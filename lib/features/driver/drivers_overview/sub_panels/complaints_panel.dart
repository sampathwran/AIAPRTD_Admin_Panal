import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ComplaintsPanel extends StatefulWidget {
  final VoidCallback onBack;
  const ComplaintsPanel({super.key, required this.onBack});

  @override
  State<ComplaintsPanel> createState() => _ComplaintsPanelState();
}

class _ComplaintsPanelState extends State<ComplaintsPanel> {
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
                      'Complaints & Customer Support Tickets',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Open support tickets needing immediate review and action mediation',
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
                hintText:
                    'Search ticket entries by Driver ID, Rider or Subject...',
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

            // ==========================================================
            // 📊 SECTION 3: COMPLAINTS TICKETS STREAM
            // ==========================================================
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('complaints')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.redAccent),
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

                  final complaintDocs = snapshot.data?.docs ?? [];

                  final filteredTickets = complaintDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final driverId = (data['driverMembershipNo'] ?? '')
                        .toString()
                        .toLowerCase();
                    final rider = (data['passengerName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final title = (data['subject'] ?? '')
                        .toString()
                        .toLowerCase();
                    final query = _searchQuery.toLowerCase();
                    return driverId.contains(query) ||
                        rider.contains(query) ||
                        title.contains(query);
                  }).toList();

                  if (filteredTickets.isEmpty) {
                    return const Center(
                      child: Text(
                        'All clear! No pending customer support complaints.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    );
                  }

                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF000000,
                          ).withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
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
                              headingRowColor: WidgetStateProperty.all(
                                Colors.redAccent.withValues(alpha: 0.02),
                              ),
                              dataRowMinHeight: 65,
                              dataRowMaxHeight: 65,
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'Driver ID',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Passenger',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Complaint Subject',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Description',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Date Logged',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Mediation Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                              rows: filteredTickets.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final String status =
                                    data['status'] ?? 'pending';
                                final bool isPending =
                                    status.toLowerCase() == 'pending';

                                String dateText = 'N/A';
                                if (data['timestamp'] != null) {
                                  final Timestamp t = data['timestamp'];
                                  dateText = DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(t.toDate());
                                }

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        data['driverMembershipNo'] ?? '-',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        data['passengerName'] ??
                                            'Rider Profile',
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        data['subject'] ?? 'Service Issue',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 250,
                                        child: Text(
                                          data['description'] ?? '-',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(dateText)),
                                    // Ticket Resolution Status
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isPending
                                              ? Colors.red.withValues(
                                                  alpha: 0.1,
                                                )
                                              : Colors.green.withValues(
                                                  alpha: 0.1,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: isPending
                                                ? Colors.red
                                                : Colors.green,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
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
