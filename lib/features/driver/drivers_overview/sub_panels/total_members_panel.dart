import 'dart:html' as html;
import 'database_migration_dialog.dart';
import 'document_migration_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_admin_dashboard/core/providers/member_provider.dart';
import 'package:aiaprtd_admin_dashboard/core/utils/status_helpers.dart';
import 'package:aiaprtd_admin_dashboard/core/utils/member_utils.dart';
import 'package:aiaprtd_admin_dashboard/core/utils/csv_exporter.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/sub_panels/driver_profile_dialog.dart';

class TotalMembersPanel extends StatefulWidget {
  final VoidCallback? onBack;
  const TotalMembersPanel({super.key, this.onBack});

  @override
  State<TotalMembersPanel> createState() => _TotalMembersPanelState();
}

class _TotalMembersPanelState extends State<TotalMembersPanel> {
  String _searchQuery = '';
  int _currentPage = 1;
  final int _itemsPerPage = 50;
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

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

  Future<void> _showAddMemberDialog(BuildContext context) async {
    final TextEditingController _idController = TextEditingController();
    final TextEditingController _firstNameController = TextEditingController();
    final TextEditingController _lastNameController = TextEditingController();
    final TextEditingController _mobileController = TextEditingController();
    final TextEditingController _nicController = TextEditingController();
    bool _isSaving = false;
    bool _isLoadingId = true;

    // Fetch next ID
    try {
      final doc = await FirebaseFirestore.instance.collection('system_config').doc('id_management').get();
      if (doc.exists) {
        final data = doc.data()!;
        String prefix = data['prefix']?.toString() ?? '26';
        int nextAvailable = int.tryParse(data['next_available']?.toString() ?? '0') ?? 0;
        if (nextAvailable == 0) {
          int current = int.tryParse(data['current_value']?.toString() ?? '0') ?? 0;
          nextAvailable = current + 1;
        }
        _idController.text = 'AIAPRTD-$prefix-${nextAvailable.toString().padLeft(4, '0')}';
      } else {
        _idController.text = 'AIAPRTD-26-0000';
      }
    } catch (e) {
      _idController.text = 'AIAPRTD-26-ERROR';
    }
    _isLoadingId = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Member'),
            content: SizedBox(
              width: 400,
              child: _isLoadingId
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _idController,
                          decoration: const InputDecoration(labelText: 'Membership Number (Auto-Generated)', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder()),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _nicController,
                          decoration: const InputDecoration(labelText: 'NIC', border: OutlineInputBorder()),
                        ),
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                onPressed: _isSaving
                    ? null
                    : () async {
                        if (_idController.text.isEmpty || _firstNameController.text.isEmpty || _mobileController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields!'), backgroundColor: Colors.red));
                          return;
                        }

                        setState(() => _isSaving = true);
                        try {
                          String memId = _idController.text.trim();
                          
                          // Save member
                          await FirebaseFirestore.instance.collection('member').doc(memId).set({
                            'membershipNo': memId,
                            'firstName': _firstNameController.text.trim(),
                            'lastName': _lastNameController.text.trim(),
                            'fullName': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
                            'mobile': _mobileController.text.trim(),
                            'mobile_number': _mobileController.text.trim(),
                            'nic': _nicController.text.trim(),
                            'profile_status': 'ACTIVE MEMBER',
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          // Increment counter
                          // No need to increment current_value directly anymore, as the admin should re-scan to find the next empty number.

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member added successfully!'), backgroundColor: Colors.green));
                          }
                        } catch (e) {
                          setState(() => _isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        }
                      },
                child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save Member'),
              ),
            ],
          );
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final memberProvider = Provider.of<MemberProvider>(context);
    final allMembers = memberProvider.allMembersList;

    final filteredMembers = allMembers.where((driver) {
      return matchesSearchQuery(driver, _searchQuery);
    }).toList();

    int totalPages = (filteredMembers.length / _itemsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
    
    // Ensure currentPage is valid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentPage > totalPages) {
        setState(() {
          _currentPage = totalPages;
        });
      }
    });

    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > filteredMembers.length) {
      endIndex = filteredMembers.length;
    }
    
    final paginatedMembers = filteredMembers.sublist(startIndex, endIndex);

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
                if (widget.onBack != null) ...[
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
                ],
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
                        _currentPage = 1;
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
                // NEW: Migrate IDs Button
                ElevatedButton.icon(
                  onPressed: () => _showAddMemberDialog(context),
                  icon: const Icon(Icons.person_add, size: 16, color: Colors.white),
                  label: const Text('Add Member', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Migrate Single Member ID',
                  child: ElevatedButton.icon(
                    onPressed: () => showDocumentMigrationDialog(context),
                    icon: const Icon(Icons.move_up, size: 16, color: Colors.white),
                    label: const Text(
                      'Migrate Single ID',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Full Web Sync Migration',
                  child: ElevatedButton.icon(
                    onPressed: () => showFullDatabaseMigrationDialog(context),
                    icon: const Icon(
                      Icons.sync_problem,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Start Full Migration',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  tooltip: 'Export Options',
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Export Data',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                  onSelected: (value) async {
                    if (filteredMembers.isEmpty) return;
                    await _handleExport(value, filteredMembers);
                  },
                  itemBuilder: (context) => [
                    _buildPopupItem('all', 'All Details', Icons.list_alt),
                    _buildPopupItem(
                      'personal',
                      'Personal Details',
                      Icons.person_outline,
                    ),
                    _buildPopupItem(
                      'vehicle',
                      'Vehicle Details',
                      Icons.directions_car_outlined,
                    ),
                    _buildPopupItem('fee', 'Membership Fee', Icons.payment),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildPaginationControls(totalPages),
            const SizedBox(height: 8),

            // Ultra Scrollable Table Canvas
            Expanded(
              child: memberProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1E3A8A),
                        strokeWidth: 2.5,
                      ),
                    )
                  : paginatedMembers.isEmpty
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
                                        itemCount: paginatedMembers.length,
                                        physics: const BouncingScrollPhysics(),
                                        itemExtent: 65,
                                        itemBuilder: (context, index) {
                                          final driver = paginatedMembers[index];
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

                                          // ðŸ’¡ FIXED: à¶¸à·™à¶­à¶± à¶­à·’à¶¶à·”à¶«à·” Bracket issues à·ƒà·’à¶ºà¶½à·Šà¶½à¶¸ à¶šà·Šà¶½à·“à¶±à·Š à¶šà¶»à¶½à· à·ƒà¶¸à·Šà¶´à·–à¶»à·Šà¶« Row à¶‘à¶š à¶´à·’à·…à·’à·€à·™à¶½à¶§ à·„à·à¶¯à·”à·€à· à¶¸à¶ à¶‚
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
                                                        html.window.history.pushState(null, 'Driver Profile', '/dashboard/driver/total_members?memberId=${driver['uid']}');
                                                        showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              DriverProfileDialog(
                                                                driver: driver,
                                                              ),
                                                        ).then((_) {
                                                          html.window.history.pushState(null, 'Total Members', '/dashboard/driver/total_members');
                                                        });
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

  PopupMenuItem<String> _buildPopupItem(
    String value,
    String text,
    IconData icon,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _handleExport(
    String type,
    List<Map<String, dynamic>> filteredMembers,
  ) async {
    String escape(String value) {
      if (value.isEmpty) return '""';
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }

    String getDateJoined(Map<String, dynamic> member) {
      if (member['createdAt'] != null) {
        try {
          final ts = member['createdAt'] as Timestamp;
          final date = ts.toDate();
          return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        } catch (_) {}
      }
      return '-';
    }

    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preparing export...'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      final StringBuffer csvData = StringBuffer();
      final List<String> idCols = ["Membership No", "Full Name", "NIC"];

      if (type == 'personal') {
        final List<String> columns = [
          ...idCols,
          "Mobile",
          "Email",
          "Gender",
          "DOB",
          "Address",
          "Religion",
          "Status",
          "Join Date",
        ];
        csvData.writeln(columns.map((h) => '"$h"').join(','));

        for (final m in filteredMembers) {
          final mNo = m['membershipNo']?.toString() ?? '-';
          final name =
              m['fullName']?.toString() ?? m['firstName']?.toString() ?? '-';
          final nic = m['nic']?.toString() ?? '-';
          final mobile = m['mobile']?.toString() ?? '-';
          final email = m['email']?.toString() ?? '-';
          final gender = m['gender']?.toString() ?? '-';
          final dob = m['dob']?.toString() ?? '-';
          final address = m['address']?.toString() ?? '-';
          final religion = m['religion']?.toString() ?? '-';

          final statusResult = calculateMemberStatus(m);
          final statusStr = statusResult['isActive'] == true
              ? 'ACTIVE'
              : 'INACTIVE';
          final dateJoined = getDateJoined(m);

          csvData.writeln(
            "${escape(mNo)},${escape(name)},${escape(nic)},${escape(mobile)},${escape(email)},${escape(gender)},${escape(dob)},${escape(address)},${escape(religion)},${escape(statusStr)},${escape(dateJoined)}",
          );
        }
        exportToCsv('AIAPRTD_Personal_Details.csv', csvData.toString());
      } else if (type == 'fee') {
        final Map<String, int> monthToNumber = {
          'january': 1,
          'february': 2,
          'march': 3,
          'april': 4,
          'may': 5,
          'june': 6,
          'july': 7,
          'august': 8,
          'september': 9,
          'october': 10,
          'november': 11,
          'december': 12,
        };

        final Set<String> uniqueMonths = {};
        for (final m in filteredMembers) {
          final paymentHistory = m['payment_history'] as List<dynamic>? ?? [];
          for (var p in paymentHistory) {
            if (p is Map) {
              final mStr = p['month']?.toString().trim() ?? '';
              final yStr = p['year']?.toString().trim() ?? '';
              if (mStr.isNotEmpty && yStr.isNotEmpty) {
                uniqueMonths.add("$mStr $yStr");
              } else if (mStr.isNotEmpty) {
                uniqueMonths.add("$mStr 2026");
              }
            }
          }
        }

        final sortedMonths = uniqueMonths.toList()
          ..sort((a, b) {
            final partsA = a.split(' ');
            final partsB = b.split(' ');
            final yearA =
                int.tryParse(partsA.length > 1 ? partsA[1] : '2026') ?? 2026;
            final yearB =
                int.tryParse(partsB.length > 1 ? partsB[1] : '2026') ?? 2026;

            if (yearA != yearB) return yearA.compareTo(yearB);

            final mA = monthToNumber[partsA[0].toLowerCase()] ?? 0;
            final mB = monthToNumber[partsB[0].toLowerCase()] ?? 0;
            return mA.compareTo(mB);
          });

        final List<String> columns = [
          ...idCols,
          "Join Date",
          "Status",
          ...sortedMonths,
        ];
        csvData.writeln(columns.map((h) => '"$h"').join(','));

        for (final m in filteredMembers) {
          final mNo = m['membershipNo']?.toString() ?? '-';
          final name =
              m['fullName']?.toString() ?? m['firstName']?.toString() ?? '-';
          final nic = m['nic']?.toString() ?? '-';

          final statusResult = calculateMemberStatus(m);
          final statusStr = statusResult['isActive'] == true
              ? 'ACTIVE'
              : 'INACTIVE';
          final dateJoined = getDateJoined(m);

          final List<String> rowValues = [
            escape(mNo),
            escape(name),
            escape(nic),
            escape(dateJoined),
            escape(statusStr),
          ];

          final paymentHistory = m['payment_history'] as List<dynamic>? ?? [];
          final Map<String, List<Map>> memberPayments = {};

          for (var p in paymentHistory) {
            if (p is Map) {
              final mStr = p['month']?.toString().trim() ?? '';
              final yStr = p['year']?.toString().trim() ?? '';
              String key = '';
              if (mStr.isNotEmpty && yStr.isNotEmpty) {
                key = "$mStr $yStr";
              } else if (mStr.isNotEmpty) {
                key = "$mStr 2026";
              }

              if (key.isNotEmpty) {
                if (!memberPayments.containsKey(key)) memberPayments[key] = [];
                memberPayments[key]!.add(p);
              }
            }
          }

          for (final monthKey in sortedMonths) {
            final payments = memberPayments[monthKey] ?? [];
            if (payments.isEmpty) {
              rowValues.add(escape('-'));
            } else {
              final List<String> cellParts = [];
              for (var p in payments) {
                final amt = p['amount']?.toString() ?? '';
                final tType =
                    p['type']?.toString() ?? p['method']?.toString() ?? '';
                final status = p['status']?.toString() ?? '';
                final dt = p['date']?.toString() ?? '';
                final reason = p['reason']?.toString() ?? '';

                String txt = '';
                if (status.toLowerCase() == 'approved') {
                  txt = "Paid";
                  if (amt.isNotEmpty) txt += " $amt";
                  if (tType.isNotEmpty) txt += " ($tType)";
                  if (dt.isNotEmpty) txt += " on $dt";
                } else {
                  txt = "Pending ($status)";
                }
                if (reason.isNotEmpty && reason != "Monthly Membership Fee") {
                  txt += " [$reason]";
                }
                cellParts.add(txt);
              }
              rowValues.add(escape(cellParts.join(' | ')));
            }
          }

          csvData.writeln(rowValues.join(','));
        }
        exportToCsv('AIAPRTD_Membership_Fee.csv', csvData.toString());
      } else if (type == 'vehicle' || type == 'all') {
        // Fetch vehicles
        final vehiclesSnap = await FirebaseFirestore.instance
            .collection('vehicles')
            .get();
        final Map<String, Map<String, dynamic>> allVehicles = {};
        for (var doc in vehiclesSnap.docs) {
          allVehicles[doc.id] = doc.data();
        }

        final Set<String> dynamicVehicleKeys = {};
        for (final member in filteredMembers) {
          final mNo = member['membershipNo']?.toString();
          if (mNo == null) continue;

          final v = allVehicles[mNo];
          if (v != null) {
            v.forEach((k, val) {
              if (k != 'details' &&
                  k != 'documents' &&
                  k != 'vehiclePhotos' &&
                  k != 'vehicleHistory' &&
                  val is! Map &&
                  val is! List) {
                dynamicVehicleKeys.add(k);
              }
            });

            final details = v['details'] as Map<String, dynamic>? ?? {};
            details.forEach((k, val) {
              dynamicVehicleKeys.add(k);
            });

            final docs = v['documents'] as List<dynamic>? ?? [];
            for (var d in docs) {
              if (d is Map<String, dynamic> && d['reviewData'] != null) {
                final review = d['reviewData'] as Map<String, dynamic>;
                review.forEach((k, val) {
                  dynamicVehicleKeys.add(k);
                });
              }
            }
          }
        }

        final dynamicKeysList = dynamicVehicleKeys.toList()..sort();
        final List<String> standardColumns = type == 'all'
            ? [
                ...idCols,
                "Mobile",
                "Email",
                "Gender",
                "DOB",
                "Address",
                "Religion",
                "Status",
                "Join Date",
                "Current Month Paid",
                "Last Paid Month",
              ]
            : idCols;

        final List<String> headerRow = [...standardColumns, ...dynamicKeysList];
        csvData.writeln(headerRow.map((h) => '"$h"').join(','));

        for (final member in filteredMembers) {
          final mNo = member['membershipNo']?.toString() ?? '-';
          final name =
              member['fullName']?.toString() ??
              member['firstName']?.toString() ??
              '-';
          final nic = member['nic']?.toString() ?? '-';

          final List<String> rowValues = [
            escape(mNo),
            escape(name),
            escape(nic),
          ];

          if (type == 'all') {
            final mobile = member['mobile']?.toString() ?? '-';
            final email = member['email']?.toString() ?? '-';
            final gender = member['gender']?.toString() ?? '-';
            final dob = member['dob']?.toString() ?? '-';
            final address = member['address']?.toString() ?? '-';
            final religion = member['religion']?.toString() ?? '-';

            final statusResult = calculateMemberStatus(member);
            final statusStr = statusResult['isActive'] == true
                ? 'ACTIVE'
                : 'INACTIVE';
            final dateJoined = getDateJoined(member);

            final feeCheck = checkMembershipFeeStatus(member);
            final currentPaid = feeCheck['hasPaidForCurrentMonth'] == true
                ? 'Yes'
                : 'No';
            String lastPaidMonth = '-';
            final paymentHistory =
                member['payment_history'] as List<dynamic>? ?? [];
            if (paymentHistory.isNotEmpty) {
              for (var p in paymentHistory) {
                if (p is Map &&
                    p['status']?.toString().toLowerCase() == 'paid') {
                  lastPaidMonth = "${p['month']} ${p['year']}";
                  break;
                }
              }
            }

            rowValues.addAll([
              escape(mobile),
              escape(email),
              escape(gender),
              escape(dob),
              escape(address),
              escape(religion),
              escape(statusStr),
              escape(dateJoined),
              escape(currentPaid),
              escape(lastPaidMonth),
            ]);
          }

          final v = allVehicles[mNo] ?? {};
          final details = v['details'] as Map<String, dynamic>? ?? {};
          final docs = v['documents'] as List<dynamic>? ?? [];

          final Map<String, String> flatVehicleData = {};

          v.forEach((k, val) {
            if (val != null && val is! Map && val is! List)
              flatVehicleData[k] = val.toString();
          });

          details.forEach((k, val) {
            if (val != null) flatVehicleData[k] = val.toString();
          });

          for (var d in docs) {
            if (d is Map<String, dynamic> && d['reviewData'] != null) {
              final review = d['reviewData'] as Map<String, dynamic>;
              review.forEach((k, val) {
                if (val != null) {
                  if (val is List) {
                    flatVehicleData[k] = val.join(', ');
                  } else {
                    flatVehicleData[k] = val.toString();
                  }
                }
              });
            }
          }

          for (final dk in dynamicKeysList) {
            final val = flatVehicleData[dk] ?? '';
            rowValues.add(escape(val));
          }

          csvData.writeln(rowValues.join(','));
        }

        final fileName = type == 'all'
            ? 'AIAPRTD_All_Details.csv'
            : 'AIAPRTD_Vehicle_Details.csv';
        exportToCsv(fileName, csvData.toString());
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV Exported successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showMigrateIdsDialog(
    BuildContext context,
    List<Map<String, dynamic>> allMembers,
  ) async {
    final emailMembers = allMembers.where((m) {
      final docId = m['doc_id']?.toString() ?? '';
      return docId.contains('@');
    }).toList();

    if (emailMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No members found with email-based Document IDs!'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    bool isLoading = false;
    int successCount = 0;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Migrate Email Document IDs'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Found ${emailMembers.length} members with Email as their Document ID in Firestore.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This action will:\n'
                    '1. Copy their document to a new ID based on their Membership Number.\n'
                    '2. Delete the old Email-based document.\n'
                    '3. Do the same for related collections (vehicles, bank_details, etc).\n\n'
                    'WARNING: If the mobile app strictly relies on reading the document by Email ID, it might break for these users until they re-login or update the app.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                  if (isLoading) ...[
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text('Migrating... Please do not close.'),
                  ],
                ],
              ),
            ),
            actions: [
              if (!isLoading)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              if (!isLoading)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    setState(() => isLoading = true);

                    for (final member in emailMembers) {
                      final oldId = member['doc_id']?.toString() ?? '';
                      final newId = member['membershipNo']?.toString() ?? '';

                      if (oldId.isNotEmpty &&
                          oldId.contains('@') &&
                          newId.isNotEmpty &&
                          newId != '-' &&
                          newId != oldId) {
                        try {
                          final batch = FirebaseFirestore.instance.batch();

                          // 1. Migrate `member` collection
                          final oldMemberRef = FirebaseFirestore.instance
                              .collection('member')
                              .doc(oldId);
                          final newMemberRef = FirebaseFirestore.instance
                              .collection('member')
                              .doc(newId);
                          final oldMemberDoc = await oldMemberRef.get();
                          if (oldMemberDoc.exists) {
                            batch.set(newMemberRef, oldMemberDoc.data()!);
                            batch.delete(oldMemberRef);
                          }

                          // 2. Migrate `vehicles` collection
                          final oldVehicleRef = FirebaseFirestore.instance
                              .collection('vehicles')
                              .doc(oldId);
                          final newVehicleRef = FirebaseFirestore.instance
                              .collection('vehicles')
                              .doc(newId);
                          final oldVehicleDoc = await oldVehicleRef.get();
                          if (oldVehicleDoc.exists) {
                            batch.set(newVehicleRef, oldVehicleDoc.data()!);
                            batch.delete(oldVehicleRef);
                          }

                          // 3. Migrate `bank_details` collection
                          final oldBankRef = FirebaseFirestore.instance
                              .collection('bank_details')
                              .doc(oldId);
                          final newBankRef = FirebaseFirestore.instance
                              .collection('bank_details')
                              .doc(newId);
                          final oldBankDoc = await oldBankRef.get();
                          if (oldBankDoc.exists) {
                            batch.set(newBankRef, oldBankDoc.data()!);
                            batch.delete(oldBankRef);
                          }

                          // 4. Migrate `member_inactive_reasons` collection
                          final oldReasonRef = FirebaseFirestore.instance
                              .collection('member_inactive_reasons')
                              .doc(oldId);
                          final newReasonRef = FirebaseFirestore.instance
                              .collection('member_inactive_reasons')
                              .doc(newId);
                          final oldReasonDoc = await oldReasonRef.get();
                          if (oldReasonDoc.exists) {
                            batch.set(newReasonRef, oldReasonDoc.data()!);
                            batch.delete(oldReasonRef);
                          }

                          // 5. Migrate `app_membership_fee` collection
                          final oldFeeRef = FirebaseFirestore.instance
                              .collection('app_membership_fee')
                              .doc(oldId);
                          final newFeeRef = FirebaseFirestore.instance
                              .collection('app_membership_fee')
                              .doc(newId);
                          final oldFeeDoc = await oldFeeRef.get();
                          if (oldFeeDoc.exists) {
                            batch.set(newFeeRef, oldFeeDoc.data()!);
                            batch.delete(oldFeeRef);
                          }

                          await batch.commit();
                          successCount++;
                        } catch (e) {
                          debugPrint('Error migrating $oldId to $newId: $e');
                        }
                      }
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Migrated $successCount documents successfully!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                      // Refresh members
                      Provider.of<MemberProvider>(
                        context,
                        listen: false,
                      ).startListeningToMembers();
                    }
                  },
                  child: const Text('Start Migration'),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();
    
    List<Widget> pageButtons = [];
    
    pageButtons.add(
      IconButton(
        icon: const Icon(Icons.chevron_left, size: 20),
        onPressed: _currentPage > 1 ? () { setState(() { _currentPage--; }); } : null,
      )
    );
    
    for (int i = 1; i <= totalPages; i++) {
      if (totalPages > 10) {
        if (i != 1 && i != totalPages && (i < _currentPage - 2 || i > _currentPage + 2)) {
          if (i == 2 || i == totalPages - 1) {
            pageButtons.add(const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('...')));
          }
          continue;
        }
      }
      
      bool isSelected = i == _currentPage;
      pageButtons.add(
        InkWell(
          onTap: () { setState(() { _currentPage = i; }); },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey.shade300),
            ),
            child: Text(
              i.toString(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        )
      );
    }
    
    pageButtons.add(
      IconButton(
        icon: const Icon(Icons.chevron_right, size: 20),
        onPressed: _currentPage < totalPages ? () { setState(() { _currentPage++; }); } : null,
      )
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: pageButtons,
      ),
    );
  }
}