import 'package:flutter/material.dart';

class SupportTicketsPanel extends StatelessWidget {
  const SupportTicketsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('🛠️ Driver Complaints & Help Desk Tickets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}