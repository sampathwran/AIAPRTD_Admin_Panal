import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/marketplace_ads/tabs/marketplace_categories_tab.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/marketplace_ads/tabs/marketplace_pending_tab.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/marketplace_ads/tabs/marketplace_active_tab.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/marketplace_ads/tabs/marketplace_sold_tab.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/marketplace_ads/tabs/marketplace_sponsor_tab.dart';

class AdsManagementPanel extends StatefulWidget {
  const AdsManagementPanel({super.key});

  @override
  State<AdsManagementPanel> createState() => _AdsManagementPanelState();
}

class _AdsManagementPanelState extends State<AdsManagementPanel> {
  @override
  void initState() {
    super.initState();
    _cleanupOldSoldAds();
  }

  Future<void> _cleanupOldSoldAds() async {
    // Delete sold ads older than 7 days
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await FirebaseFirestore.instance
          .collection('marketplace_ads')
          .where('status', isEqualTo: 'sold')
          .where('soldAt', isLessThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      debugPrint("Cleaned up ${snapshot.docs.length} old sold ads.");
    } catch (e) {
      debugPrint("Error cleaning up old ads: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              isScrollable: true,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: [
                _buildCountTab(
                  Icons.category,
                  "Categories",
                  FirebaseFirestore.instance
                      .collection('marketplace_categories')
                      .snapshots(),
                ),
                _buildCountTab(
                  Icons.pending_actions,
                  "Pending Approvals",
                  FirebaseFirestore.instance
                      .collection('marketplace_ads')
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                ),
                _buildCountTab(
                  Icons.check_circle_outline,
                  "Active Ads",
                  FirebaseFirestore.instance
                      .collection('marketplace_ads')
                      .where('status', isEqualTo: 'approved')
                      .snapshots(),
                ),
                const Tab(icon: Icon(Icons.history), text: "Sold / History"),
                const Tab(
                  icon: Icon(Icons.monetization_on),
                  text: "Sponsor Ads",
                ),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                MarketplaceCategoriesTab(),
                MarketplacePendingTab(),
                MarketplaceActiveTab(),
                MarketplaceSoldTab(),
                MarketplaceSponsorTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountTab(
    IconData icon,
    String text,
    Stream<QuerySnapshot> stream,
  ) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(text),
          const SizedBox(width: 8),
          StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final count = snapshot.data!.docs.length;
              if (count == 0) return const SizedBox.shrink();
              return Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
