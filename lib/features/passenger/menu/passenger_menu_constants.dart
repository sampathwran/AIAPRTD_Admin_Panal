import 'package:flutter/material.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/menu/driver_menu_constants.dart';

class PassengerMenuConstants {
  static const List<AdminMenuItem> menuItems = [
    AdminMenuItem(title: 'Passengers Overview', icon: Icons.pie_chart_rounded, route: 'overview'),
    AdminMenuItem(title: 'Total Users List', icon: Icons.supervised_user_circle_rounded, route: 'total_users'),
    AdminMenuItem(title: 'Verification Requests', icon: Icons.verified_user_rounded, route: 'verification_requests'),
    AdminMenuItem(title: 'User Refunds', icon: Icons.assignment_return_rounded, route: 'refunds'),
    AdminMenuItem(title: 'Booking History', icon: Icons.map_rounded, route: 'booking_history'),
    AdminMenuItem(title: 'Promo & Benefits', icon: Icons.card_giftcard_rounded, route: 'promo'),
    AdminMenuItem(title: 'Customer Support', icon: Icons.contact_support_rounded, route: 'support'),
    AdminMenuItem(title: 'Polls & Votes', icon: Icons.poll_rounded, route: 'votes'),
    AdminMenuItem(title: 'Campaign Ads', icon: Icons.campaign_rounded, route: 'campaigns'),
    AdminMenuItem(title: 'Push Notifications', icon: Icons.mail_rounded, route: 'notifications'),
    AdminMenuItem(title: 'Fare Category & Rates', icon: Icons.monetization_on_rounded, route: 'fare_rates'),
    AdminMenuItem(title: 'App Configurations', icon: Icons.tune_rounded, route: 'app_config'),
  ];
}
