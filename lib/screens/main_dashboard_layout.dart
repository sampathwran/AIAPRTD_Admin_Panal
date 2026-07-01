import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/member_provider.dart';
import '../widgets/admin_sidebar.dart';
import 'overview_panel.dart';

// 📂 Driver/Menu ෆයිල් 13 කන්ස්ටන්ට්ස් සහ පැනල්ස්
import '../driver/driver_menu_constants.dart';
import '../passenger/passenger_menu_constants.dart';
import '../driver/menu/drivers_overview_panel.dart';
import '../driver/menu/total_members_list_panel.dart';
import '../requests/activation_requests_panel.dart';
import '../driver/menu/member_payouts_panel.dart';
import '../driver/menu/ride_history_panel.dart';
import '../driver/menu/scheduled_bookings_panel.dart';
import '../driver/menu/member_benefits_panel.dart';
import '../driver/menu/support_tickets_panel.dart';
import '../driver/menu/votes_panel.dart';
import '../driver/menu/ads_management_panel.dart';
import '../driver/menu/notifications_panel.dart';
import '../driver/menu/system_settings_panel.dart';

// =========================================================================
// 🎯 FIXED IMPORT PATH: අපි සාදාගත් අලුත්ම rates ෆෝල්ඩර් එකට පාත් එක හැදුවා මචං
// =========================================================================
import '../rates/vehicle_category_rates_panel.dart';

// 📂 Overview එක ඇතුළේ කාඩ් 9 ක්ලික් කරොත් ඕපන් වෙන පැනල්ස්
import 'sub_panels/total_members_panel.dart';
import 'sub_panels/active_members_panel.dart';
import 'sub_panels/online_members_panel.dart';
import 'sub_panels/offline_members_panel.dart';
import 'sub_panels/inactive_members_panel.dart';
import 'sub_panels/ongoing_trips_panel.dart';
import 'sub_panels/today_complete_panel.dart';
import 'sub_panels/canceled_trips_panel.dart';
import 'sub_panels/complaints_panel.dart';

class MainDashboardLayout extends StatefulWidget {
  const MainDashboardLayout({super.key});

  @override
  State<MainDashboardLayout> createState() => _MainDashboardLayoutState();
}

class _MainDashboardLayoutState extends State<MainDashboardLayout> {
  int _selectedIndex = 0;
  bool _isDriverMode = true;
  String? _currentSubPage;

  // 💡 NEW STATE: සයිඩ්බාර් එක ඇකිලිලාද නැද්ද කියලා පාලනය කරන variable එක මචං
  bool _isSidebarCollapsed = false;

  // ==========================================================
  // 📡 INITIALIZATION (Firebase Live Connection)
  // ==========================================================
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MemberProvider>(context, listen: false).startListeningToMembers();
    });
  }

  // 🎛️ CARD SUB PANEL SELECTOR METHOD
  Widget _getSubPageWidget(String title) {
    void goBack() {
      setState(() => _currentSubPage = null);
    }

    switch (title) {
      case 'Total Members': return TotalMembersPanel(onBack: goBack);
      case 'Active Members': return ActiveMembersPanel(onBack: goBack);
      case 'Online Members': return OnlineMembersPanel(onBack: goBack);
      case 'Offline Members': return OfflineMembersPanel(onBack: goBack);
      case 'Inactive Members': return InactiveMembersPanel(onBack: goBack);
      case 'Ongoing Trips': return OngoingTripsPanel(onBack: goBack);
      case 'Today Complete': return TodayCompletePanel(onBack: goBack);
      case 'Canceled Trips': return CanceledTripsPanel(onBack: goBack);
      case 'Complaints': return ComplaintsPanel(onBack: goBack);
      default: return Container();
    }
  }

  // 🎛️ සයිඩ්බාර් එකේ ක්ලික් එක අනුව නිවැරදි ෆයිල් එක ලෝඩ් කරන මෙතඩ් එක
  Widget _getDriverPanel(int index) {
    switch (index) {
      case 0: return const DriversOverviewPanel();
      case 1: return const TotalMembersListPanel();
      case 2: return const ActivationRequestsPanel();
      case 3: return const MemberPayoutsPanel();
      case 4: return const RideHistoryPanel();
      case 5: return const ScheduledBookingsPanel();
      case 6: return const MemberBenefitsPanel();
      case 7: return const SupportTicketsPanel();
      case 8: return const VotesPanel();
      case 9: return const AdsManagementPanel();
      case 10: return const NotificationsPanel();
      case 11: return const VehicleCategoryRatesPanel(); // 💡 ඔන්න දැන් පැනල් එක බය නැතුව ලෝඩ් වෙනවා මචං
      case 12: return const SystemSettingsPanel();
      default: return const DriversOverviewPanel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMenuTitles = _isDriverMode ? DriverMenuConstants.menuTitles : PassengerMenuConstants.menuTitles;
    final currentMenuIcons = _isDriverMode ? DriverMenuConstants.menuIcons : PassengerMenuConstants.menuIcons;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // ==========================================================
          // 📊 SECTION 1: SIDEBAR (Updated with Collapse Callbacks)
          // ==========================================================
          AdminSidebar(
            selectedIndex: _selectedIndex,
            menuTitles: currentMenuTitles,
            menuIcons: currentMenuIcons,
            isDriverMode: _isDriverMode,
            isCollapsed: _isSidebarCollapsed,
            onToggleCollapse: () {
              setState(() {
                _isSidebarCollapsed = !_isSidebarCollapsed;
              });
            },
            onMenuSelected: (index) {
              setState(() {
                _selectedIndex = index;
                _currentSubPage = null;
              });
            },
            onToggleMode: () {
              setState(() {
                _isDriverMode = !_isDriverMode;
                _selectedIndex = 0;
                _currentSubPage = null;
              });
            },
          ),

          // ==========================================================
          // 💻 SECTION 2: MAIN DYNAMIC CONTENT AREA
          // ==========================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🛑 1. Top Navigation Bar
                Container(
                  height: 70,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isDriverMode ? Colors.blue[50] : Colors.blueGrey[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _isDriverMode ? 'DRIVERS ZONE' : 'PASSENGERS ZONE',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _isDriverMode ? Colors.blue[800] : Colors.blueGrey[800]),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _currentSubPage ?? currentMenuTitles[_selectedIndex],
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          Icon(Icons.notifications_none_rounded, color: Colors.grey),
                          SizedBox(width: 20),
                          CircleAvatar(
                            backgroundColor: Colors.amber,
                            child: Icon(Icons.gavel_rounded, color: Colors.black87, size: 20),
                          )
                        ],
                      )
                    ],
                  ),
                ),

                // ⚡ 2. Content Switching logic
                Expanded(
                  child: _isDriverMode
                      ? (_selectedIndex == 0
                      ? (_currentSubPage != null
                      ? _getSubPageWidget(_currentSubPage!)
                      : OverviewPanel(
                    onSubPageSelected: (title) {
                      setState(() => _currentSubPage = title);
                    },
                  ))
                      : _getDriverPanel(_selectedIndex))
                      : const Center(child: Text('Passenger Panels Coming Soon...')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}