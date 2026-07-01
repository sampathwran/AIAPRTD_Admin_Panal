import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/member_provider.dart';

class DashboardStatsGrid extends StatelessWidget {
  final Function(String pageTitle) onCardTap;

  const DashboardStatsGrid({super.key, required this.onCardTap});

  @override
  Widget build(BuildContext context) {
    // 💡 Provider එක හරහා Firebase එකෙන් එන සාමාජිකයින්ගේ මුළු ලිස්ට් එක මෙතනට ගන්නවා මචං
    final memberProvider = Provider.of<MemberProvider>(context);
    final allMembers = memberProvider.allMembersList;

    // =========================================================================
    // 📊 REALTIME COUNTS CALCULATION (ෆයර්බේස් එකෙන් එසැණින් ගණනය කරන කෑල්ල)
    // =========================================================================

    // 1. Total Members Count
    int totalMembersCount = allMembers.length;

    // 2. Active Members Count (status == 'active')
    int activeMembersCount = allMembers.where((d) => d['status'] == 'active').length;

    // 3. Online Members Count (isOnline == true හෝ onlineStatus == 'online')
    int onlineMembersCount = allMembers.where((d) {
      return d['isOnline'] == true || d['onlineStatus'] == 'online';
    }).length;

    // 4. Offline Members Count (Online නැති අය)
    int offlineMembersCount = allMembers.where((d) {
      final isOnline = d['isOnline'] == true || d['onlineStatus'] == 'online';
      return !isOnline;
    }).length;

    // 5. Inactive Members Count (status != 'active')
    int inactiveMembersCount = allMembers.where((d) => d['status'] != 'active').length;

    // =========================================================================
    // 📝 DYNAMIC STATS ITEMS LIST
    // =========================================================================
    final List<Map<String, dynamic>> statsItems = [
      {'title': 'Total Members', 'value': totalMembersCount.toString(), 'icon': Icons.people_alt_rounded, 'color': Colors.blue},
      {'title': 'Active Members', 'value': activeMembersCount.toString(), 'icon': Icons.gavel_rounded, 'color': Colors.indigo},
      {'title': 'Online Members', 'value': onlineMembersCount.toString(), 'icon': Icons.cloud_done_rounded, 'color': Colors.green},
      {'title': 'Offline Members', 'value': offlineMembersCount.toString(), 'icon': Icons.cloud_off_rounded, 'color': Colors.grey},
      {'title': 'Inactive Members', 'value': inactiveMembersCount.toString(), 'icon': Icons.person_off_rounded, 'color': Colors.orange},
      // 💡 Trips සහ complaints ටික ඔයාගේ අදාළ අනෙක් providers හදපු ගමන් මේ විදිහටම live කරගන්න පුළුවන් මචං
      {'title': 'Ongoing Trips', 'value': '45', 'icon': Icons.local_taxi_rounded, 'color': Colors.purple},
      {'title': 'Today Complete', 'value': '180', 'icon': Icons.check_circle_rounded, 'color': Colors.teal},
      {'title': 'Canceled Trips', 'value': '12', 'icon': Icons.cancel_rounded, 'color': Colors.red},
      {'title': 'Complaints', 'value': '3', 'icon': Icons.assignment_late_rounded, 'color': Colors.redAccent},
    ];

    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 1400 ? 5 : (screenWidth > 1100 ? 4 : 3);

    // 💡 සාමාජික දත්ත බාගත වෙමින් පවතිනවා නම් පොඩි ලස්සන loading indicator එකක් දෙනවා (Layout එක කැඩෙන්නේ නැති වෙන්න)
    if (memberProvider.isLoading && allMembers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A), strokeWidth: 3)),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: statsItems.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount( crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 90,
      ),
      itemBuilder: (context, index) {
        final item = statsItems[index];
        return InkWell(
          onTap: () => onCardTap(item['title']),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['icon'], color: item['color'], size: 24),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'],
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['value'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}