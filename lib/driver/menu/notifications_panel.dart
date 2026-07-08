import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationsPanel extends StatefulWidget {
  const NotificationsPanel({super.key});

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _bodyCtrl = TextEditingController();
  final TextEditingController _memberIdCtrl = TextEditingController();

  String _targetType = 'all'; // 'all' or 'specific'
  bool _isScheduled = false;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  bool _isSending = false;

  void _sendNotification() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title and Body are required.")));
      return;
    }

    if (_targetType == 'specific' && _memberIdCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Member ID is required for specific target.")));
      return;
    }

    DateTime? scheduledAt;
    if (_isScheduled) {
      if (_scheduledDate == null || _scheduledTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a valid date and time.")));
        return;
      }
      scheduledAt = DateTime(
        _scheduledDate!.year,
        _scheduledDate!.month,
        _scheduledDate!.day,
        _scheduledTime!.hour,
        _scheduledTime!.minute,
      );
    }

    setState(() => _isSending = true);

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'targetType': _targetType,
        'targetMembers': _targetType == 'specific' ? [_memberIdCtrl.text.trim()] : [],
        'scheduledAt': scheduledAt != null ? Timestamp.fromDate(scheduledAt) : null,
        'createdAt': FieldValue.serverTimestamp(),
        'readBy': [],
      });

      _titleCtrl.clear();
      _bodyCtrl.clear();
      _memberIdCtrl.clear();
      setState(() {
        _isScheduled = false;
        _scheduledDate = null;
        _scheduledTime = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notification successfully queued!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to send: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _scheduledTime = picked);
  }

  void _deleteNotification(String id) {
    FirebaseFirestore.instance.collection('notifications').doc(id).delete();
  }

  void _showNotificationDetails(String title, String body, String target, String timeText, bool isPending) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(isPending ? Icons.schedule : Icons.check_circle, color: isPending ? Colors.orange : Colors.green),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          content: SizedBox(
            width: 600, // Make the box larger
            child: SingleChildScrollView(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(body, style: const TextStyle(fontSize: 16, height: 1.5)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.people, size: 18, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Expanded(child: Text("Target: $target", style: const TextStyle(fontWeight: FontWeight.w600))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(timeText, style: const TextStyle(color: Colors.blueGrey))),
                  ],
                ),
              ],
            ),
          ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Close", style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Notification Center", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          // Composer Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Compose Message", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: "Notification Title", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _bodyCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: "Notification Body", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  
                  // Target Selection
                  Row(
                    children: [
                      const Text("Target: "),
                      Radio(value: 'all', groupValue: _targetType, onChanged: (v) => setState(() => _targetType = v.toString())),
                      const Text("All Members"),
                      const SizedBox(width: 24),
                      Radio(value: 'specific', groupValue: _targetType, onChanged: (v) => setState(() => _targetType = v.toString())),
                      const Text("Specific Member"),
                    ],
                  ),
                  if (_targetType == 'specific')
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: TextField(
                        controller: _memberIdCtrl,
                        decoration: const InputDecoration(
                          labelText: "Enter Member ID",
                          border: OutlineInputBorder(),
                          hintText: "e.g. M12345",
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Schedule Selection
                  Row(
                    children: [
                      Checkbox(
                        value: _isScheduled,
                        onChanged: (v) => setState(() => _isScheduled = v ?? false),
                      ),
                      const Text("Schedule for later"),
                    ],
                  ),
                  if (_isScheduled)
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(_scheduledDate == null ? "Pick Date" : DateFormat('yyyy-MM-dd').format(_scheduledDate!)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.access_time),
                          label: Text(_scheduledTime == null ? "Pick Time" : _scheduledTime!.format(context)),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendNotification,
                      icon: _isSending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
                      label: Text(_isSending ? "Sending..." : "Send Notification"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
          const Text("Notification History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('notifications').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text("Error: ${snapshot.error}");
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Text("No notifications sent yet.");

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final title = data['title'] ?? '';
                  final body = data['body'] ?? '';
                  final target = data['targetType'] == 'all' ? 'All Members' : 'Member: ${(data['targetMembers'] as List).join(', ')}';
                  final scheduledAt = data['scheduledAt'] as Timestamp?;
                  final createdAt = data['createdAt'] as Timestamp?;
                  final timeText = scheduledAt != null 
                      ? "Scheduled: ${DateFormat('MMM dd, yyyy HH:mm').format(scheduledAt.toDate())}"
                      : "Sent: ${createdAt != null ? DateFormat('MMM dd, yyyy HH:mm').format(createdAt.toDate()) : 'Now'}";
                  
                  final isPending = scheduledAt != null && scheduledAt.toDate().isAfter(DateTime.now());

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      onTap: () => _showNotificationDetails(title, body, target, timeText, isPending),
                      leading: CircleAvatar(
                        backgroundColor: isPending ? Colors.orange.shade100 : Colors.green.shade100,
                        child: Icon(isPending ? Icons.schedule : Icons.check_circle, color: isPending ? Colors.orange : Colors.green),
                      ),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                child: Text(target, style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                              ),
                              const SizedBox(width: 8),
                              Text(timeText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          )
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteNotification(docs[index].id),
                        tooltip: "Delete Notification",
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}