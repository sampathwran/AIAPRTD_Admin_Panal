import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/member_provider.dart';

class OfflineMembersPanel extends StatefulWidget {
  final VoidCallback onBack;
  const OfflineMembersPanel({super.key, required this.onBack});

  @override
  State<OfflineMembersPanel> createState() => _OfflineMembersPanelState();
}

class _OfflineMembersPanelState extends State<OfflineMembersPanel> {
  String _searchQuery = '';

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MemberProvider>(context, listen: false).startListeningToMembers();
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

    // 💡 FIXED: කෙලින්ම Provider එකේ සාදාගත් Offline ලැයිස්තුව ලබාගනී
    final offlineMembers = memberProvider.offlineMembersList;

    // Search Live Filter
    final filteredMembers = offlineMembers.where((driver) {
      final name = (driver['fullName'] ?? '').toString().toLowerCase();
      final mobile = (driver['mobile'] ?? '').toString().toLowerCase();
      final vehicleNo = (driver['vehicleNumber'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || mobile.contains(query) || vehicleNo.contains(query);
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
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: Colors.black87),
                  onPressed: widget.onBack,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Offline Members List',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Disconnected drivers from socket with last seen tracks (${offlineMembers.length})',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Live Search Bar
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(fontSize: 11),
              decoration: InputDecoration(
                hintText: 'Search offline drivers by Name, Mobile, Vehicle...',
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 16),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Dual-Scroll Custom Grid Table
            Expanded(
              child: memberProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.blueGrey, strokeWidth: 2.5))
                  : filteredMembers.isEmpty
                  ? const Center(
                child: Text('No offline drivers found.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              )
                  : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Scrollbar(
                  controller: _horizontalController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 910,
                      child: Column(
                        children: [
                          // FIXED CUSTOM TABLE HEADER
                          Container(
                            height: 34,
                            color: Colors.grey.withValues(alpha: 0.05),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: const Row(
                              children: [
                                SizedBox(width: 110, child: Text('Membership No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey))),
                                SizedBox(width: 180, child: Text('Driver Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey))),
                                SizedBox(width: 110, child: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey))),
                                SizedBox(width: 130, child: Text('Vehicle Plate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey))),
                                SizedBox(width: 130, child: Text('Vehicle Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey))),
                                SizedBox(width: 250, child: Text('Last Seen Tracking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey))),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),

                          // VERTICAL SCROLL LIST
                          Expanded(
                            child: Scrollbar(
                              controller: _verticalController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: ListView.builder(
                                controller: _verticalController,
                                itemCount: filteredMembers.length,
                                physics: const BouncingScrollPhysics(),
                                itemExtent: 36,
                                itemBuilder: (context, index) {
                                  final driver = filteredMembers[index];

                                  // Last seen text mapping
                                  String lastSeenText = driver['lastSeen']?.toString() ?? 'Never';

                                  return Container(
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Row(
                                      children: [
                                        SizedBox(width: 110, child: Text(driver['membershipNo'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11))),
                                        SizedBox(width: 180, child: Text(driver['fullName'] ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11))),
                                        SizedBox(width: 110, child: Text(driver['mobile'] ?? '-', style: const TextStyle(fontSize: 11))),
                                        SizedBox(
                                          width: 130,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                  color: Colors.grey.withValues(alpha: 0.05),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1))
                                              ),
                                              child: Text(driver['vehicleNumber'] ?? '-', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 10)),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 130, child: Text(driver['vehicleType'] ?? '-', style: const TextStyle(fontSize: 11))),
                                        SizedBox(
                                          width: 250,
                                          child: Row(
                                            children: [
                                              const Icon(Icons.access_time_rounded, size: 12, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  lastSeenText,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
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
          ],
        ),
      ),
    );
  }
}