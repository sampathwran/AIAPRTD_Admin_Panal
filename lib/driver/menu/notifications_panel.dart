import 'package:flutter/material.dart';

class NotificationsPanel extends StatelessWidget {
  const NotificationsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('🔔 Send Push Notifications & Bulk SMS to Drivers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}