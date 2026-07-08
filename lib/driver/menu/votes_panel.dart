import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class VotesPanel extends StatefulWidget {
  const VotesPanel({super.key});

  @override
  State<VotesPanel> createState() => _VotesPanelState();
}

class _VotesPanelState extends State<VotesPanel> {
  int _totalMembersCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchTotalMembers();
  }

  Future<void> _fetchTotalMembers() async {
    try {
      final countQuery = await FirebaseFirestore.instance.collection('members').count().get();
      setState(() {
        _totalMembersCount = countQuery.count ?? 0;
      });
    } catch (e) {
      debugPrint("Error fetching total members: $e");
    }
  }

  void _showCreatePollDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    List<TextEditingController> optionCtrls = [TextEditingController(), TextEditingController()];
    DateTime? selectedExpiry;
    bool allowComments = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Create New Poll"),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Poll Title", border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
                      const SizedBox(height: 20),
                      const Text("Options", style: TextStyle(fontWeight: FontWeight.bold)),
                      ...List.generate(optionCtrls.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Expanded(child: TextField(controller: optionCtrls[index], decoration: InputDecoration(labelText: "Option ${index + 1}", border: const OutlineInputBorder()))),
                              if (optionCtrls.length > 2)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => setState(() => optionCtrls.removeAt(index)),
                                )
                            ],
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed: () => setState(() => optionCtrls.add(TextEditingController())),
                        icon: const Icon(Icons.add),
                        label: const Text("Add Option"),
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Expiration Date & Time"),
                        subtitle: Text(selectedExpiry == null ? "Not set" : DateFormat('yyyy-MM-dd hh:mm a').format(selectedExpiry!)),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                            if (date != null && context.mounted) {
                              final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                              if (time != null) {
                                setState(() {
                                  selectedExpiry = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                });
                              }
                            }
                          },
                          child: const Text("Select"),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text("Allow Member Comments"),
                        value: allowComments,
                        onChanged: (val) => setState(() => allowComments = val),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (titleCtrl.text.trim().isEmpty || selectedExpiry == null) return;
                          final validOptions = optionCtrls.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
                          if (validOptions.length < 2) return; // Need at least 2 options

                          setState(() => isSubmitting = true);

                          await FirebaseFirestore.instance.collection('polls').add({
                            'title': titleCtrl.text.trim(),
                            'description': descCtrl.text.trim(),
                            'options': validOptions,
                            'expiresAt': Timestamp.fromDate(selectedExpiry!),
                            'allowComments': allowComments,
                            'createdAt': FieldValue.serverTimestamp(),
                            'votes': {}, // map of docId -> {optionIndex, name, memberNo, phone}
                            'comments': [],
                          });

                          if (context.mounted) Navigator.pop(context);
                        },
                  child: isSubmitting ? const CircularProgressIndicator() : const Text("Create Poll"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _generatePollPdf(Map<String, dynamic> data, String docId, List<int> optionCounts, double overallParticipation, int totalVotes) async {
    final pdf = pw.Document();
    
    final title = data['title'] ?? 'No Title';
    final description = data['description'] ?? '';
    final options = List<String>.from(data['options'] ?? []);
    final votesMap = Map<String, dynamic>.from(data['votes'] ?? {});
    final comments = List<dynamic>.from(data['comments'] ?? []);
    final expiresAt = data['expiresAt'] as Timestamp?;
    final dateStr = expiresAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(expiresAt.toDate()) : 'Never';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(level: 0, text: 'Poll Summary Report', textStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24)),
            pw.SizedBox(height: 10),
            pw.Text('Poll: $title', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
            if (description.isNotEmpty) pw.Text(description, style: const pw.TextStyle(color: PdfColors.grey700)),
            pw.Text('Expires: $dateStr'),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text("Total Participation: $totalVotes votes (${overallParticipation.toStringAsFixed(1)}% of $_totalMembersCount members)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
            pw.SizedBox(height: 20),
            pw.Text("Results", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
            pw.SizedBox(height: 10),
            ...List.generate(options.length, (index) {
              int count = optionCounts[index];
              double pct = totalVotes > 0 ? (count / totalVotes) : 0.0;
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(options[index], style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text("$count votes (${(pct * 100).toStringAsFixed(1)}%)"),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Text("Voter Details", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
            pw.SizedBox(height: 10),
            if (votesMap.isEmpty) pw.Text("No votes yet.", style: const pw.TextStyle(color: PdfColors.grey))
            else ...votesMap.entries.map((entry) {
              final voteData = entry.value;
              String selectedOption = options[voteData['optionIndex']];
              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Text("- ${voteData['name']} (${voteData['memberNo']}) [Phone: ${voteData['phone']}] voted for: $selectedOption", style: const pw.TextStyle(fontSize: 10)),
              );
            }),
            if (data['allowComments'] == true && comments.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text("Member Comments", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.SizedBox(height: 10),
              ...comments.map((c) {
                final cDate = c['timestamp'] != null ? DateFormat('yyyy-MM-dd HH:mm').format((c['timestamp'] as Timestamp).toDate()) : '';
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("${c['name']} - $cDate", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text(c['text'] ?? '', style: const pw.TextStyle(fontSize: 10)),
                    ]
                  )
                );
              }),
            ]
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'poll_summary_$docId.pdf',
    );
  }

  void _showPollDetails(Map<String, dynamic> data, String docId) {
    final options = List<String>.from(data['options'] ?? []);
    final votesMap = Map<String, dynamic>.from(data['votes'] ?? {});
    final comments = List<dynamic>.from(data['comments'] ?? []);
    final int totalVotes = votesMap.length;
    
    // Calculate option counts
    List<int> optionCounts = List.filled(options.length, 0);
    votesMap.forEach((key, val) {
      int optIdx = val['optionIndex'];
      if (optIdx >= 0 && optIdx < options.length) {
        optionCounts[optIdx]++;
      }
    });

    double overallParticipation = _totalMembersCount > 0 ? (totalVotes / _totalMembersCount) * 100 : 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(data['title'] ?? 'Poll Details')),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                tooltip: "Download Summary as PDF",
                onPressed: () => _generatePollPdf(data, docId, optionCounts, overallParticipation, totalVotes),
              ),
            ],
          ),
          content: SizedBox(
            width: 700,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['description'] ?? '', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  Text("Total Participation: $totalVotes votes (${overallParticipation.toStringAsFixed(1)}% of $_totalMembersCount members)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 20),
                  const Text("Results", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  ...List.generate(options.length, (index) {
                    int count = optionCounts[index];
                    double pct = totalVotes > 0 ? (count / totalVotes) : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(options[index], style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text("$count votes (${(pct * 100).toStringAsFixed(1)}%)"),
                            ],
                          ),
                          const SizedBox(height: 5),
                          LinearProgressIndicator(value: pct, backgroundColor: Colors.grey.shade200, color: Colors.blue, minHeight: 8),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 40),
                  const Text("Voter Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 10),
                  if (votesMap.isEmpty) const Text("No votes yet.", style: TextStyle(color: Colors.grey))
                  else ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: votesMap.length,
                    itemBuilder: (context, index) {
                      String memberId = votesMap.keys.elementAt(index);
                      var voteData = votesMap[memberId];
                      String selectedOption = options[voteData['optionIndex']];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text("${voteData['name']} (${voteData['memberNo']})"),
                        subtitle: Text("Phone: ${voteData['phone']}\nVoted: $selectedOption"),
                        isThreeLine: true,
                      );
                    },
                  ),
                  if (data['allowComments'] == true) ...[
                    const Divider(height: 40),
                    const Text("Member Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 10),
                    if (comments.isEmpty) const Text("No comments yet.", style: TextStyle(color: Colors.grey))
                    else ...comments.map((c) {
                      final cDate = c['timestamp'] != null ? DateFormat('MMM dd, hh:mm a').format((c['timestamp'] as Timestamp).toDate()) : '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${c['name']} • $cDate", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(c['text'] ?? ''),
                          ],
                        ),
                      );
                    }),
                  ]
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => FirebaseFirestore.instance.collection('polls').doc(docId).delete().then((_) => Navigator.pop(context)),
              child: const Text("Delete Poll", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('🗳️ Voting & Polls', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: _showCreatePollDialog,
                icon: const Icon(Icons.add),
                label: const Text("Create Poll"),
              )
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('polls').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

              var docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) return const Center(child: Text("No polls created yet."));

              // Sort locally
              docs.sort((a, b) {
                final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final expiresAt = data['expiresAt'] as Timestamp?;
                  bool isExpired = expiresAt != null && expiresAt.toDate().isBefore(DateTime.now());
                  final votesCount = (data['votes'] as Map?)?.length ?? 0;

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: () => _showPollDetails(data, doc.id),
                      leading: CircleAvatar(
                        backgroundColor: isExpired ? Colors.grey : Colors.blue,
                        child: const Icon(Icons.how_to_vote, color: Colors.white),
                      ),
                      title: Text(data['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Votes: $votesCount • Expires: ${expiresAt != null ? DateFormat('MMM dd, hh:mm a').format(expiresAt.toDate()) : 'Never'}"),
                      trailing: Chip(
                        label: Text(isExpired ? "Closed" : "Active", style: TextStyle(color: isExpired ? Colors.grey : Colors.green, fontWeight: FontWeight.bold)),
                        backgroundColor: isExpired ? Colors.grey.shade200 : Colors.green.shade50,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }
}