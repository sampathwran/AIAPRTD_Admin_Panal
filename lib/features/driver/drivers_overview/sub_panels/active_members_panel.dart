import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_admin_dashboard/core/providers/member_provider.dart';

class ActiveMembersPanel extends StatefulWidget {
  final VoidCallback onBack;
  const ActiveMembersPanel({super.key, required this.onBack});

  @override
  State<ActiveMembersPanel> createState() => _ActiveMembersPanelState();
}

class _ActiveMembersPanelState extends State<ActiveMembersPanel> {
  String _searchQuery = '';

  // 💡 දෙපැත්තටම ස්වාධීනව scroll වෙන්න Controllers දෙකක් අනිවාර්යයෙන්ම ඕනේ මචං
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

    final activeMembers = memberProvider.allMembersList.where((driver) {
      return driver['status'] == 'active';
    }).toList();

    final filteredMembers = activeMembers.where((driver) {
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: Colors.black87,
                  ),
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Members Analytics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Verified drivers running inside the grid (${activeMembers.length})',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Utility Bar
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Search active drivers...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.grey,
                  size: 18,
                ),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Real Live Data Grid Table
            Expanded(
              child: memberProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.indigo,
                        strokeWidth: 3,
                      ),
                    )
                  : filteredMembers.isEmpty
                  ? const Center(
                      child: Text(
                        'No active drivers matching search query.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF000000,
                            ).withValues(alpha: 0.01),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      // =========================================================================
                      // 💡 1. VERTICAL LAYER: උඩ/පහළ ස්ක්‍රෝල් එක සහ දකුණු පැත්තේ ලයිව් ස්ක්‍රෝල් බාර් එක
                      // =========================================================================
                      child: Scrollbar(
                        controller: _verticalController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        child: SingleChildScrollView(
                          controller: _verticalController,
                          scrollDirection: Axis.vertical,
                          // =========================================================================
                          // 💡 2. HORIZONTAL LAYER: වමට/දකුණට ස්ක්‍රෝල් එක සහ යටින් ලයිව් ස්ක්‍රෝල් බාර් එක
                          // =========================================================================
                          child: Scrollbar(
                            controller: _horizontalController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            // notificationPredicate එක දාලා තියෙන්නේ scroll bars දෙක පටලවා නොගන්න Flutter engine එකට උදව් වෙන්න මචං
                            notificationPredicate: (notification) =>
                                notification.depth == 0,
                            child: SingleChildScrollView(
                              controller: _horizontalController,
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                // Table එක තෙරපෙන්නේ නැතුව නිදහසේ දිග හැරෙන්න මෙතන පළල 1100 ක් කළා මචං
                                constraints: const BoxConstraints(
                                  minWidth: 1100,
                                ),
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    Colors.indigo.withValues(alpha: 0.02),
                                  ),
                                  headingRowHeight: 40,
                                  dataRowMinHeight: 44,
                                  dataRowMaxHeight: 44,
                                  horizontalMargin: 12,
                                  columnSpacing: 24,
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        'ID',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Full Name',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Mobile',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Vehicle Number',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Vehicle Type',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Rating',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Status',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: filteredMembers.map((driver) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            driver['membershipNo'] ?? '-',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            driver['fullName'] ?? 'Unknown',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            driver['mobile'] ?? '-',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            driver['vehicleNumber'] ?? '-',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            driver['vehicleType'] ?? '-',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '⭐ ${driver['rating'] ?? '5.0'}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              "ACTIVE",
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
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
