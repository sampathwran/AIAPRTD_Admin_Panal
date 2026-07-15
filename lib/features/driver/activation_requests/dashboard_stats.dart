import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardStats extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;

  // Parent (VehicleChangeRequests) එකෙන් data සහ click events ටික පාලනය කරන්න constructor එක හදලා තියෙනවා
  const DashboardStats({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('vehicles').snapshots(),
      builder: (context, snapshot) {
        int pending = 0;
        int approved = 0;
        int rejected = 0;
        int total = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          total = docs.length;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            switch (data['status']) {
              case 'pending':
                pending++;
                break;
              case 'approved':
                approved++;
                break;
              case 'rejected':
                rejected++;
                break;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Column(
            children: [
              // Header Gradient Panel
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: const LinearGradient(
                    colors: [Color(0xff1B2735), Color(0xff2C5364)],
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.dashboard_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Vehicle Dashboard",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Interactive Stats Row
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      title: "Pending",
                      count: pending.toString(),
                      color: Colors.orange,
                      isActive: selectedStatus == 'pending',
                      onTap: () => onStatusChanged('pending'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _statCard(
                      title: "Approved",
                      count: approved.toString(),
                      color: Colors.green,
                      isActive: selectedStatus == 'approved',
                      onTap: () => onStatusChanged('approved'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _statCard(
                      title: "Rejected",
                      count: rejected.toString(),
                      color: Colors.red,
                      isActive: selectedStatus == 'rejected',
                      onTap: () => onStatusChanged('rejected'),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _statCard(
                      title: "Total",
                      count: total.toString(),
                      color: Colors.blue,
                      isActive: selectedStatus == 'all',
                      onTap: () => onStatusChanged('all'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Modern Card Custom Widget
  Widget _statCard({
    required String title,
    required String count,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? color : Colors.transparent,
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              // Fixed deprecation using withValues
              color: isActive
                  ? color.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isActive ? color : const Color(0xff1B2735),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? color : Colors.grey.shade500,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
