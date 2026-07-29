import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_admin_dashboard/core/providers/member_provider.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/driver_profile_dialog.dart';

class NewMembersPanel extends StatefulWidget {
  final VoidCallback onBack;
  const NewMembersPanel({super.key, required this.onBack});

  @override
  State<NewMembersPanel> createState() => _NewMembersPanelState();
}

class _NewMembersPanelState extends State<NewMembersPanel> {
  String _searchQuery = '';

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  bool _isAcknowledgingAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MemberProvider>(
        context,
        listen: false,
      ).startListeningToMembers();
    });
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  Future<void> _markAsViewed(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('member').doc(docId).update({
        'adminViewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error marking as viewed: $e");
    }
  }

  Future<void> _acknowledgeAll(List<Map<String, dynamic>> unviewedMembers) async {
    setState(() => _isAcknowledgingAll = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var member in unviewedMembers) {
        final docId = member['doc_id'] as String?;
        if (docId != null) {
          final docRef = FirebaseFirestore.instance.collection('member').doc(docId);
          batch.update(docRef, {'adminViewedAt': FieldValue.serverTimestamp()});
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error acknowledging all: $e");
    } finally {
      if (mounted) setState(() => _isAcknowledgingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberProvider = Provider.of<MemberProvider>(context);
    final allMembers = memberProvider.allMembersList;

    // Filter by search query first
    final filteredMembers = allMembers.where((driver) {
      final name = (driver['fullName'] ?? '').toString().toLowerCase();
      final mobile = (driver['mobile'] ?? '').toString().toLowerCase();
      final vehicleNo = (driver['vehicleNumber'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || mobile.contains(query) || vehicleNo.contains(query);
    }).toList();

    // Split into Unviewed and Recently Viewed
    final List<Map<String, dynamic>> unviewedMembers = [];
    final List<Map<String, dynamic>> recentlyViewedMembers = [];

    final now = DateTime.now();
    for (var driver in filteredMembers) {
      final adminViewedAt = driver['adminViewedAt'];
      if (adminViewedAt == null) {
        unviewedMembers.add(driver);
      } else if (adminViewedAt is Timestamp) {
        final viewedDate = adminViewedAt.toDate();
        if (now.difference(viewedDate).inDays <= 3) {
          recentlyViewedMembers.add(driver);
        }
      }
    }

    // Sort unviewed by creation if possible, or just leave as is
    final List<dynamic> combinedList = [
      if (unviewedMembers.isNotEmpty) 'HEADER_UNVIEWED',
      ...unviewedMembers,
      if (recentlyViewedMembers.isNotEmpty) 'HEADER_RECENTLY_VIEWED',
      ...recentlyViewedMembers,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.black87),
                  onPressed: widget.onBack,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Members Tracking',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Acknowledge newly registered drivers. Viewed profiles clear after 3 days.',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Bar & Acknowledge All
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: const TextStyle(fontSize: 11),
                    decoration: InputDecoration(
                      hintText: 'Search by Name, Mobile, Vehicle...',
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 16),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade200)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: unviewedMembers.isEmpty ? Colors.grey.shade300 : const Color(0xFF059669),
                    foregroundColor: unviewedMembers.isEmpty ? Colors.grey : Colors.white,
                    minimumSize: const Size(140, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: (unviewedMembers.isEmpty || _isAcknowledgingAll) ? null : () => _acknowledgeAll(unviewedMembers),
                  icon: _isAcknowledgingAll 
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text(
                    'Acknowledge All',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Table
            Expanded(
              child: memberProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A), strokeWidth: 2.5))
                  : combinedList.isEmpty
                  ? const Center(child: Text('No new members found.', style: TextStyle(color: Colors.grey, fontSize: 12)))
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Scrollbar(
                          controller: _horizontalController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          child: SingleChildScrollView(
                            controller: _horizontalController,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: 800,
                              child: Column(
                                children: [
                                  // Header Row
                                  Container(
                                    height: 34,
                                    color: const Color(0xFFF8FAFC),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: const Row(
                                      children: [
                                        SizedBox(width: 50, child: Text('Sr No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E3A8A)))),
                                        SizedBox(width: 100, child: Text('Member Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E3A8A)))),
                                        SizedBox(width: 200, child: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E3A8A)))),
                                        SizedBox(width: 120, child: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E3A8A)))),
                                        SizedBox(width: 120, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E3A8A)))),
                                        SizedBox(width: 150, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E3A8A)))),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                                  // Vertical List rows
                                  Expanded(
                                    child: Scrollbar(
                                      controller: _verticalController,
                                      thumbVisibility: true,
                                      trackVisibility: true,
                                      child: ListView.builder(
                                        controller: _verticalController,
                                        itemCount: combinedList.length,
                                        physics: const BouncingScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          final item = combinedList[index];

                                          if (item is String) {
                                            bool isUnviewed = item == 'HEADER_UNVIEWED';
                                            return Container(
                                              height: 30,
                                              color: isUnviewed ? Colors.blue.shade50 : Colors.grey.shade100,
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                isUnviewed ? 'UNVIEWED NEW MEMBERS (${unviewedMembers.length})' : 'RECENTLY VIEWED (Last 3 days)',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                  color: isUnviewed ? Colors.blue.shade800 : Colors.grey.shade700,
                                                ),
                                              ),
                                            );
                                          }

                                          final driver = item as Map<String, dynamic>;
                                          final bool isAcknowledged = driver['adminViewedAt'] != null;
                                          final String profileStatusStr = (driver['profile_status'] ?? '').toString().toUpperCase();
                                          final bool isActive = profileStatusStr == 'ACTIVE MEMBER';

                                          return Container(
                                            height: 65,
                                            decoration: const BoxDecoration(
                                              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 50,
                                                  child: Text('${index + 1}'.padLeft(2, '0'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.grey)),
                                                ),
                                                SizedBox(
                                                  width: 100,
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 18,
                                                        backgroundColor: Colors.blue.shade50,
                                                        backgroundImage: driver['profileImageUrl'] != null && driver['profileImageUrl'].toString().isNotEmpty
                                                            ? NetworkImage(driver['profileImageUrl'].toString())
                                                            : null,
                                                        child: (driver['profileImageUrl'] == null || driver['profileImageUrl'].toString().isEmpty)
                                                            ? Text(
                                                                ((driver['firstName'] ?? '').toString().trim().isNotEmpty ? (driver['firstName'] ?? '').toString().trim().substring(0, 1) : ((driver['fullName'] ?? '').toString().trim().isNotEmpty ? (driver['fullName'] ?? '').toString().trim().substring(0, 1) : 'D')).toUpperCase(),
                                                                style: TextStyle(color: Colors.blue.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                                                              )
                                                            : null,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(driver['membershipNo'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 9, color: Colors.grey)),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 200,
                                                  child: Text(driver['fullName'] ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                                                ),
                                                SizedBox(
                                                  width: 120,
                                                  child: Text(driver['mobile'] ?? '-', style: const TextStyle(fontSize: 11)),
                                                ),
                                                SizedBox(
                                                  width: 120,
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Tooltip(
                                                      message: isActive ? 'Active Member' : 'Inactive Member',
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          isActive ? 'ACTIVE' : 'INACTIVE',
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(color: isActive ? Colors.green.shade700 : Colors.red.shade700, fontSize: 8, fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 150,
                                                  child: Row(
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(Icons.visibility_rounded, color: Color(0xFF1E3A8A), size: 16),
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                                        onPressed: () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) => DriverProfileDialog(driver: driver),
                                                          );
                                                        },
                                                      ),
                                                      if (!isAcknowledged)
                                                        Padding(
                                                          padding: const EdgeInsets.only(left: 8.0),
                                                          child: ElevatedButton.icon(
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: const Color(0xFF10B981),
                                                              foregroundColor: Colors.white,
                                                              minimumSize: const Size(60, 24),
                                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                                            ),
                                                            onPressed: () {
                                                              if (driver['doc_id'] != null) {
                                                                _markAsViewed(driver['doc_id']);
                                                              }
                                                            },
                                                            icon: const Icon(Icons.check_rounded, size: 12),
                                                            label: const Text('OK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
