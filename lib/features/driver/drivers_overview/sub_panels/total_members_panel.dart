import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_admin_dashboard/core/providers/member_provider.dart';
import 'package:aiaprtd_admin_dashboard/core/utils/status_helpers.dart';
import 'package:aiaprtd_admin_dashboard/core/utils/csv_exporter.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/driver_profile_dialog.dart';

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Registered Members',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Manage and monitor all registered driver profiles',
                        style: TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
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
                    if (filteredMembers.isEmpty) return;

                    final StringBuffer csvData = StringBuffer();
                    // Headers
                    csvData.writeln(
                        '"Membership No","Full Name","Mobile","Vehicle No","Vehicle Type","Status","Join Date"');

                    for (final member in filteredMembers) {
                      final mNo = member['membershipNo']?.toString() ?? '-';
                      final name = member['fullName']?.toString() ?? '-';
                      final mobile = member['mobile']?.toString() ?? '-';
                      final vNo = member['vehicleNumber']?.toString() ?? '-';
                      final vType = member['vehicleType']?.toString() ?? '-';

                      final statusResult = calculateMemberStatus(member);
                      final isActive = statusResult['isActive'] == true;
                      final statusStr = isActive ? 'ACTIVE' : 'INACTIVE';

                      String dateJoined = '-';
                      if (member['createdAt'] != null) {
                        final ts = member['createdAt'] as Timestamp;
                        final date = ts.toDate();
                        dateJoined = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                      }

                      // Escape quotes in fields
                      String escape(String value) {
                        final escaped = value.replaceAll('"', '""');
                        return '"$escaped"';
                      }

                      csvData.writeln(
                          "${escape(mNo)},${escape(name)},${escape(mobile)},${escape(vNo)},${escape(vType)},${escape(statusStr)},${escape(dateJoined)}");
                    }

                    exportToCsv('AIAPRTD_Members.csv', csvData.toString());

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('CSV Exported successfully!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text(
                    'Export CSV',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(130, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () {
                    if (filteredMembers.isEmpty) return;

                    final StringBuffer csvData = StringBuffer();
                    // Headers
                    csvData.writeln(
                        '"Membership No","Full Name","NIC","Mobile","Email","Gender","DOB","Address","Religion","Status","Join Date","Vehicle Category","Vehicle Number","Make & Model","Color","Fuel Type","Current Month Paid","Last Paid Month"');

                    for (final member in filteredMembers) {
                      final mNo = member['membershipNo']?.toString() ?? '-';
                      final name = member['fullName']?.toString() ?? member['firstName']?.toString() ?? '-';
                      final nic = member['nic']?.toString() ?? '-';
                      final mobile = member['mobile']?.toString() ?? '-';
                      final email = member['email']?.toString() ?? '-';
                      final gender = member['gender']?.toString() ?? '-';
                      final dob = member['dob']?.toString() ?? '-';
                      final address = member['address']?.toString() ?? '-';
                      final religion = member['religion']?.toString() ?? '-';
                      
                      final statusResult = calculateMemberStatus(member);
                      final isActive = statusResult['isActive'] == true;
                      final statusStr = isActive ? 'ACTIVE' : 'INACTIVE';

                      String dateJoined = '-';
                      if (member['createdAt'] != null) {
                        try {
                          final ts = member['createdAt'] as Timestamp;
                          final date = ts.toDate();
                          dateJoined = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                        } catch (_) {}
                      }

                      // Vehicle details
                      final currentVehicle = member['currentVehicle'] as Map<String, dynamic>? ?? {};
                      final vDetails = currentVehicle['details'] as Map<String, dynamic>? ?? {};
                      final vCategory = vDetails['category']?.toString() ?? '-';
                      final vNo = vDetails['number']?.toString() ?? '-';
                      final vMakeModel = "${vDetails['make'] ?? ''} ${vDetails['model'] ?? ''}".trim();
                      final vColor = vDetails['color']?.toString() ?? '-';
                      final vFuel = vDetails['fuelType']?.toString() ?? '-';

                      // Payment details
                      final feeCheck = checkMembershipFeeStatus(member);
                      final currentPaid = feeCheck['hasPaidForCurrentMonth'] == true ? 'Yes' : 'No';
                      
                      String lastPaidMonth = '-';
                      final paymentHistory = member['payment_history'] as List<dynamic>? ?? [];
                      if (paymentHistory.isNotEmpty) {
                        for (var p in paymentHistory) {
                          if (p is Map && p['status']?.toString().toLowerCase() == 'paid') {
                             lastPaidMonth = "${p['month']} ${p['year']}";
                             break;
                          }
                        }
                      }

                      // Escape quotes in fields
                      String escape(String value) {
                        if (value.isEmpty) return '""';
                        final escaped = value.replaceAll('"', '""');
                        return '"$escaped"';
                      }

                      csvData.writeln(
                          "${escape(mNo)},${escape(name)},${escape(nic)},${escape(mobile)},${escape(email)},${escape(gender)},${escape(dob)},${escape(address)},${escape(religion)},${escape(statusStr)},${escape(dateJoined)},${escape(vCategory)},${escape(vNo)},${escape(vMakeModel)},${escape(vColor)},${escape(vFuel)},${escape(currentPaid)},${escape(lastPaidMonth)}");
                    }

                    exportToCsv('AIAPRTD_Full_Members_Data.csv', csvData.toString());

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Full CSV Exported successfully!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_for_offline_rounded, size: 16),
                  label: const Text(
                    'Export Full Data',
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
                                        itemExtent: 65,
                                        itemBuilder: (context, index) {
                                          final driver = filteredMembers[index];
                                          final String profileStatusStr =
                                              (driver['profile_status'] ?? '')
                                                  .toString()
                                                  .toUpperCase();
                                          final bool isActive =
                                              profileStatusStr ==
                                              'ACTIVE MEMBER';
                                          final String statusText = isActive
                                              ? 'ACTIVE MEMBER'
                                              : 'INACTIVE MEMBER';

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
                                                    '${index + 1}'.padLeft(
                                                      2,
                                                      '0',
                                                    ),
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
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 18,
                                                        backgroundColor:
                                                            Colors.blue.shade50,
                                                        backgroundImage:
                                                            driver['profileImageUrl'] !=
                                                                    null &&
                                                                driver['profileImageUrl']
                                                                    .toString()
                                                                    .isNotEmpty
                                                            ? NetworkImage(
                                                                driver['profileImageUrl']
                                                                    .toString(),
                                                              )
                                                            : null,
                                                        child:
                                                            (driver['profileImageUrl'] ==
                                                                    null ||
                                                                driver['profileImageUrl']
                                                                    .toString()
                                                                    .isEmpty)
                                                            ? Text(
                                                                ((driver['firstName'] ??
                                                                                '')
                                                                            .toString()
                                                                            .trim()
                                                                            .isNotEmpty
                                                                        ? (driver['firstName'] ??
                                                                                  '')
                                                                              .toString()
                                                                              .trim()
                                                                              .substring(
                                                                                0,
                                                                                1,
                                                                              )
                                                                        : ((driver['fullName'] ??
                                                                                      '')
                                                                                  .toString()
                                                                                  .trim()
                                                                                  .isNotEmpty
                                                                              ? (driver['fullName'] ??
                                                                                        '')
                                                                                    .toString()
                                                                                    .trim()
                                                                                    .substring(
                                                                                      0,
                                                                                      1,
                                                                                    )
                                                                              : 'D'))
                                                                    .toUpperCase(),
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .blue
                                                                      .shade800,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              )
                                                            : null,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        driver['membershipNo'] ??
                                                            '-',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
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
                                                    driver['fullName'] ??
                                                        'Unknown',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            color: isActive
                                                                ? Colors
                                                                      .green
                                                                      .shade700
                                                                : Colors
                                                                      .red
                                                                      .shade700,
                                                            fontSize: 8,
                                                            fontWeight:
                                                                FontWeight.bold,
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
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              DriverProfileDialog(
                                                                driver: driver,
                                                              ),
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
}
