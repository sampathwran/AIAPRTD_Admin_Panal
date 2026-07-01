import 'package:flutter/material.dart';

class AdsManagementPanel extends StatelessWidget {
  const AdsManagementPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('📢 In-App Banner Ads & Driver Target Campaigns', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}