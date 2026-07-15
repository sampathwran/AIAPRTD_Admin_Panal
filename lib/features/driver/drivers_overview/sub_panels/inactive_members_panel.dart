import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_admin_dashboard/core/providers/member_provider.dart';

class InactiveMembersPanel extends StatefulWidget {
  final VoidCallback onBack;
  const InactiveMembersPanel({super.key, required this.onBack});

  @override
  State<InactiveMembersPanel> createState() => _InactiveMembersPanelState();
}

class _InactiveMembersPanelState extends State<InactiveMembersPanel> {
  String _searchQuery = '';

  // 💡 දෙපැත්තටම ස්වාධීනව ස්ක්‍රෝල් වෙන්න පාලක දෙකක් හැදුවා මචං
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

    // 💡 Realtime Filtering: Status එක 'active' නොවන (pending/inactive) අය වෙන් කරලා ගන්නවා
    final inactiveMembers = memberProvider.allMembersList.where((driver) {
      return driver['status'] != 'active';
    }).toList();

    final filteredMembers = inactiveMembers.where((driver) {
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
        // 💡 1. ULTRA COMPACT: බාහිර පරතරය 24 සිට 10 දක්වා අඩු කළා මචං
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section (Slim Layer)
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
                      'Inactive Members (Dormant Accounts)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Accounts requiring re-engagement or pending verification',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search Bar (Ultra Compact)
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(fontSize: 11),
              decoration: InputDecoration(
                hintText: 'Search dormant profiles...',
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
            const SizedBox(height: 12),

            // ==========================================================
            // 📊 DUAL-SCROLLABLE CUSTOM GRID LAYOUT
            // ==========================================================
            Expanded(
              child: memberProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.orange,
                        strokeWidth: 2.5,
                      ),
                    )
                  : filteredMembers.isEmpty
                  ? const Center(
                      child: Text(
                        'No inactive profiles found.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      // 💡 LAYER 1: HORIZONTAL SCROLLBAR (වමට දකුණට)
                      child: Scrollbar(
                        controller: _horizontalController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        child: SingleChildScrollView(
                          controller: _horizontalController,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            // Table එක හිර නොවී දිගහැරෙන්න සීමාව 860px කළා මචං
                            width: 860,
                            child: Column(
                              children: [
                                // Custom Header Row
                                Container(
                                  height: 34,
                                  color: Colors.orange.withValues(alpha: 0.02),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: const Row(
                                    children: [
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          'ID',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 180,
                                        child: Text(
                                          'Full Name',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: Colors.orange,
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
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 130,
                                        child: Text(
                                          'Vehicle Number',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 130,
                                        child: Text(
                                          'Type',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          'Status',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: Colors.orange,
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

                                // 💡 LAYER 2: VERTICAL SCROLLBAR (උඩ පහළ)
                                Expanded(
                                  child: Scrollbar(
                                    controller: _verticalController,
                                    thumbVisibility: true,
                                    trackVisibility: true,
                                    child: ListView.builder(
                                      controller: _verticalController,
                                      itemCount: filteredMembers.length,
                                      physics: const BouncingScrollPhysics(),
                                      itemExtent:
                                          36, // Row එකක උස 36px දක්වා සිහින් කළා
                                      itemBuilder: (context, index) {
                                        final driver = filteredMembers[index];
                                        final currentStatus =
                                            driver['status'] ?? 'pending';

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
                                              // ID Column
                                              SizedBox(
                                                width: 100,
                                                child: Text(
                                                  driver['membershipNo'] ?? '-',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),

                                              // Full Name Column
                                              SizedBox(
                                                width: 180,
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

                                              // Mobile Column
                                              SizedBox(
                                                width: 120,
                                                child: Text(
                                                  driver['mobile'] ?? '-',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),

                                              // Vehicle Number Badge Column
                                              SizedBox(
                                                width: 130,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors
                                                            .grey
                                                            .shade200,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      driver['vehicleNumber'] ??
                                                          '-',
                                                      style: const TextStyle(
                                                        fontFamily: 'monospace',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 10,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),

                                              // Vehicle Type Column
                                              SizedBox(
                                                width: 130,
                                                child: Text(
                                                  driver['vehicleType'] ?? '-',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),

                                              // Status Soft Badge Column
                                              SizedBox(
                                                width: 100,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.amber
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      currentStatus
                                                          .toString()
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                        color: Colors.amber,
                                                        fontSize: 8,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
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
          ],
        ),
      ),
    );
  }
}
