import 'package:flutter/material.dart';

class VotesPanel extends StatelessWidget {
  const VotesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('🗳️ Driver Association Voting & Polls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}