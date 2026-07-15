import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aiaprtd_admin_dashboard/core/providers/member_provider.dart';
import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';
import 'package:aiaprtd_admin_dashboard/core/widgets/modern_stat_card.dart';

class DashboardStatsGrid extends StatelessWidget {
  final Function(String pageTitle) onCardTap;

  const DashboardStatsGrid({super.key, required this.onCardTap});

  @override
  Widget build(BuildContext context) {
    final memberProvider = Provider.of<MemberProvider>(context);
    final allMembers = memberProvider.allMembersList;

    final totalMembersCount = allMembers.length;
    final activeMembersCount = allMembers.where((d) {
      return d['status'] == 'active' ||
          d['kycApprovalStatus'] == 'approved' ||
          d['adminApproval'] == 'Approved' ||
          d['isApproved'] == true;
    }).length;
    final onlineMembersCount = allMembers
        .where((d) => d['isOnline'] == true || d['onlineStatus'] == 'online')
        .length;
    final offlineMembersCount = allMembers.where((d) {
      final isOnline = d['isOnline'] == true || d['onlineStatus'] == 'online';
      return !isOnline;
    }).length;
    final inactiveMembersCount = allMembers.where((d) {
      return d['status'] != 'active' &&
          d['kycApprovalStatus'] != 'approved' &&
          d['adminApproval'] != 'Approved' &&
          d['isApproved'] != true;
    }).length;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 5;
        if (constraints.maxWidth < 1100) crossAxisCount = 4;
        if (constraints.maxWidth < 800) crossAxisCount = 2;
        if (constraints.maxWidth < 500) crossAxisCount = 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
          children: [
            InkWell(
              onTap: () => onCardTap('Total Members List'),
              child: ModernStatCard(
                title: 'Total Members',
                value: totalMembersCount.toString(),
                icon: Icons.people_alt_rounded,
                iconColor: AdminColors.primary,
                bottomWidget: _buildTrend('Registered fleet'),
              ),
            ),
            InkWell(
              onTap: () => onCardTap('Drivers Overview'),
              child: ModernStatCard(
                title: 'Active Members',
                value: activeMembersCount.toString(),
                icon: Icons.verified_rounded,
                iconColor: AdminColors.success,
                bottomWidget: _buildTrend('Approved drivers'),
              ),
            ),
            InkWell(
              onTap: () => onCardTap('Drivers Overview'),
              child: ModernStatCard(
                title: 'Online Members',
                value: onlineMembersCount.toString(),
                icon: Icons.sensors_rounded,
                iconColor: AdminColors.driver,
                bottomWidget: _buildTrend('Live right now'),
              ),
            ),
            InkWell(
              onTap: () => onCardTap('Drivers Overview'),
              child: ModernStatCard(
                title: 'Offline Members',
                value: offlineMembersCount.toString(),
                icon: Icons.cloud_off_rounded,
                iconColor: AdminColors.muted,
                bottomWidget: _buildTrend('Not active right now'),
              ),
            ),
            InkWell(
              onTap: () => onCardTap('Drivers Overview'),
              child: ModernStatCard(
                title: 'Inactive Members',
                value: inactiveMembersCount.toString(),
                icon: Icons.person_off_rounded,
                iconColor: AdminColors.danger,
                bottomWidget: _buildTrend('Suspended/Pending'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrend(String label) {
    return Text(
      label,
      style: AdminText.body.copyWith(fontSize: 12),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
