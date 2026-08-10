import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:go_router/go_router.dart';

import 'package:aiaprtd_admin_dashboard/core/providers/member_provider.dart';
import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';
import 'package:aiaprtd_admin_dashboard/features/dashboard_shell/widgets/admin_sidebar.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/overview_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/menu/driver_menu_constants.dart';
import 'package:aiaprtd_admin_dashboard/features/passenger/menu/passenger_menu_constants.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/drivers_overview_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/activation_requests/activation_requests_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/payment_approvals/payment_approvals_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/scheduled_bookings/scheduled_bookings_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/support_tickets/support_tickets_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/votes/votes_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/marketplace_ads/ads_management_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/notifications/notifications_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/system_settings/system_settings_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/membership_approvals/membership_fee_approvals_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/vehicle_category_rates/vehicle_category_rates_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/finance/finance_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/member_benefits/member_benefits_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/p2p_transfers/p2p_transfers_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/withdrawal_requests/withdrawal_requests_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/total_members_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/active_members_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/online_members_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/offline_members_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/inactive_members_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/new_members_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/ongoing_trips_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/today_complete_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/canceled_trips_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/complaints_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/scheduled_bookings/scheduled_bookings_full_panel.dart';

class MainDashboardLayout extends StatefulWidget {
  final String mode;
  final String tab;
  final String? subpage;

  const MainDashboardLayout({
    super.key,
    required this.mode,
    required this.tab,
    this.subpage,
  });

  @override
  State<MainDashboardLayout> createState() => _MainDashboardLayoutState();
}

class _MainDashboardLayoutState extends State<MainDashboardLayout> {
  bool _isSidebarCollapsed = false;

  int get _selectedIndex {
    switch (widget.tab) {
      case 'overview': return 0;
      case 'total_members': return 1;
      case 'activation_requests': return 2;
      case 'payment_approvals': return 3;
      case 'bookings': return 4;
      case 'support_tickets': return 5;
      case 'votes': return 6;
      case 'marketplace': return 7;
      case 'notifications': return 8;
      case 'vehicle_rates': return 9;
      case 'settings': return 10;
      case 'membership_approvals': return 11;
      case 'finance': return 12;
      case 'member_benefits': return 13;
      case 'p2p': return 14;
      case 'withdrawals': return 15;
      default: return 0;
    }
  }

  String _getTabString(int index) {
    switch (index) {
      case 0: return 'overview';
      case 1: return 'total_members';
      case 2: return 'activation_requests';
      case 3: return 'payment_approvals';
      case 4: return 'bookings';
      case 5: return 'support_tickets';
      case 6: return 'votes';
      case 7: return 'marketplace';
      case 8: return 'notifications';
      case 9: return 'vehicle_rates';
      case 10: return 'settings';
      case 11: return 'membership_approvals';
      case 12: return 'finance';
      case 13: return 'member_benefits';
      case 14: return 'p2p';
      case 15: return 'withdrawals';
      default: return 'overview';
    }
  }

  bool get _isDriverMode => widget.mode == 'driver';
  String? get _currentSubPage => widget.subpage;

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
    void goBack() => context.go('/dashboard/${widget.mode}/${widget.tab}');

    switch (title) {
      case 'Total Members':
      case 'Total Members List':
        return TotalMembersPanel(onBack: goBack);
      case 'Active Members':
        return ActiveMembersPanel(onBack: goBack);
      case 'Online Members':
        return OnlineMembersPanel(onBack: goBack);
      case 'Offline Members':
        return OfflineMembersPanel(onBack: goBack);
      case 'Inactive Members':
        return InactiveMembersPanel(onBack: goBack);
      case 'New Members':
        return NewMembersPanel(onBack: goBack);
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
        return const TotalMembersPanel();
      case 2:
        return const ActivationRequestsPanel();
      case 3:
        return const PaymentApprovalsPanel();
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
      case 13:
        return const MemberBenefitsPanel();
      case 14:
        return const P2PTransfersPanel();
      case 15:
        return const WithdrawalRequestsPanel();
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

    final paymentStream = FirebaseFirestore.instance
        .collection('app_usage_payments')
        .where('status', isEqualTo: 'pending')
        .snapshots();
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
    final p2pStream = FirebaseFirestore.instance
        .collection('p2p_debts')
        .where('status', isEqualTo: 'pending_admin_verification')
        .snapshots();
    final withdrawalStream = FirebaseFirestore.instance
        .collection('withdrawal_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
    final marketplaceAdsStream = FirebaseFirestore.instance
        .collection('marketplace_ads')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    final combinedStream = CombineLatestStream.list<QuerySnapshot>([
      paymentStream,
      profileStream,
      vehicleStream,
      kycStream,
      bankStream,
      imageStream,
      p2pStream,
      withdrawalStream,
      marketplaceAdsStream,
    ]);

    return SelectionArea(
      child: Scaffold(
        backgroundColor: AdminColors.canvas,
        body: Row(
          children: [
            StreamBuilder<List<QuerySnapshot>>(
              stream: combinedStream,
              builder: (context, snapshot) {
                int pendingPaymentCount = 0;
                int activationCount = 0;
                int p2pCount = 0;
                int withdrawalCount = 0;
                int marketplaceAdsCount = 0;

                if (snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data!.length == 9) {
                  pendingPaymentCount = snapshot.data![0].docs.length;
                  activationCount =
                      snapshot.data![1].docs.length +
                      snapshot.data![2].docs.length +
                      snapshot.data![3].docs.length +
                      snapshot.data![4].docs.length +
                      snapshot.data![5].docs.length;
                  p2pCount = snapshot.data![6].docs.length;
                  withdrawalCount = snapshot.data![7].docs.length;
                  marketplaceAdsCount = snapshot.data![8].docs.length;
                }

                final badges = <String, int>{};
                if (pendingPaymentCount > 0) {
                  badges['Payment Approvals'] = pendingPaymentCount;
                }
                if (activationCount > 0) {
                  badges['Activation Requests'] = activationCount;
                }
                if (p2pCount > 0) {
                  badges['P2P Transfers'] = p2pCount;
                }
                if (withdrawalCount > 0) {
                  badges['Withdrawal Requests'] = withdrawalCount;
                }
                if (marketplaceAdsCount > 0) {
                  badges['Marketplace Ads'] = marketplaceAdsCount;
                }

                return AdminSidebar(
                  selectedIndex: _selectedIndex,
                  menuTitles: currentMenuTitles,
                  menuIcons: currentMenuIcons,
                  isDriverMode: _isDriverMode,
                  isCollapsed: _isSidebarCollapsed,
                  menuBadges: badges,
                  onToggleCollapse: () {
                    setState(() {
                      _isSidebarCollapsed = !_isSidebarCollapsed;
                    });
                  },
                  onToggleMode: () {
                    final newMode = _isDriverMode ? 'passenger' : 'driver';
                    context.go('/dashboard/$newMode/overview');
                  },
                  onMenuSelected: (index) {
                    context.go('/dashboard/${widget.mode}/${_getTabString(index)}');
                  },
                );
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
                        : () => context.go('/dashboard/${widget.mode}/${widget.tab}'),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _isDriverMode
                          ? (_selectedIndex == 0
                                ? (_currentSubPage != null
                                      ? _getSubPageWidget(_currentSubPage!)
                                      : OverviewPanel(
                                          onSubPageSelected: (title) {
                                            final encoded = Uri.encodeComponent(title);
                                            context.go('/dashboard/${widget.mode}/${widget.tab}?subpage=$encoded');
                                          },
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
                    style: const TextStyle(
                      color: AdminColors.ink,
                      fontSize: 13,
                    ),
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
                  border: Border.all(
                    color: AdminColors.primary.withValues(alpha: 0.3),
                  ),
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
