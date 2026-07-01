import 'package:flutter/material.dart';

class SystemSettingsPanel extends StatelessWidget {
  const SystemSettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('⚙️ Driver App Configurations & Core System Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}