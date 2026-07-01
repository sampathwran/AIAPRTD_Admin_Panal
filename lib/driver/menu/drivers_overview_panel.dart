import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/member_provider.dart'; // Folder tree එක අනුව provider path එක

// =========================================================================
// 🚀 FIXED IMPORTS: ඔයාගේ නිවැරදි ෆෝල්ඩර් structure එකට අනුව paths මෙන්න මේ විදිහට හැදුවා මචං
// =========================================================================
import '../../screens/sub_panels/total_members_panel.dart';
import '../../screens/sub_panels/active_members_panel.dart';
import '../../screens/sub_panels/inactive_members_panel.dart';
import '../../screens/sub_panels/online_members_panel.dart';
import '../../screens/sub_panels/offline_members_panel.dart';
import '../../screens/sub_panels/ongoing_trips_panel.dart';
import '../../screens/sub_panels/today_complete_panel.dart';
import '../../screens/sub_panels/canceled_trips_panel.dart';
import '../../screens/sub_panels/complaints_panel.dart';

// 💡 සටහන: උඩ තියෙන relative paths (../../) වෙනුවට ඔයාගේ project name එක දාලා
// package imports විදිහට පාවිච්චි කරන්නත් පුළුවන් මචං (වඩාත්ම standard ක්‍රමය):
// import 'package:your_project_name/screens/sub_panels/total_members_panel.dart';

class DriversOverviewPanel extends StatefulWidget {
  const DriversOverviewPanel({super.key});

  @override
  State<DriversOverviewPanel> createState() => _DriversOverviewPanelState();
}

class _DriversOverviewPanelState extends State<DriversOverviewPanel> {
  int _currentViewIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MemberProvider>(context, listen: false).startListeningToMembers();
    });
  }

  // Dashboard එකට ආපහු එන්න පාවිච්චි කරන callback එක
  void _navigateToDashboard() {
    setState(() {
      _currentViewIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentViewIndex,
      children: [
        _buildMainDashboard(context),                      // Index 0
        TotalMembersPanel(onBack: _navigateToDashboard),   // Index 1
        ActiveMembersPanel(onBack: _navigateToDashboard),  // Index 2
        InactiveMembersPanel(onBack: _navigateToDashboard),// Index 3 (🟢 Fixed Bracket Typos Here)
        OnlineMembersPanel(onBack: _navigateToDashboard),  // Index 4
        OfflineMembersPanel(onBack: _navigateToDashboard), // Index 5
        OngoingTripsPanel(onBack: _navigateToDashboard),   // Index 6
        TodayCompletePanel(onBack: _navigateToDashboard),  // Index 7
        CanceledTripsPanel(onBack: _navigateToDashboard),  // Index 8
        ComplaintsPanel(onBack: _navigateToDashboard),     // Index 9
      ],
    );
  }

  // ==========================================================
  // 📊 MAIN DASHBOARD LAYOUT
  // ==========================================================
  Widget _buildMainDashboard(BuildContext context) {
    final memberProvider = Provider.of<MemberProvider>(context);
    final List<dynamic> allDrivers = memberProvider.allMembersList;

    int totalMembers = allDrivers.length;
    int activeMembers = allDrivers.where((d) => d['status'] == 'active').length;
    int inactiveMembers = allDrivers.where((d) => d['status'] != 'active').length;
    int onlineMembers = allDrivers.where((d) => d['isOnline'] == true || d['onlineStatus'] == 'online').length;
    int offlineMembers = totalMembers - onlineMembers;

    final DateTime now = DateTime.now();
    final DateTime startOfToday = DateTime(now.year, now.month, now.day);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Accent Header Block
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2C5364)]),
              ),
              child: const Row(
                children: [
                  Icon(Icons.analytics_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Drivers Overview Center',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text('Real-time operational metrics and grid dispatch diagnostics', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _buildSectionHeading("DRIVER REGISTRY LOGS"),
            const SizedBox(height: 12),

            // Metrics Row Grid View
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 5 : (MediaQuery.of(context).size.width > 768 ? 3 : 2),
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMetricCard('Total Registered', totalMembers.toString(), Icons.group_rounded, Colors.blue, 1),
                _buildMetricCard('Active Verified', activeMembers.toString(), Icons.verified_user_rounded, Colors.indigo, 2),
                _buildMetricCard('Dormant/Inactive', inactiveMembers.toString(), Icons.no_accounts_rounded, Colors.orange, 3),
                _buildMetricCard('Live Online', onlineMembers.toString(), Icons.gpp_good_rounded, Colors.green, 4),
                _buildMetricCard('Offline Sockets', offlineMembers.toString(), Icons.cloud_off_rounded, Colors.blueGrey, 5),
              ],
            ),
            const SizedBox(height: 28),

            _buildSectionHeading("REALTIME JOB DISPATCH MATRIX"),
            const SizedBox(height: 12),

            // Stream Builder Engine for Live Trips Tracking
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('trips').snapshots(),
              builder: (context, tripsSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
                  builder: (context, complaintsSnapshot) {
                    int ongoingTrips = 0;
                    int todayCompleted = 0;
                    int canceledTrips = 0;
                    int activeComplaints = complaintsSnapshot.data?.docs.length ?? 0;

                    if (tripsSnapshot.hasData) {
                      for (var doc in tripsSnapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'] ?? '';

                        if (status == 'ongoing') ongoingTrips++;
                        if (status == 'canceled') canceledTrips++;

                        if (status == 'completed' && data['timestamp'] != null) {
                          final Timestamp t = data['timestamp'];
                          if (t.toDate().isAfter(startOfToday)) {
                            todayCompleted++;
                          }
                        }
                      }
                    }

                    return GridView.count(
                      crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : (MediaQuery.of(context).size.width > 768 ? 2 : 2),
                      shrinkWrap: true,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildMetricCard('Ongoing Rides', ongoingTrips.toString(), Icons.local_taxi_rounded, Colors.purple, 6),
                        _buildMetricCard("Today's Completed", todayCompleted.toString(), Icons.check_circle_rounded, Colors.teal, 7),
                        _buildMetricCard('Canceled Audits', canceledTrips.toString(), Icons.cancel_rounded, Colors.red, 8),
                        _buildMetricCard('Support Tickets', activeComplaints.toString(), Icons.assignment_late_rounded, Colors.redAccent, 9),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeading(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 1.2),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color accentColor, int targetIndex) {
    return InkWell(
      onTap: () => setState(() => _currentViewIndex = targetIndex),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 14),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B2735))),
                const SizedBox(height: 2),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              ],
            )
          ],
        ),
      ),
    );
  }
}