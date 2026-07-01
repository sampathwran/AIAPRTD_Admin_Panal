import 'package:flutter/material.dart';

class RideHistoryPanel extends StatelessWidget {
  const RideHistoryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('🚗 Completed, Ongoing & Cancelled Rides Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}