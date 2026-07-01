// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/member_provider.dart';
import '../../providers/profile_image_provider.dart';
import 'member_profile_cards.dart'; // 💡 අලුතින් හදපු Cards ටික මෙතනින් Import කළා

class TotalMembersListPanel extends StatefulWidget {
  const TotalMembersListPanel({super.key});

  @override
  State<TotalMembersListPanel> createState() => _TotalMembersListPanelState();
}

class _TotalMembersListPanelState extends State<TotalMembersListPanel> {
  Map<String, dynamic>? _selectedMember;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileImageProvider>(context, listen: false).startListeningToProfileImages();

      // ==========================================================
      // 💡 🎯 FIXED: Member list එක Firebase එකෙන් ලෝඩ් කරන්න කමාන්ඩ් එක දුන්නා
      // ==========================================================
      final memberProvider = Provider.of<MemberProvider>(context, listen: false);
      if (memberProvider.allMembersList.isEmpty) {
        memberProvider.startListeningToMembers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedMember != null) {
      return SelectionArea(
        child: _buildProfileView(_selectedMember!),
      );
    }

    final memberProvider = Provider.of<MemberProvider>(context);

    final filteredMembers = memberProvider.allMembersList.where((member) {
      final membershipNo = (member['membershipNo'] ?? '').toString().toLowerCase();
      final fullName = (member['fullName'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return membershipNo.contains(query) || fullName.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registered Members Directory',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            Text(
              'Browse and manage full master profile records inside the grid (${filteredMembers.length})',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),

            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search by Membership No or Name...',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1E3A8A), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = "");
                      },
                    )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E3A8A))),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: memberProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A), strokeWidth: 2.5))
                  : filteredMembers.isEmpty
                  ? const Center(child: Text('No registered members found.', style: TextStyle(color: Colors.grey, fontSize: 13)))
                  : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Scrollbar(
                  controller: _horizontalController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 550,
                      child: Column(
                        children: [
                          Container(
                            height: 40,
                            color: const Color(0xFFF8FAFC),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: const Row(
                              children: [
                                SizedBox(width: 150, child: Text('Membership No', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A)))),
                                SizedBox(width: 260, child: Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A)))),
                                SizedBox(width: 100, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A)))),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          Expanded(
                            child: Scrollbar(
                              controller: _verticalController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: ListView.builder(
                                controller: _verticalController,
                                itemCount: filteredMembers.length,
                                physics: const BouncingScrollPhysics(),
                                itemExtent: 40,
                                itemBuilder: (context, index) {
                                  final d = filteredMembers[index];
                                  return Container(
                                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1))),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Row(
                                      children: [
                                        SizedBox(width: 150, child: Text(d['membershipNo'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                        SizedBox(width: 260, child: Text(d['fullName'] ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                                        SizedBox(
                                          width: 100,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: InkWell(
                                              onTap: () => setState(() => _selectedMember = d),
                                              borderRadius: BorderRadius.circular(4),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(color: const Color(0xFF1E3A8A).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                                                child: const Text('View Profile', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 11, fontWeight: FontWeight.bold)),
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

  // =========================================================================
  // 💎 MODULAR PROFILE VIEW LAYOUT
  // =========================================================================
  Widget _buildProfileView(Map<String, dynamic> d) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1))),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text('Member Master Profile', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)),
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 16),
              onPressed: () => setState(() => _selectedMember = null),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Section
            ProfileHeaderCard(memberData: d),
            const SizedBox(height: 16),

            // 2. Two-Column Grid (Personal Details | Vehicle & Bank)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      PersonalDetailsCard(memberData: d),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      VehicleInfoCard(memberData: d),
                      const SizedBox(height: 16),
                      BankDetailsCard(memberData: d),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),

            // 3. Full Width Sections
            PaymentHistoryCard(memberData: d),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}