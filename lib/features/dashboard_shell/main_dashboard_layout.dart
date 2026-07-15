import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aiaprtd_admin_dashboard/core/providers/member_provider.dart';
import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';
import 'package:aiaprtd_admin_dashboard/features/dashboard_shell/widgets/admin_sidebar.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/overview_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/menu/driver_menu_constants.dart';
import 'package:aiaprtd_admin_dashboard/features/passenger/menu/passenger_menu_constants.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/drivers_overview_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/total_members/total_members_list_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/activation_requests/activation_requests_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/ride_history/ride_history_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/scheduled_bookings/scheduled_bookings_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/support_tickets/support_tickets_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/votes/votes_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/marketplace_ads/ads_management_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/notifications/notifications_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/system_settings/system_settings_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/membership_approvals/membership_fee_approvals_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/vehicle_category_rates/vehicle_category_rates_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/finance/finance_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/total_members_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/active_members_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/online_members_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/offline_members_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/inactive_members_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/ongoing_trips_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/today_complete_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/canceled_trips_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/complaints_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/scheduled_bookings/scheduled_bookings_full_panel.dart';

class MainDashboardLayout extends StatefulWidget {
  const MainDashboardLayout({super.key});

  @override
  State<MainDashboardLayout> createState() => _MainDashboardLayoutState();
}

class _MainDashboardLayoutState extends State<MainDashboardLayout> {
  int _selectedIndex = 0;
  bool _isDriverMode = true;
  String? _currentSubPage;
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MemberProvider>(
        context,
        listen: false,
      ).startListeningToMembers();
    });
  }

  Widget _getSubPageWidget(String title) {
    void goBack() => setState(() => _currentSubPage = null);

    switch (title) {
      case 'Total Members':
        return TotalMembersPanel(onBack: goBack);
      case 'Active Members':
        return ActiveMembersPanel(onBack: goBack);
      case 'Online Members':
        return OnlineMembersPanel(onBack: goBack);
      case 'Offline Members':
        return OfflineMembersPanel(onBack: goBack);
      case 'Inactive Members':
        return InactiveMembersPanel(onBack: goBack);
      case 'Scheduled Bookings':
        return ScheduledBookingsFullPanel(onBack: goBack);
      case 'Ongoing Trips':
        return OngoingTripsPanel(onBack: goBack);
      case 'Today Complete':
        return TodayCompletePanel(onBack: goBack);
      case 'Canceled Trips':
        return CanceledTripsPanel(onBack: goBack);
      case 'Complaints':
        return ComplaintsPanel(onBack: goBack);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _getDriverPanel(int index) {
    switch (index) {
      case 0:
        return const DriversOverviewPanel();
      case 1:
        return const TotalMembersListPanel();
      case 2:
        return const ActivationRequestsPanel();
      case 3:
        return const RideHistoryPanel();
      case 4:
        return const ScheduledBookingsPanel();
      case 5:
        return const SupportTicketsPanel();
      case 6:
        return const VotesPanel();
      case 7:
        return const AdsManagementPanel();
      case 8:
        return const NotificationsPanel();
      case 9:
        return const VehicleCategoryRatesPanel();
      case 10:
        return const SystemSettingsPanel();
      case 11:
        return const MembershipFeeApprovalsPanel();
      case 12:
        return const FinancePanel();
      default:
        return const DriversOverviewPanel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMenuTitles = _isDriverMode
        ? DriverMenuConstants.menuTitles
        : PassengerMenuConstants.menuTitles;
    final currentMenuIcons = _isDriverMode
        ? DriverMenuConstants.menuIcons
        : PassengerMenuConstants.menuIcons;
    final selectedTitle =
        _currentSubPage ??
        currentMenuTitles[_selectedIndex.clamp(
          0,
          currentMenuTitles.length - 1,
        )];

    return Scaffold(
      backgroundColor: AdminColors.canvas,
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: _selectedIndex,
            menuTitles: currentMenuTitles,
            menuIcons: currentMenuIcons,
            isDriverMode: _isDriverMode,
            isCollapsed: _isSidebarCollapsed,
            onToggleCollapse: () =>
                setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardTopBar(
                  title: selectedTitle,
                  isDriverMode: _isDriverMode,
                  isSubPage: _currentSubPage != null,
                  onBack: _currentSubPage == null
                      ? null
                      : () => setState(() => _currentSubPage = null),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _isDriverMode
                        ? (_selectedIndex == 0
                              ? (_currentSubPage != null
                                    ? _getSubPageWidget(_currentSubPage!)
                                    : OverviewPanel(
                                        onSubPageSelected: (title) => setState(
                                          () => _currentSubPage = title,
                                        ),
                                      ))
                              : _getDriverPanel(_selectedIndex))
                        : _PassengerComingSoon(title: selectedTitle),
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

class _DashboardTopBar extends StatelessWidget {
  final String title;
  final bool isDriverMode;
  final bool isSubPage;
  final VoidCallback? onBack;

  const _DashboardTopBar({
    required this.title,
    required this.isDriverMode,
    required this.isSubPage,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isDriverMode
        ? AdminColors.driver
        : AdminColors.passenger;

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(bottom: BorderSide(color: AdminColors.line)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          return Row(
            children: [
              if (isSubPage)
                Tooltip(
                  message: 'Back',
                  child: IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
              if (isSubPage) const SizedBox(width: 4),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isDriverMode
                                ? 'DRIVER OPERATIONS'
                                : 'PASSENGER OPERATIONS',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: accentColor.darken(),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(width: 8),
                          const AdminStatusPill(
                            label: 'LIVE CONSOLE',
                            icon: Icons.sensors_rounded,
                            color: AdminColors.success,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: TextField(
                    style: const TextStyle(color: AdminColors.ink, fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search members, bookings, tickets',
                      hintStyle: const TextStyle(
                        color: AdminColors.faint,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: AdminColors.muted,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      filled: true,
                      fillColor: AdminColors.surfaceAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 12),
              _TopIconButton(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                badgeColor: accentColor,
              ),
              const SizedBox(width: 8),
              if (!compact) ...[
                _TopIconButton(
                  icon: Icons.tune_rounded,
                  label: 'Quick filters',
                ),
                const SizedBox(width: 14),
              ],
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AdminColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AdminColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AdminColors.primary,
                  size: 20,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? badgeColor;

  const _TopIconButton({
    required this.icon,
    required this.label,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AdminColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AdminColors.line),
            ),
            child: Icon(icon, color: AdminColors.inkSoft, size: 20),
          ),
          if (badgeColor != null)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PassengerComingSoon extends StatelessWidget {
  final String title;

  const _PassengerComingSoon({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('passenger-panel'),
      color: AdminColors.canvas,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: AdminSurface(
          elevated: true,
          padding: const EdgeInsets.all(28),
          child: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AdminColors.passenger.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.groups_2_rounded,
                    color: AdminColors.passenger,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AdminColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Passenger admin screens are ready to be connected to their data modules.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AdminColors.muted, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _ColorTone on Color {
  Color darken([double amount = .18]) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
