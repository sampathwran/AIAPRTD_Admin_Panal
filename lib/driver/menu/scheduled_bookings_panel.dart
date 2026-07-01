import 'package:flutter/material.dart';

class ScheduledBookingsPanel extends StatelessWidget {
  const ScheduledBookingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '📅 Scheduled Bookings - Advance Ride Management',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}