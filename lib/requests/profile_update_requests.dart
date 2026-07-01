import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileUpdateRequests extends StatelessWidget {
  const ProfileUpdateRequests({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Profile Update Requests",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xff1B2735)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xff1B2735), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 💡 🎯 FIXED: අලුත් කලෙක්ෂන් එකට (profile_image_requests) පොයින්ට් කළා
        stream: FirebaseFirestore.instance
            .collection('profile_image_requests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_box_rounded, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text(
                    "No pending profile updates",
                    style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return RequestCard(
                docId: docs[index].id,
                data: data,
              );
            },
          );
        },
      ),
    );
  }
}

class RequestCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const RequestCard({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final String imageUrl = data['newImageUrl']?.toString() ?? '';
    final String membershipNo = data['membershipNo']?.toString() ?? 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showFullImage(context, imageUrl),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xff1B2735).withValues(alpha: 0.1), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey.shade100,
                          backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                          child: imageUrl.isEmpty ? Icon(Icons.person, color: Colors.grey.shade600, size: 28) : null,
                        ),
                      ),
                      if (imageUrl.isNotEmpty)
                        const CircleAvatar(
                          radius: 10,
                          backgroundColor: Color(0xff1B2735),
                          child: Icon(Icons.fullscreen_rounded, size: 12, color: Colors.white),
                        )
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        membershipNo, // 💡 ID එක ප්‍රධාන කරලා පෙන්නුවා
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff1B2735)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Waiting for approval",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.orange.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xff1B2735),
                    side: BorderSide(color: const Color(0xff1B2735).withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.zoom_in_rounded, size: 16),
                  label: const Text("View Image", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => _showFullImage(context, imageUrl),
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.cancel_rounded, size: 16),
                    label: const Text("Reject", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _promptReject(context, membershipNo),
                  ),
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text("Approve", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () => _handleApproval(context, membershipNo, imageUrl),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 10, right: 10,
              child: IconButton(
                icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white, size: 18)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // 🔴 🎯 PRE-DEFINED REJECT REASONS LOGIC
  // ==========================================================
  Future<void> _promptReject(BuildContext context, String membershipNo) async {
    final List<String> rejectReasons = [
      "Face is not clearly visible",
      "Image is too dark or blurry",
      "Not a real/live photo (e.g., photo of a photo)",
      "Wearing sunglasses or face is covered",
      "Other (Invalid format)"
    ];

    int selectedIndex = 0;

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text("Select Rejection Reason", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              // 💡 FIXED: අලුත් Flutter අප්ඩේට් එකට ගැලපෙන්න RadioGroup එකක් පාවිච්චි කළා
              content: RadioGroup<int>(
                groupValue: selectedIndex,
                onChanged: (int? value) {
                  setState(() => selectedIndex = value!);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: rejectReasons.asMap().entries.map((entry) {
                    return RadioListTile<int>(
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.red,
                      title: Text(entry.value, style: const TextStyle(fontSize: 14)),
                      value: entry.key,
                      // 💡 groupValue සහ onChanged දැන් මෙතනට ලියන්න අවශ්‍ය නෑ! (ඒවා RadioGroup එකට දුන්නා)
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.pop(context, rejectReasons[selectedIndex]);
                  },
                  child: const Text("Confirm Reject"),
                ),
              ],
            );
          }
      ),
    );

    if (reason != null && context.mounted) {
      await _handleRejection(context, membershipNo, reason);
    }
  }

  // ==========================================================
  // ✅ 🎯 APPROVAL: Update Request & Member Profile
  // ==========================================================
  Future<void> _handleApproval(BuildContext context, String membershipNo, String imageUrl) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      DocumentReference requestRef = FirebaseFirestore.instance.collection('profile_image_requests').doc(docId);
      DocumentReference memberRef = FirebaseFirestore.instance.collection('member').doc(membershipNo);

      // 1. Request එක Approve කරනවා
      batch.update(requestRef, {
        'status': 'approved',
        'actionDate': FieldValue.serverTimestamp(),
      });

      // 2. Member ගේ Profile එකට අලුත් Image එක දානවා
      batch.update(memberRef, {
        'profileImageUrl': imageUrl,
        'imageRequestStatus': 'approved',
      });

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Image Approved Successfully! ✅"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // ==========================================================
  // ❌ 🎯 REJECTION: Update Request & Send Notification
  // ==========================================================
  Future<void> _handleRejection(BuildContext context, String membershipNo, String reason) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      DocumentReference requestRef = FirebaseFirestore.instance.collection('profile_image_requests').doc(docId);
      DocumentReference memberRef = FirebaseFirestore.instance.collection('member').doc(membershipNo);
      DocumentReference notificationRef = FirebaseFirestore.instance.collection('notifications').doc();

      // 1. Request එක Reject කරනවා
      batch.update(requestRef, {
        'status': 'rejected',
        'rejectReason': reason,
        'actionDate': FieldValue.serverTimestamp(),
      });

      // 2. Member එකේ Status එක අප්ඩේට් කරනවා
      batch.update(memberRef, {
        'imageRequestStatus': 'rejected',
        'imageRejectReason': reason,
      });

      // 3. යූසර්ට Notification එකක් යවනවා
      batch.set(notificationRef, {
        'membershipNo': membershipNo,
        'title': 'Profile Photo Rejected ❌',
        'body': 'Your recent profile photo update was rejected. Reason: $reason. Please upload a clear photo.',
        'type': 'profile_update_rejected',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request Rejected & Notification Sent!"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }
}