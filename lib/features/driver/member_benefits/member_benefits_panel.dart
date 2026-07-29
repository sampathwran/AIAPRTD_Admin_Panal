import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/member_benefits/add_edit_benefit_dialog.dart';

class MemberBenefitsPanel extends StatefulWidget {
  const MemberBenefitsPanel({super.key});

  @override
  State<MemberBenefitsPanel> createState() => _MemberBenefitsPanelState();
}

class _MemberBenefitsPanelState extends State<MemberBenefitsPanel> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showAddEditDialog([DocumentSnapshot? doc]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddEditBenefitDialog(benefitDoc: doc),
    );
  }

  void _deleteBenefit(String docId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Benefit'),
        content: const Text(
          'Are you sure you want to delete this member benefit?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('member_benefits').doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Benefit deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting benefit: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminColors.canvas,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Member Benefits Management',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AdminColors.ink,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add New Benefit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AdminColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminColors.line),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('member_benefits')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No benefits found. Create one to get started.',
                        style: TextStyle(color: AdminColors.muted),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: AdminColors.line),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final title = data['title'] ?? 'N/A';
                      final desc = data['description'] ?? 'N/A';
                      final iconName = data['icon'] ?? 'star';
                      final isGlobal = data['isGlobal'] ?? false;

                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AdminColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.card_giftcard_rounded,
                            color: AdminColors.primary,
                          ),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AdminColors.ink,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              style: const TextStyle(color: AdminColors.muted),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isGlobal
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isGlobal
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                  child: Text(
                                    isGlobal ? 'Global' : 'Targeted',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isGlobal
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Icon: $iconName',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AdminColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Edit',
                              onPressed: () => _showAddEditDialog(doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete',
                              onPressed: () => _deleteBenefit(doc.id),
                            ),
                          ],
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
