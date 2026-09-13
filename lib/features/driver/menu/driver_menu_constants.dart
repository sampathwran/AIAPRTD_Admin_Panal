import 'package:flutter/material.dart';

class AdminMenuItem {
  final String title;
  final IconData icon;
  final String route;
  final List<AdminMenuItem> children;

  const AdminMenuItem({
    required this.title,
    required this.icon,
    required this.route,
    this.children = const [],
  });
}

class DriverMenuConstants {
  static const List<AdminMenuItem> menuItems = [
    AdminMenuItem(
      title: 'Drivers Overview',
      icon: Icons.analytics_rounded,
      route: 'overview',
    ),
    AdminMenuItem(
      title: 'Total Members List',
      icon: Icons.people_alt_rounded,
      route: 'total_members',
    ),
    AdminMenuItem(
      title: 'Membership IDs',
      icon: Icons.badge_rounded,
      route: 'id_management',
    ),
    AdminMenuItem(
      title: 'Activation Requests',
      icon: Icons.how_to_reg_rounded,
      route: 'activation_requests',
    ),
    AdminMenuItem(
      title: 'Payment Approvals',
      icon: Icons.receipt_long_rounded,
      route: 'payment_approvals',
    ),
    AdminMenuItem(
      title: 'Scheduled Bookings',
      icon: Icons.calendar_month_rounded,
      route: 'bookings',
    ),
    AdminMenuItem(
      title: 'Support Tickets',
      icon: Icons.support_agent_rounded,
      route: 'support_tickets',
    ),
    AdminMenuItem(
      title: 'Votes',
      icon: Icons.how_to_vote_rounded,
      route: 'votes',
    ),
    AdminMenuItem(
      title: 'Notifications',
      icon: Icons.notifications_rounded,
      route: 'notifications',
    ),
    AdminMenuItem(
      title: 'System Settings',
      icon: Icons.settings_rounded,
      route: 'settings',
    ),
    AdminMenuItem(
      title: 'Special Days',
      icon: Icons.celebration_rounded,
      route: 'special_days',
    ),
    AdminMenuItem(
      title: 'Vehicle Categories',
      icon: Icons.directions_car_rounded,
      route: 'vehicle_rates',
    ),
    AdminMenuItem(
      title: 'Membership Approvals',
      icon: Icons.verified_user_rounded,
      route: 'membership_approvals',
    ),
    AdminMenuItem(
      title: 'Finance',
      icon: Icons.account_balance_rounded,
      route: 'finance',
    ),
    AdminMenuItem(
      title: 'Member Benefits',
      icon: Icons.card_giftcard_rounded,
      route: 'member_benefits',
    ),
    AdminMenuItem(
      title: 'P2P Transfers',
      icon: Icons.swap_horiz_rounded,
      route: 'p2p',
    ),
    AdminMenuItem(
      title: 'Withdrawal Requests',
      icon: Icons.account_balance_wallet_rounded,
      route: 'withdrawals',
    ),
    AdminMenuItem(
      title: 'Driver Service Hub',
      icon: Icons.apps_rounded,
      route: 'services_hub',
      children: [
        AdminMenuItem(
          title: 'Configuration',
          icon: Icons.settings_suggest_rounded,
          route: 'services_hub_config',
        ),
        AdminMenuItem(
          title: 'Marketplace',
          icon: Icons.storefront_rounded,
          route: 'marketplace',
        ),
        AdminMenuItem(
          title: 'Mobile Reload',
          icon: Icons.phonelink_ring_rounded,
          route: 'mobile_reload',
        ),
        AdminMenuItem(
          title: 'Flight Tracking',
          icon: Icons.flight_takeoff_rounded,
          route: 'flight_tracking',
        ),
        AdminMenuItem(
          title: 'Welfare Shops',
          icon: Icons.local_grocery_store_rounded,
          route: 'welfare_shops',
        ),
        AdminMenuItem(
          title: 'Service Stations',
          icon: Icons.build_circle_rounded,
          route: 'service_stations',
        ),
        AdminMenuItem(
          title: 'Vehicle Parts',
          icon: Icons.car_repair_rounded,
          route: 'vehicle_parts',
        ),
        AdminMenuItem(
          title: 'Driver Loans',
          icon: Icons.real_estate_agent_rounded,
          route: 'driver_loans',
        ),
        AdminMenuItem(
          title: 'Police & Traffic',
          icon: Icons.local_police_rounded,
          route: 'police_traffic',
        ),
        AdminMenuItem(
          title: 'Emergency SOS',
          icon: Icons.sos_rounded,
          route: 'emergency_sos',
        ),
        AdminMenuItem(
          title: 'EV Charging',
          icon: Icons.ev_station_rounded,
          route: 'ev_charging',
        ),
        AdminMenuItem(
          title: 'App Tutorials',
          icon: Icons.play_lesson_rounded,
          route: 'app_tutorials',
        ),
      ],
    ),
  ];
}


