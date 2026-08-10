import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/services_hub_management/sub_services/ev_charging/add_edit_ev_station_dialog.dart';

class EvChargingPanel extends StatefulWidget {
  const EvChargingPanel({super.key});

  @override
  State<EvChargingPanel> createState() => _EvChargingPanelState();
}

class _EvChargingPanelState extends State<EvChargingPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AddEditEvStationDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Add EV Station"),
      ),
      backgroundColor: AdminColors.canvas,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ev_charging_stations')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No EV Charging stations added yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              String status = data['status'] ?? 'Available';
              List<dynamic> chargerTypes = data['chargerTypes'] ?? [];
              double powerKw = (data['powerKw'] ?? 0).toDouble();
              
              int totalChargers = 1;
              if (data['chargers'] != null) {
                 final chargersList = (data['chargers'] as List);
                 totalChargers = chargersList.length;
                 if (chargersList.isNotEmpty) {
                    status = chargersList.first['status'] ?? 'Available';
                    chargerTypes = chargersList.map((c) => c['type']).toSet().toList();
                    powerKw = (chargersList.first['powerKw'] ?? 0).toDouble();
                 }
              }

              Color statusColor = Colors.green;
              if (status == 'In Use') statusColor = Colors.orange;
              if (status == 'Offline' || status == 'Maintenance' || status == 'Broken') statusColor = Colors.red;

              String imageUrl = data['imageUrl'] ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover,
                            errorBuilder: (c,e,s) => _buildFallbackIcon(),
                          ),
                        )
                      : _buildFallbackIcon(),
                  title: Text(data['name'] ?? 'Unknown Station', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${data['provider']} | $totalChargers Point(s) | Rs.${data['pricePerKwh']}/kWh\nTypes: ${chargerTypes.join(', ')}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(status, style: TextStyle(color: statusColor, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => AddEditEvStationDialog(
                              station: doc, // Pass the entire DocumentSnapshot
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return CircleAvatar(
      backgroundColor: AdminColors.primary.withOpacity(0.1),
      child: const Icon(Icons.ev_station, color: AdminColors.primary),
    );
  }

  void _confirmDelete(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Station?'),
        content: const Text('Are you sure you want to delete this EV charging station?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('ev_charging_stations').doc(docId).delete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
