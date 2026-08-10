import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PoliceTrafficManagementPage extends StatefulWidget {
  const PoliceTrafficManagementPage({super.key});

  @override
  State<PoliceTrafficManagementPage> createState() => _PoliceTrafficManagementPageState();
}

class _PoliceTrafficManagementPageState extends State<PoliceTrafficManagementPage> {
  final Map<String, String> _typeLabels = {
    'traffic_police': 'Traffic Police',
    'police_barrier': 'Police Barrier',
    'high_speed': 'High Speed',
  };

  final Map<String, Color> _typeColors = {
    'traffic_police': Colors.blue,
    'police_barrier': Colors.orange,
    'high_speed': Colors.red,
  };

  Future<void> _deleteReport(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('traffic_reports').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report deleted.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Police & Traffic Updates'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('traffic_reports').orderBy('reportedAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No reports found.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final type = data['type'] ?? 'unknown';
              final label = _typeLabels[type] ?? type;
              final color = _typeColors[type] ?? Colors.grey;
              
              final isActive = data['isActive'] ?? false;
              final confirmations = data['confirmations'] ?? 0;
              final denials = data['denials'] ?? 0;
              final lat = data['latitude'];
              final lng = data['longitude'];

              DateTime? reportedAt;
              if (data['reportedAt'] != null) {
                reportedAt = (data['reportedAt'] as Timestamp).toDate();
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(Icons.local_police, color: color),
                  ),
                  title: Row(
                    children: [
                      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      if (!isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                          child: const Text('Hidden', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Reported: ${reportedAt != null ? DateFormat('MMM d, h:mm a').format(reportedAt) : 'Unknown'}'),
                      Text('Location: $lat, $lng'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.thumb_up, size: 14, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Text('$confirmations'),
                          const SizedBox(width: 16),
                          Icon(Icons.thumb_down, size: 14, color: Colors.red[700]),
                          const SizedBox(width: 4),
                          Text('$denials'),
                        ],
                      )
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteReport(doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
