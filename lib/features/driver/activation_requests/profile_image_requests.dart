import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:aiaprtd_admin_dashboard/core/utils/notification_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:crop_image/crop_image.dart';
import 'package:aiaprtd_admin_dashboard/core/services/history_service.dart';

class ProfileImageRequests extends StatelessWidget {
  const ProfileImageRequests({super.key});

  Future<void> _approveRequest(
    BuildContext context,
    String docId,
    String membershipNo,
    String newImageUrl,
  ) async {
    try {
      // 1. Update the member document
      await FirebaseFirestore.instance
          .collection('member')
          .doc(membershipNo)
          .update({'profileImageUrl': newImageUrl});

      // 2. Update the request status
      await FirebaseFirestore.instance
          .collection('profile_image_requests')
          .doc(docId)
          .update({
            'status': 'approved',
            'approvedAt': FieldValue.serverTimestamp(),
          });

      // 3. Log History
      await NotificationHelper.sendNotification(
          membershipNo: membershipNo,
          title: 'Profile Image Approved',
          body: 'Your profile image has been approved!',
        );

        await HistoryService.logActivationAction(
        type: 'PROFILE_IMAGE_UPDATE',
        membershipNo: membershipNo,
        status: 'approved',
        requestData: {'newImageUrl': newImageUrl},
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile image approved successfully."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cropAndApproveRequest(
    BuildContext context,
    String docId,
    String membershipNo,
    String imageUrl,
  ) async {
    final controller = CropController(
      aspectRatio: 1,
      defaultCrop: const Rect.fromLTRB(0.1, 0.1, 0.9, 0.9),
    );

    Uint8List? imageBytes;
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        imageBytes = response.bodyBytes;
      } else {
        throw Exception("Failed to load image from URL");
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error downloading image: $e")));
      }
      return;
    }

    if (!context.mounted) return;

    final croppedBytes = await showDialog<Uint8List?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Crop Face"),
          content: SizedBox(
            width: 400,
            height: 400,
            child: CropImage(
              controller: controller,
              image: Image.memory(imageBytes!),
              paddingSize: 25.0,
              alwaysMove: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final bitmap = await controller.croppedBitmap();
                final byteData = await bitmap.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                if (byteData != null) {
                  final bytes = byteData.buffer.asUint8List();
                  Navigator.pop(ctx, bytes);
                }
              },
              child: const Text("Crop & Save"),
            ),
          ],
        );
      },
    );

    if (croppedBytes != null && context.mounted) {
      // Show a loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final fileName =
            '${membershipNo}_${DateTime.now().millisecondsSinceEpoch}.png';
        final ref = FirebaseStorage.instance.ref().child(
          'member_selfies/$fileName',
        );
        await ref.putData(
          croppedBytes,
          SettableMetadata(contentType: 'image/png'),
        );
        final newUrl = await ref.getDownloadURL();

        if (!context.mounted) return;
        Navigator.pop(context); // close loading dialog

        await _approveRequest(context, docId, membershipNo, newUrl);
      } catch (e) {
        if (!context.mounted) return;
        Navigator.pop(context); // close loading dialog

        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text("Upload Error"),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _rejectRequest(
    BuildContext context,
    String docId,
    String membershipNo,
  ) async {
    final List<String> rejectReasons = [
      "Face is not clearly visible",
      "Image is too dark or blurry",
      "Not a real/live photo",
      "Wearing sunglasses or face is covered",
      "Other (Invalid format)",
    ];
    int selectedIndex = 0;
    
    String? reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Select Rejection Reason"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: rejectReasons.asMap().entries.map((entry) {
                  return RadioListTile<int>(
                    title: Text(entry.value),
                    value: entry.key,
                    groupValue: selectedIndex,
                    onChanged: (int? value) {
                      setState(() => selectedIndex = value!);
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, rejectReasons[selectedIndex]);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Reject", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (reason != null) {
      try {
        await FirebaseFirestore.instance
            .collection('profile_image_requests')
            .doc(docId)
            .update({
              'status': 'rejected',
              'rejectReason': reason,
              'rejectedAt': FieldValue.serverTimestamp(),
            });

        await NotificationHelper.sendNotification(
          membershipNo: membershipNo,
          title: "Profile Image Rejected",
          body: "Your profile image was rejected. Reason: $reason",
        );

        await NotificationHelper.sendNotification(
          membershipNo: membershipNo,
          title: 'Profile Image Approved',
          body: 'Your profile image has been approved!',
        );

        await HistoryService.logActivationAction(
          type: 'PROFILE_IMAGE_UPDATE',
          membershipNo: membershipNo,
          status: 'rejected',
          requestData: {'reason': reason},
          remarks: reason,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Request rejected."), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Profile Image Approvals",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xff1B2735),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xff1B2735),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('profile_image_requests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final docs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final String membershipNo = data['membershipNo'] ?? 'Unknown';
              final String newImageUrl = data['newImageUrl'] ?? '';

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: newImageUrl.isNotEmpty
                          ? Image.network(newImageUrl, fit: BoxFit.cover)
                          : Container(
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            membershipNo,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.red,
                                ),
                                onPressed: () => _rejectRequest(
                                  context,
                                  doc.id,
                                  membershipNo,
                                ),
                                tooltip: "Reject",
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.crop_rounded,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _cropAndApproveRequest(
                                  context,
                                  doc.id,
                                  membershipNo,
                                  newImageUrl,
                                ),
                                tooltip: "Crop & Approve",
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green,
                                ),
                                onPressed: () => _approveRequest(
                                  context,
                                  doc.id,
                                  membershipNo,
                                  newImageUrl,
                                ),
                                tooltip: "Approve As Is",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 80,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "All Caught Up!",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "No pending profile images to review.",
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
