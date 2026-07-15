import 'package:flutter/material.dart';

class MemberPayoutsPanel extends StatelessWidget {
  const MemberPayoutsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '💰 Driver Earnings, Commissions & Bank Payouts',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
