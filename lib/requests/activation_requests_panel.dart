// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart'; // 💡 NEW: rxdart import කළා

import 'profile_update_requests.dart';
import 'vehicle_change_requests.dart';
import 'kyc_verification_requests.dart';
import 'bank_account_details_change.dart';
import 'profile_image_requests.dart';

class ActivationRequestsPanel extends StatelessWidget {
  const ActivationRequestsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // 🔄 STREAMS ENGINE: ලයිව් ස්ට්‍රීම් 4
    // ==========================================================

    final Stream<QuerySnapshot> profileStream = FirebaseFirestore.instance
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .where('requestType', isEqualTo: 'profile_update')
        .snapshots();

    final Stream<QuerySnapshot> vehicleStream = FirebaseFirestore.instance
        .collection('vehicles')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    final Stream<QuerySnapshot> kycStream = FirebaseFirestore.instance
        .collection('verify_kyc')
        .where('kycApprovalStatus', isEqualTo: 'pending')
        .snapshots();

    final Stream<QuerySnapshot> bankStream = FirebaseFirestore.instance
        .collection('verify_bank')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    final Stream<QuerySnapshot> imageStream = FirebaseFirestore.instance
        .collection('profile_image_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    final Stream<List<QuerySnapshot>> combinedStream = CombineLatestStream.list([
      profileStream,
      vehicleStream,
      kycStream,
      bankStream,
      imageStream,
    ]);

    return StreamBuilder<List<QuerySnapshot>>(
      stream: combinedStream, // 💡 Stream එක මෙතනට දුන්නා
      builder: (context, snapshot) {
        // Data ලෝඩ් වෙනකම් පෙන්වන එක
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Error ආවොත්
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        int totalPending = 0;
        int profileCount = 0;
        int vehicleCount = 0;
        int kycCount = 0;
        int bankCount = 0;
        int imageCount = 0;

        if (snapshot.hasData && snapshot.data!.length >= 5) {
          profileCount = snapshot.data![0].docs.length;
          vehicleCount = snapshot.data![1].docs.length;
          kycCount = snapshot.data![2].docs.length;
          bankCount = snapshot.data![3].docs.length;
          imageCount = snapshot.data![4].docs.length;

          totalPending = profileCount + vehicleCount + kycCount + bankCount + imageCount;
        }

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              "Activation Panel",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xff1B2735)),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0, top: 4),
                child: Badge(
                  label: Text(
                    "$totalPending",
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.red,
                  isLabelVisible: totalPending > 0,
                  child: IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Color(0xff1B2735), size: 24),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("You have $totalPending pending requests to review."),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            physics: const BouncingScrollPhysics(),
            children: [
              // 💡 SUMMARY CARD
              _buildSummaryCard(totalPending, profileCount, vehicleCount, kycCount, bankCount, imageCount),
              const SizedBox(height: 16),

              Row(
                children: [
                  Text(
                    "REQUEST CATEGORIES",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              _buildRequestTile(
                context: context,
                index: "1",
                title: "Profile Detail Updates",
                icon: Icons.manage_accounts_rounded,
                targetPage: const ProfileUpdateRequests(),
                count: profileCount,
                accentColor: Colors.blue,
              ),
              const SizedBox(height: 10),

              _buildRequestTile(
                context: context,
                index: "2",
                title: "Profile Image Approvals",
                icon: Icons.account_circle_rounded,
                targetPage: const ProfileImageRequests(),
                count: imageCount,
                accentColor: Colors.indigo,
              ),
              const SizedBox(height: 10),

              _buildRequestTile(
                context: context,
                index: "3",
                title: "Vehicle Change Requests",
                icon: Icons.published_with_changes_rounded,
                targetPage: const VehicleChangeRequests(),
                count: vehicleCount,
                accentColor: Colors.amber.shade800,
              ),
              const SizedBox(height: 10),

              _buildRequestTile(
                context: context,
                index: "4",
                title: "KYC Profile Verifications",
                icon: Icons.gpp_good_rounded,
                targetPage: const KYCVerificationRequests(),
                count: kycCount,
                accentColor: Colors.purple.shade700,
              ),
              const SizedBox(height: 10),

              _buildRequestTile(
                context: context,
                index: "5",
                title: "Bank Account Updates",
                icon: Icons.account_balance_rounded,
                targetPage: const BankAccountDetailsChangeRequests(),
                count: bankCount,
                accentColor: Colors.teal.shade700,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(int total, int profileCount, int vehicleCount, int kycCount, int bankCount, int imageCount) {
    final bool hasRequests = total > 0;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: hasRequests
              ? [const Color(0xff1B2735), const Color(0xff2C5364)]
              : [const Color(0xff11998e), const Color(0xff38ef7d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (hasRequests ? const Color(0xff1B2735) : Colors.green).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasRequests ? "Action Required" : "All Caught Up!",
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Total Pending Requests",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$total",
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            if (hasRequests) ...[
              const SizedBox(height: 14),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildSubCountItem("Details", profileCount),
                    _buildSubCountItem("Images", imageCount),
                    _buildSubCountItem("Vehicles", vehicleCount),
                    _buildSubCountItem("KYC", kycCount),
                    _buildSubCountItem("Bank", bankCount),
                  ],
                ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSubCountItem(String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
        ),
        Text(
          "$count",
          style: TextStyle(
            color: count > 0 ? Colors.amberAccent : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestTile({
    required BuildContext context,
    required String index,
    required String title,
    required IconData icon,
    required Widget targetPage,
    required int count,
    required Color accentColor,
  }) {
    final bool isActionNeeded = count > 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$index.",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
          ],
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff1B2735)),
        ),
        subtitle: Text(
          isActionNeeded ? "$count items waiting review" : "No pending items",
          style: TextStyle(color: isActionNeeded ? Colors.red.shade400 : Colors.grey, fontSize: 11, fontWeight: isActionNeeded ? FontWeight.w500 : FontWeight.normal),
        ),
        trailing: isActionNeeded
            ? Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "$count PENDING",
            style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        )
            : const CircleAvatar(
          radius: 12,
          backgroundColor: Color(0xffE8F5E9),
          child: Icon(Icons.check_rounded, color: Colors.green, size: 14),
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => targetPage)),
      ),
    );
  }
}