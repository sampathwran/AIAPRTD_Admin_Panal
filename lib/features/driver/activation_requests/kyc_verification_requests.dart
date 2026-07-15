// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:aiaprtd_admin_dashboard/core/services/history_service.dart';

class KYCVerificationRequests extends StatelessWidget {
  const KYCVerificationRequests({super.key});

  // =========================================================================
  // 👑 🎯 THE KING APPROVAL ENGINE: FIRESTORE + WORDPRESS WEB SYNC CALL
  // =========================================================================
  Future<void> _approveKYCRequest({
    required BuildContext context,
    required String membershipNo,
    required Map<String, dynamic>
    updatedKycData, // 💡 ඇඩ්මින් එඩිට් කරපු දත්ත ටික
    required Map<String, dynamic>
    originalItem, // පින්තූර ලින්ක්ස් ටික ගන්න පරණ ඩේටා
    bool isFromSlider = false,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final firestore = FirebaseFirestore.instance;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.deepPurple),
      ),
    );

    try {
      // 1. 💡 'verify_kyc' කලෙක්ෂන් එකේ status එක approved කරනවා
      await firestore.collection('verify_kyc').doc(membershipNo).update({
        'kycApprovalStatus': 'approved',
        'faceKycStatus': 'approved',
        'fullName': updatedKycData['fullName'],
        'nic': updatedKycData['nic'],
        'mobile': updatedKycData['mobile'],
        'address': updatedKycData['address'],
        'dob': updatedKycData['dob'],
        'religion': updatedKycData['religion'],
      });

      // 2. 'member' කලෙක්ෂන් එක අප්ඩේට් කරද්දී Driver Active කරවනවා
      await firestore.collection('member').doc(membershipNo).set({
        'kycApprovalStatus': 'approved',
        'faceKycStatus': 'approved',
        'fullName': updatedKycData['fullName'],
        'nic': updatedKycData['nic'],
        'mobile': updatedKycData['mobile'],
        'address': updatedKycData['address'],
        'dob': updatedKycData['dob'],
        'religion': updatedKycData['religion'],
        'idCardFrontUrl': originalItem['idCardFrontUrl'],
        'idCardBackUrl': originalItem['idCardBackUrl'],
        'faceVerificationUrl': originalItem['faceVerificationUrl'],
        'user_email': originalItem['user_email'],
        'gender': originalItem['gender'] ?? '',
      }, SetOptions(merge: true));

      // 2.5 Log History
      await HistoryService.logActivationAction(
        type: 'KYC_VERIFICATION',
        membershipNo: membershipNo,
        status: 'approved',
        requestData: originalItem,
      );

      // 3. WordPress DB Real-time Sync (ඇඩ්මින් වෙනස් කරපු නමත් වෙබ් එකට යවනවා 🎯)
      final url = Uri.parse(
        'https://aiaprtd.lk/wp-json/aiaprtd-sync/v1/update-profile',
      );
      http
          .post(
            url,
            body: {
              'membership_no': membershipNo,
              'full_name':
                  updatedKycData['fullName'] ?? '', // 👈 අලුතින් එකතු කලා
              'nic': updatedKycData['nic'] ?? '',
              'address': updatedKycData['address'] ?? '',
              'mobile': updatedKycData['mobile'] ?? '',
            },
          )
          .catchError((e) => debugPrint("WP Sync Error (Ignored): $e"));

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (isFromSlider) {
        Navigator.pop(context); // Close Side Inspector Panel
      }

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text("KYC Profile Approved & User Activated! 🎉🚀"),
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Loading dialog එක වහනවා
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("Approve Error: $e ❌"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // =========================================================================
  // ❌ 🎯 REJECT ENGINE (WITH ASYNC CONTEXT FIX)
  // =========================================================================
  Future<void> _rejectKYCRequest(
    BuildContext context,
    String membershipNo, {
    bool isFromSlider = false,
  }) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 'verify_kyc' එකෙන් Reject කිරීම
      await FirebaseFirestore.instance
          .collection('verify_kyc')
          .doc(membershipNo)
          .update({
            'kycApprovalStatus': 'rejected',
            'faceKycStatus': 'rejected',
          });

      // User හට ආයෙත් Form එක පිරවීමට අවස්ථාව දීම
      await FirebaseFirestore.instance
          .collection('member')
          .doc(membershipNo)
          .set({
            'kycApprovalStatus': 'rejected',
            'faceKycStatus': 'rejected',
          }, SetOptions(merge: true));

      // Log History
      await HistoryService.logActivationAction(
        type: 'KYC_VERIFICATION',
        membershipNo: membershipNo,
        status: 'rejected',
        requestData: {'membershipNo': membershipNo},
      );

      if (!context.mounted) return;
      if (isFromSlider) Navigator.pop(context); // Side Panel එක වහනවා

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text("Request Rejected. Driver can submit again! ❌"),
          backgroundColor: Colors.amber,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F9),
      appBar: AppBar(
        title: const Text(
          "Biometric KYC Desk",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('verify_kyc')
            .where('kycApprovalStatus', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.gpp_good_outlined,
                    size: 70,
                    color: Colors.green.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "All Verification Queues Clear!",
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 500,
              mainAxisExtent: 210,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (context, index) {
              final item = docs[index].data() as Map<String, dynamic>;
              final String docId = docs[index].id;
              final String name = item['fullName']?.toString() ?? 'Anonymous Member';
              final String mobile = item['mobile']?.toString() ?? 'N/A';
              final String nic = item['nic']?.toString() ?? 'N/A';
              final String faceUrl = item['faceVerificationUrl']?.toString() ?? '';
              final String idFrontUrl = item['idCardFrontUrl']?.toString() ?? '';

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          _openRequestSideInspector(context, docId, item),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildModernPreview(faceUrl, isCircle: true),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      _buildStatusTag(
                                        Icons.badge_outlined,
                                        "NIC",
                                        nic,
                                        Colors.blueGrey,
                                      ),
                                      const SizedBox(height: 4),
                                      _buildStatusTag(
                                        Icons.phone_outlined,
                                        "Call",
                                        mobile,
                                        Colors.indigo,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildModernPreview(
                                  idFrontUrl,
                                  isCircle: false,
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                const Icon(
                                  Icons.shield_outlined,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "ID: ${docId.substring(0, docId.length > 8 ? 8 : docId.length)}...",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.redAccent,
                                    side: BorderSide(
                                      color: Colors.red.shade100,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _rejectKYCRequest(context, docId),
                                  child: const Text(
                                    "Reject",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                  onPressed: () => _approveKYCRequest(
                                    context: context,
                                    membershipNo: docId,
                                    updatedKycData: item,
                                    originalItem: item,
                                  ),
                                  child: const Text(
                                    "Approve",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildModernPreview(String url, {required bool isCircle}) {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipRRect(
        borderRadius: isCircle
            ? BorderRadius.circular(100)
            : BorderRadius.circular(12),
        child: url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image_outlined,
                  size: 22,
                  color: Colors.grey,
                ),
              )
            : const Icon(
                Icons.image_not_supported_outlined,
                size: 22,
                color: Colors.grey,
              ),
      ),
    );
  }

  Widget _buildStatusTag(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF334155),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 🎨 🛠️ SIDE SLIDE INSPECTOR PANEL (WITH LIVE EDIT CONTROLLERS)
  // =========================================================================
  void _openRequestSideInspector(
    BuildContext context,
    String membershipNo,
    Map<String, dynamic> item,
  ) {
    final nameController = TextEditingController(text: item['fullName']?.toString() ?? '');
    final mobileController = TextEditingController(text: item['mobile']?.toString() ?? '');
    final nicController = TextEditingController(text: item['nic']?.toString() ?? '');
    final dobController = TextEditingController(text: item['dob']?.toString() ?? '');
    final religionController = TextEditingController(
      text: item['religion']?.toString() ?? '',
    );
    final addressController = TextEditingController(
      text: item['address']?.toString() ?? '',
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withValues(alpha: 0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.88,
            constraints: const BoxConstraints(maxWidth: 460),
            height: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(32)),
            ),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 40,
                      left: 20,
                      right: 20,
                      bottom: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Biometric Audit & Edit",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.grey,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildSectionTitle(
                          "VERIFIED IDENTITY CRITERIA (EDITABLE)",
                        ),
                        _buildEditableInfoBox(
                          "Membership Number (Fixed)",
                          TextEditingController(text: membershipNo),
                          Icons.fingerprint_rounded,
                          readOnly: true,
                        ),
                        _buildEditableInfoBox(
                          "Driver Full Name",
                          nameController,
                          Icons.person_outline_rounded,
                        ),
                        _buildEditableInfoBox(
                          "Mobile Number",
                          mobileController,
                          Icons.phone_android_rounded,
                        ),
                        _buildEditableInfoBox(
                          "NIC Card Identifier",
                          nicController,
                          Icons.contact_mail_outlined,
                        ),
                        _buildEditableInfoBox(
                          "Date of Birth",
                          dobController,
                          Icons.calendar_month_outlined,
                        ),
                        _buildEditableInfoBox(
                          "Religion Faith",
                          religionController,
                          Icons.auto_awesome_outlined,
                        ),
                        _buildEditableInfoBox(
                          "Permanent Residence Address",
                          addressController,
                          Icons.map_outlined,
                          maxLines: 2,
                        ),

                        const SizedBox(height: 20),
                        _buildSectionTitle("AI FACE MATCH SELECTION"),
                        const SizedBox(height: 6),
                        _buildModernImageCard(
                          context,
                          "Liveness Capture Image",
                          item['faceVerificationUrl'],
                        ),

                        const SizedBox(height: 20),
                        _buildSectionTitle("OFFICIAL IDENTITY CARDS"),
                        const SizedBox(height: 6),
                        _buildModernImageCard(
                          context,
                          "National ID - Front Side",
                          item['idCardFrontUrl'],
                        ),
                        const SizedBox(height: 12),
                        _buildModernImageCard(
                          context,
                          "National ID - Back Side",
                          item['idCardBackUrl'],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => _rejectKYCRequest(
                              context,
                              membershipNo,
                              isFromSlider: true,
                            ),
                            child: const Text(
                              "Reject Request",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Map<String, dynamic> updatedData = {
                                'fullName': nameController.text.trim(),
                                'mobile': mobileController.text.trim(),
                                'nic': nicController.text.trim(),
                                'dob': dobController.text.trim(),
                                'religion': religionController.text.trim(),
                                'address': addressController.text.trim(),
                              };

                              _approveKYCRequest(
                                context: context,
                                membershipNo: membershipNo,
                                updatedKycData: updatedData,
                                originalItem: item,
                                isFromSlider: true,
                              );
                            },
                            child: const Text(
                              "Approve Profile",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(anim1),
          child: child,
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4F46E5),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildEditableInfoBox(
    String title,
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: readOnly ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: readOnly ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0),
            child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              readOnly: readOnly,
              maxLines: maxLines,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: readOnly
                    ? Colors.grey.shade600
                    : const Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                labelText: title,
                labelStyle: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          if (!readOnly)
            const Icon(Icons.edit_rounded, size: 14, color: Colors.indigo),
        ],
      ),
    );
  }

  Widget _buildModernImageCard(
    BuildContext context,
    String title,
    String? imageUrl,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        if (imageUrl != null && imageUrl.isNotEmpty)
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(10),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      InteractiveViewer(
                        panEnabled: true,
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 0.5,
                        maxScale: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(imageUrl, fit: BoxFit.contain),
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                color: const Color(0xFFF1F5F9),
                width: double.infinity,
                height: 180,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4F46E5),
                        strokeWidth: 2,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                "Document Missing",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
