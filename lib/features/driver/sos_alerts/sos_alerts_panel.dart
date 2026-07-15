import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/sos_alerts/sos_alert_details_dialog.dart';

class SosAlertsPanel extends StatelessWidget {
  const SosAlertsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminColors.canvas,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SOS Emergencies',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AdminColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track and manage driver emergency alerts in real-time.',
            style: TextStyle(color: AdminColors.muted),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: AdminSurface(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sos_alerts')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading alerts'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('No SOS alerts found.', style: TextStyle(color: AdminColors.muted)),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => const Divider(height: 32, color: AdminColors.line),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final isActive = data['status'] == 'active';

                      String dateString = 'N/A';
                      if (data['createdAt'] != null) {
                        final timestamp = data['createdAt'] as Timestamp;
                        dateString = DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp.toDate());
                      }

                      return InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => SosAlertDetailsDialog(alertData: data),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isActive ? AdminColors.danger.withValues(alpha: 0.05) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isActive ? AdminColors.danger.withValues(alpha: 0.3) : Colors.transparent,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isActive 
                                      ? AdminColors.danger.withValues(alpha: 0.1) 
                                      : AdminColors.surfaceAlt,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.emergency_share_rounded,
                                  color: isActive ? AdminColors.danger : AdminColors.muted,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          data['memberName'] ?? 'Unknown Member',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AdminColors.ink,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        AdminStatusPill(
                                          label: isActive ? 'ACTIVE SOS' : 'RESOLVED',
                                          color: isActive ? AdminColors.danger : AdminColors.success,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Member ID: ${data['memberId']} • Phone: ${data['memberPhone']}',
                                      style: const TextStyle(color: AdminColors.faint, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    dateString,
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: AdminColors.inkSoft),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Responders: ${(data['responders'] as List?)?.length ?? 0}',
                                    style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.chevron_right_rounded, color: AdminColors.muted),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
