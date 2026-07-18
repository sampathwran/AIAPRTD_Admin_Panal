import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_admin_dashboard/core/providers/member_provider.dart';
import 'package:aiaprtd_admin_dashboard/core/providers/profile_image_provider.dart';
import 'package:aiaprtd_admin_dashboard/core/utils/status_helpers.dart';

class TotalMembersPanel extends StatefulWidget {
  final VoidCallback onBack;
  const TotalMembersPanel({super.key, required this.onBack});

  @override
  State<TotalMembersPanel> createState() => _TotalMembersPanelState();
}

class _TotalMembersPanelState extends State<TotalMembersPanel> {
  String _searchQuery = '';

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileImageProvider>(
        context,
        listen: false,
      ).startListeningToProfileImages();
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

  @override
  Widget build(BuildContext context) {
    final memberProvider = Provider.of<MemberProvider>(context);
    final profileImageProvider = Provider.of<ProfileImageProvider>(context);
    final allMembers = memberProvider.allMembersList;

    final filteredMembers = allMembers.where((driver) {
      final name = (driver['fullName'] ?? '').toString().toLowerCase();
      final mobile = (driver['mobile'] ?? '').toString().toLowerCase();
      final vehicleNo = (driver['vehicleNumber'] ?? '')
          .toString()
          .toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) ||
          mobile.contains(query) ||
          vehicleNo.contains(query);
    }).toList();

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
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 14,
                    color: Colors.black87,
                  ),
                  onPressed: widget.onBack,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Registered Members',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Manage and monitor all registered driver profiles',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Bar & Export CSV
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: const TextStyle(fontSize: 11),
                    decoration: InputDecoration(
                      hintText: 'Search by Name, Mobile, Vehicle...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.grey,
                        size: 16,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(110, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () {
                    // Export CSV logic
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text(
                    'Export CSV',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Ultra Scrollable Table Canvas
            Expanded(
              child: memberProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E3A8A),
                        strokeWidth: 2.5,
                      ),
                    )
                  : filteredMembers.isEmpty
                  ? const Center(
                      child: Text(
                        'No registered members found.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    )
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
                              width: 700,
                              child: Column(
                                children: [
                                  // Header Row
                                  Container(
                                    height: 34,
                                    color: const Color(0xFFF8FAFC),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: const Row(
                                      children: [
                                        SizedBox(
                                          width: 50,
                                          child: Text(
                                            'Sr No',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: Color(0xFF1E3A8A),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 100,
                                          child: Text(
                                            'Member Info',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: Color(0xFF1E3A8A),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 200,
                                          child: Text(
                                            'Full Name',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: Color(0xFF1E3A8A),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: Text(
                                            'Mobile',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: Color(0xFF1E3A8A),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 160,
                                          child: Text(
                                            'Status',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: Color(0xFF1E3A8A),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 50,
                                          child: Text(
                                            'Actions',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: Color(0xFF1E3A8A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFE2E8F0),
                                  ),

                                  // Vertical List rows
                                  Expanded(
                                    child: Scrollbar(
                                      controller: _verticalController,
                                      thumbVisibility: true,
                                      trackVisibility: true,
                                      child: ListView.builder(
                                        controller: _verticalController,
                                        itemCount: filteredMembers.length,
                                        physics: const BouncingScrollPhysics(),
                                        itemExtent: 52,
                                        itemBuilder: (context, index) {
                                          final driver = filteredMembers[index];
                                          final statusResult = calculateMemberStatus(driver);
                                          final bool isActive = statusResult['isActive'] == true;
                                          final String inactiveReason = statusResult['reason'] ?? '';
                                          final String statusText = isActive 
                                              ? 'ACTIVE MEMBER' 
                                              : (inactiveReason.isNotEmpty ? 'INACTIVE: $inactiveReason' : 'INACTIVE MEMBER');

                                          // 💡 FIXED: මෙතන තිබුණු Bracket issues සියල්ලම ක්ලීන් කරලා සම්පූර්ණ Row එක පිළිවෙලට හැදුවා මචං
                                          return Container(
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Color(0xFFF1F5F9),
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 50,
                                                  child: Text(
                                                    '${index + 1}'.padLeft(2, '0'),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 11,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 100,
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 12,
                                                        backgroundColor: Colors.blue.shade50,
                                                        backgroundImage: profileImageProvider.profileImages[driver['membershipNo']] != null
                                                            ? NetworkImage(profileImageProvider.profileImages[driver['membershipNo']]!)
                                                            : null,
                                                        child: profileImageProvider.profileImages[driver['membershipNo']] == null
                                                            ? Text(
                                                                ((driver['firstName'] ?? '').toString().trim().isNotEmpty ? (driver['firstName'] ?? '').toString().trim().substring(0, 1) : ((driver['fullName'] ?? '').toString().trim().isNotEmpty ? (driver['fullName'] ?? '').toString().trim().substring(0, 1) : 'D')).toUpperCase(),
                                                                style: TextStyle(
                                                                  color: Colors.blue.shade800,
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              )
                                                            : null,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        driver['membershipNo'] ?? '-',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 9,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 200,
                                                  child: Text(
                                                    driver['fullName'] ?? 'Unknown',
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 120,
                                                  child: Text(
                                                    driver['mobile'] ?? '-',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 160,
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Tooltip(
                                                      message: isActive 
                                                          ? 'Active Member' 
                                                          : inactiveReason.isNotEmpty 
                                                              ? inactiveReason 
                                                              : 'Inactive Member',
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 6,
                                                              vertical: 3,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: isActive
                                                              ? Colors
                                                                    .green
                                                                    .shade50
                                                              : Colors
                                                                    .red
                                                                    .shade50,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          statusText,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(
                                                            color: isActive
                                                                ? Colors.green.shade700
                                                                : Colors.red.shade700,
                                                            fontSize: 8,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 50,
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: IconButton(
                                                      icon: const Icon(
                                                        Icons
                                                            .visibility_rounded,
                                                        color: Color(
                                                          0xFF1E3A8A,
                                                        ),
                                                        size: 16,
                                                      ),
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(),
                                                      onPressed: () {
                                                        _showDriverDetailsDialog(
                                                          context,
                                                          driver,
                                                        );
                                                      },
                                                    ),
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

  void _showDriverDetailsDialog(
    BuildContext context,
    Map<String, dynamic> driver,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: SelectionArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        color: Color(0xFF1E3A8A),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          driver['fullName'] ?? 'Driver Profile',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _detailRow('Membership No:', driver['membershipNo']),
                  _detailRow('NIC Number:', driver['nic']),
                  _detailRow('Mobile:', driver['mobile']),
                  _detailRow('Email:', driver['user_email']),
                  _detailRow('Gender:', driver['gender']),
                  _detailRow('DOB:', driver['dob']),
                  _detailRow('Religion:', driver['religion']),
                  _detailRow('Address:', driver['address']),
                  const Divider(height: 20),
                  _detailRow('Vehicle Model:', driver['vehicleType']),
                  _detailRow('Vehicle Number:', driver['vehicleNumber']),
                  _detailRow('Primary Category:', driver['primaryVehicle']),
                  _detailRow('Rating:', '⭐ ${driver['rating'] ?? 5}'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value?.toString() ?? '-',
              style: const TextStyle(color: Colors.black87, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
