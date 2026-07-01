import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/member_provider.dart';

class OnlineMembersPanel extends StatefulWidget {
  final VoidCallback onBack;
  const OnlineMembersPanel({super.key, required this.onBack});

  @override
  State<OnlineMembersPanel> createState() => _OnlineMembersPanelState();
}

class _OnlineMembersPanelState extends State<OnlineMembersPanel> {
  String _searchQuery = '';

  // 💡 දෙපැත්තටම බාධාවකින් තොරව ස්ක්‍රෝල් වෙන්න ස්වාධීන පාලක දෙකක් හැදුවා මචං
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

    // 💡 FIXED: කෙලින්ම Provider එකේ සාදාගත් Live Online ලැයිස්තුව ලබාගනී
    final onlineMembers = memberProvider.onlineMembersList;

    // සර්ච් බාර් එකෙන් ලයිව් ෆිල්ටර් කරන කෑල්ල
    final filteredMembers = onlineMembers.where((driver) {
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
            // ==========================================================
            // ⬅️ SECTION 1: HEADER & LIVE INDICATOR (Compact)
            // ==========================================================
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
                    Row(
                      children: [
                        const Text(
                          'Live Online Members',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(width: 6),
                        // 🟢 ලයිව් බ්ලින්ක් වෙන රවුම (Live Pulse Dot)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.green, blurRadius: 4, spreadRadius: 1),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Drivers active on map socket, ready for trips (${onlineMembers.length})',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ==========================================================
            // 🔎 SECTION 2: LIVE SEARCH (Ultra Slim)
            // ==========================================================
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(fontSize: 11),
              decoration: InputDecoration(
                hintText: 'Search online drivers...',
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
                  // 💡 FIXED: 'Colors.grey.shade200' වෙනුවට 'withValues' යොදාගත්තා මචං
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ==========================================================
            // 📊 SECTION 3: DUAL-SCROLLABLE CUSTOM GRID LAYOUT
            // ==========================================================
            Expanded(
              child: memberProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2.5))
                  : filteredMembers.isEmpty
                  ? const Center(
                child: Text('No active online drivers at the moment.', style: TextStyle(color: Colors.grey, fontSize: 12)),
              )
                  : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                // 💡 LAYER 1: HORIZONTAL SCROLLBAR
                child: Scrollbar(
                  controller: _horizontalController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 890,
                      child: Column(
                        children: [
                          // Custom Table Header Row
                          Container(
                            height: 34,
                            color: Colors.green.withValues(alpha: 0.02),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: const Row(
                              children: [
                                SizedBox(width: 110, child: Text('Membership No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green))),
                                SizedBox(width: 180, child: Text('Driver Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green))),
                                SizedBox(width: 110, child: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green))),
                                SizedBox(width: 130, child: Text('Vehicle Plate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green))),
                                SizedBox(width: 130, child: Text('Vehicle Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green))),
                                SizedBox(width: 130, child: Text('Availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.green))),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),

                          // 💡 LAYER 2: VERTICAL SCROLLBAR
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
                                  final bool isAvailable = driver['isAvailable'] ?? true;

                                  return Container(
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Row(
                                      children: [
                                        // Membership No
                                        SizedBox(width: 110, child: Text(driver['membershipNo'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11))),

                                        // Driver Name
                                        SizedBox(width: 180, child: Text(driver['fullName'] ?? 'Unknown', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11))),

                                        // Mobile
                                        SizedBox(width: 110, child: Text(driver['mobile'] ?? '-', style: const TextStyle(fontSize: 11))),

                                        // Vehicle Plate Badge
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

                                        // Vehicle Category
                                        SizedBox(width: 130, child: Text(driver['vehicleType'] ?? '-', style: const TextStyle(fontSize: 11))),

                                        // Availability Status Badge
                                        SizedBox(
                                          width: 130,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isAvailable ? Colors.green.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                isAvailable ? "AVAILABLE" : "ON TRIP",
                                                style: TextStyle(
                                                    color: isAvailable ? Colors.green : Colors.blue,
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold
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