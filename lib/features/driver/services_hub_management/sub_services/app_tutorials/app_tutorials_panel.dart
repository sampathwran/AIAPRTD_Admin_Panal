import 'package:flutter/material.dart';
import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';

class AppTutorialsPanel extends StatelessWidget {
  const AppTutorialsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_rounded, size: 64, color: AdminColors.faint.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'App Tutorials Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AdminColors.inkSoft),
          ),
          const SizedBox(height: 8),
          const Text(
            'This module is currently under construction.\nWe will code this part later.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AdminColors.muted),
          ),
        ],
      ),
    );
  }
}
