import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'package:aiaprtd_admin_dashboard/features/auth/admin_login_page.dart';
import 'package:aiaprtd_admin_dashboard/features/dashboard_shell/main_dashboard_layout.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const AdminLoginPage(),
    ),
    GoRoute(
      path: '/dashboard/:mode/:tab',
      builder: (context, state) {
        final mode = state.pathParameters['mode'] ?? 'driver';
        final tab = state.pathParameters['tab'] ?? 'overview';
        final subpage = state.uri.queryParameters['subpage'];

        return MainDashboardLayout(
          mode: mode,
          tab: tab,
          subpage: subpage,
        );
      },
    ),
    GoRoute(
      path: '/dashboard',
      redirect: (context, state) => '/dashboard/driver/overview',
    ),
  ],
);
