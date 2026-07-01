import 'package:flutter/material.dart';
import '../widgets/dashboard_stats_grid.dart';
// 💡 FIXED: අපි දැන් සාදාගත්තු ලයිව් ට්‍රැකින් මැප් එක මෙතනට Import කළා මචං
import 'live_tracking_map.dart';

class OverviewPanel extends StatefulWidget {
  final Function(String pageTitle) onSubPageSelected;

  const OverviewPanel({super.key, required this.onSubPageSelected});

  @override
  State<OverviewPanel> createState() => _OverviewPanelState();
}

class _OverviewPanelState extends State<OverviewPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================================
            // 📊 SECTION 1: TOP STATS CARDS GRID
            // ==========================================================
            DashboardStatsGrid(
              onCardTap: (title) {
                widget.onSubPageSelected(title);
              },
            ),

            const SizedBox(height: 24),

            // ==========================================================
            // 🗺️ SECTION 2: LIVE MAP DISPLAY (💡 FIXED WITH STREAM OVERHAUL)
            // ==========================================================
            const Text(
              'Live Members Tracking Map',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            Container(
              height: 500,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                // 💡 FIXED: පරණ static මැප් එක වෙනුවට අලුත් ලයිව් මැප් එක මෙතනට දැම්මා මචං
                child: const LiveTrackingMap(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}