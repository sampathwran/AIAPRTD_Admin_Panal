import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SupportTicketsPanel extends StatefulWidget {
  const SupportTicketsPanel({super.key});

  @override
  State<SupportTicketsPanel> createState() => _SupportTicketsPanelState();
}

class _SupportTicketsPanelState extends State<SupportTicketsPanel> {
  String _statusFilter = 'All';

  Future<void> _generatePdf(
    Map<String, dynamic> ticketData,
    String docId,
  ) async {
    final pdf = pw.Document();

    final ticketId = ticketData['ticketId'] ?? docId;
    final memberName = ticketData['memberName'] ?? 'Unknown Member';
    final memberNo = ticketData['membershipNo'] ?? 'Unknown Member No';
    final memberPhone = ticketData['memberPhone'] ?? 'Unknown Phone';
    final title = ticketData['title'] ?? 'No Title';
    final description = ticketData['description'] ?? 'No Description';
    final status = ticketData['status'] ?? 'Pending';
    final createdAt = ticketData['createdAt'] != null
        ? DateFormat(
            'yyyy-MM-dd HH:mm',
          ).format((ticketData['createdAt'] as Timestamp).toDate())
        : 'Unknown Date';

    final List<dynamic> replies = ticketData['adminReplies'] ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              text: 'Support Ticket Report',
              textStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 24,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Ticket ID: $ticketId',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Status: $status',
                  style: pw.TextStyle(
                    color: status == 'Resolved'
                        ? PdfColors.green
                        : PdfColors.red,
                  ),
                ),
              ],
            ),
            pw.Text('Created: $createdAt'),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text(
              'Member Details',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
            ),
            pw.Text('Name: $memberName'),
            pw.Text('Membership No: $memberNo'),
            pw.Text('Phone: $memberPhone'),
            pw.SizedBox(height: 20),
            pw.Text(
              'Complaint / Issue',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
            ),
            pw.Text(
              'Title: $title',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(description),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Text(
              'Updates & Replies',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
            ),
            pw.SizedBox(height: 10),
            ...replies.map((r) {
              final rDate = r['timestamp'] != null
                  ? DateFormat(
                      'yyyy-MM-dd HH:mm',
                    ).format((r['timestamp'] as Timestamp).toDate())
                  : '';
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${r['adminName'] ?? 'Admin'} - $rDate',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(r['message'] ?? ''),
                  ],
                ),
              );
            }),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'ticket_$ticketId.pdf',
    );
  }

  void _showTicketDetails(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final replyCtrl = TextEditingController();
    String currentStatus = data['status'] ?? 'Pending';
    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final replies = data['adminReplies'] as List<dynamic>? ?? [];

            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Ticket: ${data['ticketId'] ?? doc.id}"),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    tooltip: "Download PDF",
                    onPressed: () => _generatePdf(data, doc.id),
                  ),
                ],
              ),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              "Member: ${data['memberName'] ?? 'Unknown'}\nMem. No: ${data['membershipNo'] ?? 'N/A'}\nPhone: ${data['memberPhone'] ?? ''}",
                            ),
                          ),
                          DropdownButton<String>(
                            value: currentStatus,
                            items:
                                ['Pending', 'In Progress', 'Resolved', 'Closed']
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              if (val != null)
                                setState(() => currentStatus = val);
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      Text(
                        data['title'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(data['description'] ?? ''),
                      const Divider(height: 30),
                      const Text(
                        "Updates & Replies",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...replies.map((r) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${r['adminName'] ?? 'Admin'} • ${r['timestamp'] != null ? DateFormat('MMM dd, hh:mm a').format((r['timestamp'] as Timestamp).toDate()) : ''}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(r['message'] ?? ''),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      TextField(
                        controller: replyCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: "Add a reply or update...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isUpdating
                      ? null
                      : () async {
                          setState(() {
                            isUpdating = true;
                          });

                          final newReplies = List.from(replies);
                          if (replyCtrl.text.trim().isNotEmpty) {
                            newReplies.add({
                              'adminName':
                                  'Admin', // In a real app, use the logged-in admin's name
                              'message': replyCtrl.text.trim(),
                              'timestamp': Timestamp.now(),
                            });
                          }

                          await FirebaseFirestore.instance
                              .collection('support_tickets')
                              .doc(doc.id)
                              .update({
                                'status': currentStatus,
                                'adminReplies': newReplies,
                                'updatedAt': FieldValue.serverTimestamp(),
                              });

                          if (context.mounted) Navigator.pop(context);
                        },
                  child: isUpdating
                      ? const CircularProgressIndicator()
                      : const Text("Update Ticket"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '🛠️ Support Tickets',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const TabBar(
                  isScrollable: true,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  tabs: [
                    Tab(text: 'All'),
                    Tab(text: 'Pending'),
                    Tab(text: 'In Progress'),
                    Tab(text: 'Resolved'),
                    Tab(text: 'Closed'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: ['All', 'Pending', 'In Progress', 'Resolved', 'Closed'].map((
                filterStatus,
              ) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('support_tickets')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError)
                      return Center(child: Text('Error: ${snapshot.error}'));

                    var docs = snapshot.data?.docs ?? [];
                    if (filterStatus != 'All') {
                      docs = docs
                          .where(
                            (d) =>
                                (d.data() as Map<String, dynamic>)['status'] ==
                                filterStatus,
                          )
                          .toList();
                    }

                    if (docs.isEmpty)
                      return Center(
                        child: Text("No $filterStatus tickets found."),
                      );

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'] ?? 'Pending';
                        final date = data['createdAt'] != null
                            ? DateFormat('MMM dd, hh:mm a').format(
                                (data['createdAt'] as Timestamp).toDate(),
                              )
                            : '';

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            onTap: () => _showTicketDetails(context, doc),
                            leading: CircleAvatar(
                              backgroundColor: status == 'Resolved'
                                  ? Colors.green
                                  : (status == 'Pending'
                                        ? Colors.red
                                        : Colors.orange),
                              child: const Icon(
                                Icons.receipt_long,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              "${data['ticketId'] ?? doc.id} - ${data['title'] ?? ''}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "Member: ${data['memberName'] ?? ''} (${data['membershipNo'] ?? 'N/A'}) • $date",
                            ),
                            trailing: Chip(
                              label: Text(
                                status,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
