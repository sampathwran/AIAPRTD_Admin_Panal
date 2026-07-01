import 'package:flutter/material.dart';

class DriverMenuConstants {
  // 🚖 DRIVER DASHBOARD MENUS (අයිතම 13)
  static final List<String> menuTitles = [
    'Drivers Overview',
    'Total Members List',
    'Activation Requests',
    'Member Payouts',
    'Ride History',
    'Scheduled Bookings', // 👈 6 වෙනියට අලුතින් එකතු කරා මචං
    'Member Benefits',
    'Support Tickets',
    'Votes',
    'Ads Management',
    'Notifications',
    'Vehicle Category & Rates',
    'System Settings',
  ];

  static final List<IconData> menuIcons = [
    Icons.analytics_rounded,
    Icons.people_alt_rounded,
    Icons.how_to_reg_rounded,
    Icons.payments_rounded,
    Icons.history_toggle_off_rounded,
    Icons.calendar_month_rounded, // 👈 Scheduled Bookings වලට ගැලපෙන අයිකන් එක
    Icons.card_membership_rounded,
    Icons.support_agent_rounded,
    Icons.how_to_vote_rounded,
    Icons.ads_click_rounded,
    Icons.notifications_active_rounded,
    Icons.local_taxi_rounded,
    Icons.settings_applications_rounded,
  ];
}