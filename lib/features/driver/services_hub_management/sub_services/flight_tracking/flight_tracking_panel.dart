import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';
import 'package:intl/intl.dart';

class FlightTrackingPanel extends StatelessWidget {
  const FlightTrackingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight Tracking Analytics'),
        backgroundColor: Colors.white,
        foregroundColor: AdminColors.inkSoft,
        elevation: 0,
      ),
      backgroundColor: AdminColors.canvas,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Flight API Status',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AdminColors.inkSoft),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: const Icon(Icons.check_circle, color: Colors.green),
                ),
                title: const Text('AirLabs API Active', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Member App is successfully pulling live flight schedules.'),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'User Engagement Analytics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AdminColors.inkSoft),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('analytics').doc('flight_tracking').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  final totalViews = data['totalViews'] ?? 0;
                  final Timestamp? lastViewedTs = data['lastViewed'];
                  final lastViewedStr = lastViewedTs != null 
                      ? DateFormat('MMM d, yyyy - h:mm a').format(lastViewedTs.toDate()) 
                      : 'Never';

                  return GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2,
                    children: [
                      _buildStatCard(
                        'Total Views',
                        totalViews.toString(),
                        Icons.visibility,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Last Viewed',
                        lastViewedStr,
                        Icons.access_time,
                        Colors.orange,
                        isSmallText: true,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool isSmallText = false}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(color: AdminColors.muted, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    value, 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: isSmallText ? 16 : 24, 
                      color: AdminColors.inkSoft
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
