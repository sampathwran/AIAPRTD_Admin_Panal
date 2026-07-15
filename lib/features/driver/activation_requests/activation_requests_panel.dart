// ignore_for_file: spell_check_on_languages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/activation_requests/bank_account_details_change.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/activation_requests/kyc_verification_requests.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/activation_requests/profile_image_requests.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/activation_requests/profile_update_requests.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/activation_requests/vehicle_change_requests.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/activation_requests/activation_history_screen.dart';

class ActivationRequestsPanel extends StatelessWidget {
  const ActivationRequestsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final profileStream = FirebaseFirestore.instance
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .where('requestType', isEqualTo: 'profile_update')
        .snapshots();
    final vehicleStream = FirebaseFirestore.instance
        .collection('vehicles')
        .where('status', isEqualTo: 'pending')
        .snapshots();
    final kycStream = FirebaseFirestore.instance
        .collection('verify_kyc')
        .where('kycApprovalStatus', isEqualTo: 'pending')
        .snapshots();
    final bankStream = FirebaseFirestore.instance
        .collection('verify_bank')
        .where('status', isEqualTo: 'pending')
        .snapshots();
    final imageStream = FirebaseFirestore.instance
        .collection('profile_image_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    final combinedStream = CombineLatestStream.list<QuerySnapshot>([
      profileStream,
      vehicleStream,
      kycStream,
      bankStream,
      imageStream,
    ]);

    return StreamBuilder<List<QuerySnapshot>>(
      stream: combinedStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ColoredBox(
            color: AdminColors.canvas,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          );
        }

        if (snapshot.hasError) {
          return ColoredBox(
            color: AdminColors.canvas,
            child: Center(
              child: AdminSurface(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Activation request data failed to load: ${snapshot.error}',
                  style: const TextStyle(color: AdminColors.danger),
                ),
              ),
            ),
          );
        }

        final docs = snapshot.data ?? const <QuerySnapshot>[];
        final categories = [
          _RequestCategory(
            title: 'Profile Detail Updates',
            subtitle: 'Name, contact, and personal profile changes',
            icon: Icons.manage_accounts_rounded,
            count: docs.isEmpty ? 0 : docs[0].docs.length,
            color: AdminColors.primary,
            page: const ProfileUpdateRequests(),
          ),
          _RequestCategory(
            title: 'Profile Image Approvals',
            subtitle: 'New profile photo review queue',
            icon: Icons.account_circle_rounded,
            count: docs.length < 5 ? 0 : docs[4].docs.length,
            color: const Color(0xFF4F46E5),
            page: const ProfileImageRequests(),
          ),
          _RequestCategory(
            title: 'Vehicle Change Requests',
            subtitle: 'Vehicle data, plate, and category updates',
            icon: Icons.published_with_changes_rounded,
            count: docs.length < 2 ? 0 : docs[1].docs.length,
            color: AdminColors.warning,
            page: const VehicleChangeRequests(),
          ),
          _RequestCategory(
            title: 'KYC Profile Verifications',
            subtitle: 'Identity and compliance checks',
            icon: Icons.gpp_good_rounded,
            count: docs.length < 3 ? 0 : docs[2].docs.length,
            color: AdminColors.purple,
            page: const KYCVerificationRequests(),
          ),
          _RequestCategory(
            title: 'Bank Account Updates',
            subtitle: 'Payment account verification requests',
            icon: Icons.account_balance_rounded,
            count: docs.length < 4 ? 0 : docs[3].docs.length,
            color: AdminColors.passenger,
            page: const BankAccountDetailsChangeRequests(),
          ),
        ];
        final totalPending = categories.fold<int>(
          0,
          (runningTotal, item) => runningTotal + item.count,
        );
        final activeQueues = categories.where((item) => item.count > 0).length;

        return AdminPageScaffold(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminSectionHeader(
                title: 'Activation review queue',
                subtitle:
                    'Prioritize pending account, document, vehicle, and payment changes from one structured workflow.',
                icon: Icons.fact_check_rounded,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.history_rounded, color: AdminColors.primary),
                      tooltip: "View History",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ActivationHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    AdminStatusPill(
                      label: totalPending == 0
                          ? 'ALL CLEAR'
                          : '$totalPending PENDING',
                      icon: totalPending == 0
                          ? Icons.check_circle_rounded
                          : Icons.priority_high_rounded,
                      color: totalPending == 0
                          ? AdminColors.success
                          : AdminColors.danger,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _ReviewSummary(
                totalPending: totalPending,
                activeQueues: activeQueues,
                clearedQueues: categories.length - activeQueues,
              ),
              const SizedBox(height: 18),
              const Text('REQUEST CATEGORIES', style: AdminText.overline),
              const SizedBox(height: 10),
              _RequestCategoryGrid(categories: categories),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewSummary extends StatelessWidget {
  final int totalPending;
  final int activeQueues;
  final int clearedQueues;

  const _ReviewSummary({
    required this.totalPending,
    required this.activeQueues,
    required this.clearedQueues,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final cards = [
          _SummaryTile(
            label: 'Total pending',
            value: totalPending.toString(),
            icon: Icons.pending_actions_rounded,
            color: totalPending == 0 ? AdminColors.success : AdminColors.danger,
          ),
          _SummaryTile(
            label: 'Active queues',
            value: activeQueues.toString(),
            icon: Icons.view_kanban_rounded,
            color: AdminColors.primary,
          ),
          _SummaryTile(
            label: 'Cleared queues',
            value: clearedQueues.toString(),
            icon: Icons.checklist_rounded,
            color: AdminColors.success,
          ),
        ];

        if (compact) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children:
              cards
                  .expand(
                    (card) => [
                      Expanded(child: card),
                      const SizedBox(width: 14),
                    ],
                  )
                  .toList()
                ..removeLast(),
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      elevated: true,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AdminText.body),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCategoryGrid extends StatelessWidget {
  final List<_RequestCategory> categories;

  const _RequestCategoryGrid({required this.categories});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final count = width > 1180 ? 3 : (width > 740 ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: count,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 138,
          ),
          itemBuilder: (context, index) {
            final item = categories[index];
            return _RequestCategoryCard(item: item, index: index + 1);
          },
        );
      },
    );
  }
}

class _RequestCategoryCard extends StatelessWidget {
  final _RequestCategory item;
  final int index;

  const _RequestCategoryCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final actionNeeded = item.count > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => item.page),
        ),
        child: AdminSurface(
          elevated: true,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    index.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      color: AdminColors.faint,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, color: item.color, size: 23),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AdminText.body,
                    ),
                    const SizedBox(height: 12),
                    AdminStatusPill(
                      label: actionNeeded
                          ? '${item.count} NEED REVIEW'
                          : 'NO PENDING ITEMS',
                      icon: actionNeeded
                          ? Icons.schedule_rounded
                          : Icons.check_rounded,
                      color: actionNeeded
                          ? AdminColors.danger
                          : AdminColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AdminColors.faint,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCategory {
  final String title;
  final String subtitle;
  final IconData icon;
  final int count;
  final Color color;
  final Widget page;

  const _RequestCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.count,
    required this.color,
    required this.page,
  });
}
