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
import 'package:aiaprtd_admin_dashboard/features/driver/services_hub_management/sub_services/marketplace_ads/ads_management_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/services_hub_management/services_hub_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/services_hub_management/sub_services/mobile_reload/mobile_reload_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/services_hub_management/sub_services/flight_tracking/flight_tracking_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/services_hub_management/sub_services/welfare_shops/welfare_shops_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/services_hub_management/sub_services/service_stations/service_stations_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/services_hub_management/sub_services/vehicle_parts/vehicle_parts_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/services_hub_management/sub_services/driver_loans/driver_loans_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/services_hub_management/sub_services/police_traffic/police_traffic_management_page.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/services_hub_management/sub_services/emergency_sos/emergency_sos_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/services_hub_management/sub_services/ev_charging/ev_charging_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/services_hub_management/sub_services/app_tutorials/app_tutorials_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/notifications/notifications_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/system_settings/system_settings_panel.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/system_settings/special_days_panel.dart';
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

  Widget _getDriverPanel(String route) {
    switch (route) {
      case 'overview': return const DriversOverviewPanel();
      case 'total_members': return const TotalMembersPanel();
      case 'activation_requests': return const ActivationRequestsPanel();
      case 'payment_approvals': return const PaymentApprovalsPanel();
      case 'bookings': return const ScheduledBookingsPanel();
      case 'support_tickets': return const SupportTicketsPanel();
      case 'votes': return const VotesPanel();
      case 'notifications': return const NotificationsPanel();
      case 'vehicle_rates': return const VehicleCategoryRatesPanel();
      case 'settings': return const SystemSettingsPanel();
      case 'special_days': return const SpecialDaysPanel();
      case 'membership_approvals': return const MembershipFeeApprovalsPanel();
      case 'finance': return const FinancePanel();
      case 'member_benefits': return const MemberBenefitsPanel();
      case 'p2p': return const P2PTransfersPanel();
      case 'withdrawals': return const WithdrawalRequestsPanel();
      
      // Driver Service Hub Nested Routes
      case 'services_hub': return const ServicesHubPanel(); // Fallback if parent clicked
      case 'services_hub_config': return const ServicesHubPanel();
      case 'marketplace': return const AdsManagementPanel();
      case 'mobile_reload': return const MobileReloadPanel();
      case 'flight_tracking': return const FlightTrackingPanel();
      case 'welfare_shops': return const WelfareShopsPanel();
      case 'service_stations': return const ServiceStationsPanel();
      case 'vehicle_parts': return const VehiclePartsPanel();
      case 'driver_loans': return const DriverLoansPanel();
      case 'police_traffic': return const PoliceTrafficManagementPage();
      case 'emergency_sos': return const EmergencySOSPanel();
      case 'ev_charging': return const EvChargingPanel();
      case 'app_tutorials': return const AppTutorialsPanel();
      
      default: return const DriversOverviewPanel();
    }
  }

  String _getTitleForRoute(String route, List<AdminMenuItem> items) {
    for (var item in items) {
      if (item.route == route) return item.title;
      for (var child in item.children) {
        if (child.route == route) return child.title;
      }
    }
    return 'Dashboard';
  }

  @override
  Widget build(BuildContext context) {
    final currentMenuItems = _isDriverMode
        ? DriverMenuConstants.menuItems
        : PassengerMenuConstants.menuItems;
        
    final selectedTitle = _currentSubPage ?? _getTitleForRoute(widget.tab, currentMenuItems);

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
                  badges['Marketplace'] = marketplaceAdsCount; // Updated key to match nested title
                }

                return AdminSidebar(
                  currentRoute: widget.tab,
                  menuItems: currentMenuItems,
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
                  onMenuSelected: (route) {
                    context.go('/dashboard/${widget.mode}/$route');
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
                          ? (widget.tab == 'overview'
                                ? (_currentSubPage != null
                                      ? _getSubPageWidget(_currentSubPage!)
                                      : OverviewPanel(
                                          onSubPageSelected: (title) {
                                            final encoded = Uri.encodeComponent(title);
                                            context.go('/dashboard/${widget.mode}/${widget.tab}?subpage=$encoded');
                                          },
                                        ))
                                : _currentSubPage != null
                                    ? _getSubPageWidget(_currentSubPage!)
                                    : _getDriverPanel(widget.tab))
                          : Center(
                              child: Text(
                                'Passenger ${selectedTitle} Panel\n(Coming Soon)',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AdminColors.faint,
                                  fontSize: 16,
                                ),
                              ),
                            ),
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
    this.isSubPage = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AdminColors.canvas,
        border: Border(
          bottom: BorderSide(color: AdminColors.sidebarLine),
        ),
      ),
      child: Row(
        children: [
          if (isSubPage && onBack != null) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AdminColors.ink),
              onPressed: onBack,
              tooltip: 'Back',
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              color: AdminColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isDriverMode
                  ? AdminColors.driver.withValues(alpha: 0.1)
                  : AdminColors.passenger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDriverMode
                    ? AdminColors.driver.withValues(alpha: 0.2)
                    : AdminColors.passenger.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDriverMode
                        ? AdminColors.driver
                        : AdminColors.passenger,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isDriverMode ? 'Driver App Live' : 'Passenger App Live',
                  style: TextStyle(
                    color: isDriverMode
                        ? AdminColors.driver
                        : AdminColors.passenger,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          const CircleAvatar(
            radius: 18,
            backgroundColor: AdminColors.sidebarLine,
            child: Icon(
              Icons.person_outline_rounded,
              color: AdminColors.ink,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}


