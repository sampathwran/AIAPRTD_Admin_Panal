import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_admin_dashboard/core/providers/member_provider.dart';

class MembershipFeeApprovalsPanel extends StatefulWidget {
  const MembershipFeeApprovalsPanel({super.key});

  @override
  State<MembershipFeeApprovalsPanel> createState() =>
      _MembershipFeeApprovalsPanelState();
}

class _MembershipFeeApprovalsPanelState
    extends State<MembershipFeeApprovalsPanel> {
  Map<String, dynamic>? _selectedMember;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  late Stream<QuerySnapshot> _webSyncStream;
  late Stream<QuerySnapshot> _appFeeStream;

  String _filterMode = "Total"; // 'Total', 'Pending', 'Approved'

  @override
  void initState() {
    super.initState();
    _webSyncStream = FirebaseFirestore.instance
        .collection('web_sync_membership_fee')
        .snapshots();
    _appFeeStream = FirebaseFirestore.instance
        .collection('app_membership_fee')
        .snapshots();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final memberProvider = Provider.of<MemberProvider>(
        context,
        listen: false,
      );
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

  // Safe list extractor to prevent cast errors from Firebase (e.g. if field is an empty string "")
  List<dynamic> _safeList(dynamic data) {
    if (data is List) return data;
    return [];
  }

  Widget _buildStatCard(String title, int count, Color color, String mode) {
    bool isSelected = _filterMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filterMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedMember != null) {
      return SelectionArea(child: _buildProfileView(_selectedMember!));
    }

    final memberProvider = Provider.of<MemberProvider>(context);
    final allMembers = memberProvider.allMembersList;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: StreamBuilder<QuerySnapshot>(
        stream: _webSyncStream,
        builder: (context, webSyncSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: _appFeeStream,
            builder: (context, appFeeSnapshot) {
              if (webSyncSnapshot.connectionState == ConnectionState.waiting ||
                  appFeeSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                );
              }

              final webSyncMap = {
                for (var doc in webSyncSnapshot.data?.docs ?? [])
                  doc.id: doc.data() as Map<String, dynamic>,
              };
              final appFeeMap = {
                for (var doc in appFeeSnapshot.data?.docs ?? [])
                  doc.id: doc.data() as Map<String, dynamic>,
              };

              final allItems = allMembers.map((member) {
                final memNo = member['membershipNo']?.toString() ?? '';
                final wSync = webSyncMap[memNo] ?? {};
                final aFee = appFeeMap[memNo] ?? {};

                final appApprovedList = _safeList(aFee['payment_history']);
                final webPendingList = _safeList(wSync['payment_history']);

                // Calculate unapproved web syncs
                int unapprovedWebCount = 0;
                for (var webRec in webPendingList) {
                  final recMap = webRec is Map
                      ? Map<String, dynamic>.from(webRec)
                      : {};
                  final m = (recMap['month'] ?? '').toString();
                  if (m.isNotEmpty &&
                      !_isAlreadyPaidInApp(m, appApprovedList)) {
                    unapprovedWebCount++;
                  }
                }

                return {
                  'memberData': member,
                  'webSync': wSync,
                  'appFee': aFee,
                  'unapprovedWebCount': unapprovedWebCount,
                };
              }).toList();

              int totalCount = allItems.length;
              int pendingCount = 0;
              int approvedCount = 0;

              for (var item in allItems) {
                final aFee = item['appFee'] as Map<String, dynamic>;
                final pendingList = _safeList(aFee['pending_payments']);
                bool isPending =
                    pendingList.isNotEmpty ||
                    (item['unapprovedWebCount'] as int) > 0;
                if (isPending)
                  pendingCount++;
                else
                  approvedCount++;
              }

              final combinedMembers = allItems.where((item) {
                final member = item['memberData'] as Map<String, dynamic>;
                final aFee = item['appFee'] as Map<String, dynamic>;
                final pendingList = _safeList(aFee['pending_payments']);
                bool isPending =
                    pendingList.isNotEmpty ||
                    (item['unapprovedWebCount'] as int) > 0;

                bool matchesMode = true;
                if (_filterMode == 'Pending')
                  matchesMode = isPending;
                else if (_filterMode == 'Approved')
                  matchesMode = !isPending;

                if (!matchesMode) return false;

                final membershipNo = (member['membershipNo'] ?? '')
                    .toString()
                    .toLowerCase();
                final fullName = (member['fullName'] ?? '')
                    .toString()
                    .toLowerCase();
                final query = _searchQuery.toLowerCase();
                return membershipNo.contains(query) || fullName.contains(query);
              }).toList();

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Membership Fee Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Text(
                      'Manage member arrears, view web synced data, and approve pending mobile app payments.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        _buildStatCard(
                          "Total Members",
                          totalCount,
                          Colors.blue.shade700,
                          "Total",
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          "Pending Approvals",
                          pendingCount,
                          Colors.orange.shade700,
                          "Pending",
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          "Approved",
                          approvedCount,
                          Colors.green.shade700,
                          "Approved",
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

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
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Search by Membership No or Name...',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF1E3A8A),
                              size: 20,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = "");
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: memberProvider.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF1E3A8A),
                                strokeWidth: 2.5,
                              ),
                            )
                          : combinedMembers.isEmpty
                          ? const Center(
                              child: Text(
                                'No members found.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            )
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
                                    width: 850,
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 40,
                                          color: const Color(0xFFF8FAFC),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: const Row(
                                            children: [
                                              SizedBox(
                                                width: 130,
                                                child: Text(
                                                  'Membership No',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
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
                                                    fontSize: 12,
                                                    color: Color(0xFF1E3A8A),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 180,
                                                child: Text(
                                                  'Pending Web Syncs',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Color(0xFF1E3A8A),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 180,
                                                child: Text(
                                                  'Pending App Uploads',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                    color: Color(0xFF1E3A8A),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 100,
                                                child: Text(
                                                  'Action',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
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
                                        Expanded(
                                          child: Scrollbar(
                                            controller: _verticalController,
                                            thumbVisibility: true,
                                            trackVisibility: true,
                                            child: ListView.builder(
                                              controller: _verticalController,
                                              itemCount: combinedMembers.length,
                                              physics:
                                                  const BouncingScrollPhysics(),
                                              itemExtent: 50,
                                              itemBuilder: (context, index) {
                                                final item =
                                                    combinedMembers[index];
                                                final d =
                                                    item['memberData']
                                                        as Map<String, dynamic>;
                                                final a =
                                                    item['appFee']
                                                        as Map<String, dynamic>;

                                                final pendingApp = _safeList(
                                                  a['pending_payments'],
                                                );
                                                final unapprovedWebCount =
                                                    item['unapprovedWebCount']
                                                        as int;

                                                return Container(
                                                  decoration:
                                                      const BoxDecoration(
                                                        border: Border(
                                                          bottom: BorderSide(
                                                            color: Color(
                                                              0xFFF1F5F9,
                                                            ),
                                                            width: 1,
                                                          ),
                                                        ),
                                                      ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 130,
                                                        child: Text(
                                                          d['membershipNo'] ??
                                                              '-',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 200,
                                                        child: Text(
                                                          d['fullName'] ?? '-',
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 180,
                                                        child:
                                                            unapprovedWebCount >
                                                                0
                                                            ? Container(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color: Colors
                                                                      .blue
                                                                      .shade50,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        4,
                                                                      ),
                                                                ),
                                                                child: Text(
                                                                  '$unapprovedWebCount Web Syncs to Approve',
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .blue
                                                                        .shade900,
                                                                    fontSize:
                                                                        11,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              )
                                                            : const Text(
                                                                'Up to date',
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                      ),
                                                      SizedBox(
                                                        width: 180,
                                                        child:
                                                            pendingApp
                                                                .isNotEmpty
                                                            ? Container(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8,
                                                                      vertical:
                                                                          4,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color: Colors
                                                                      .orange
                                                                      .shade50,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        4,
                                                                      ),
                                                                ),
                                                                child: Text(
                                                                  '${pendingApp.length} App Uploads to Approve',
                                                                  style: TextStyle(
                                                                    color: Colors
                                                                        .orange
                                                                        .shade900,
                                                                    fontSize:
                                                                        11,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              )
                                                            : const Text(
                                                                'No Pending Slips',
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                  fontSize: 11,
                                                                ),
                                                              ),
                                                      ),
                                                      SizedBox(
                                                        width: 100,
                                                        child: Align(
                                                          alignment: Alignment
                                                              .centerLeft,
                                                          child: InkWell(
                                                            onTap: () => setState(
                                                              () =>
                                                                  _selectedMember =
                                                                      item,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  4,
                                                                ),
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        10,
                                                                    vertical: 4,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    (pendingApp
                                                                            .isNotEmpty ||
                                                                        unapprovedWebCount >
                                                                            0)
                                                                    ? Colors
                                                                          .amber
                                                                          .shade100
                                                                    : const Color(
                                                                        0xFF1E3A8A,
                                                                      ).withValues(
                                                                        alpha:
                                                                            0.08,
                                                                      ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      4,
                                                                    ),
                                                              ),
                                                              child: Text(
                                                                'View',
                                                                style: TextStyle(
                                                                  color:
                                                                      (pendingApp
                                                                              .isNotEmpty ||
                                                                          unapprovedWebCount >
                                                                              0)
                                                                      ? Colors
                                                                            .amber
                                                                            .shade900
                                                                      : const Color(
                                                                          0xFF1E3A8A,
                                                                        ),
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
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
              );
            },
          );
        },
      ),
    );
  }

  bool _isAlreadyPaidInApp(String requestedMonths, List<dynamic> appHistory) {
    final query = requestedMonths.toLowerCase();
    for (var rec in appHistory) {
      if (rec is! Map) continue;
      final recMap = Map<String, dynamic>.from(rec);
      final monthList = _safeList(recMap['months']);
      if (monthList.isNotEmpty) {
        // App format
        for (var m in monthList) {
          if (query.contains(m.toString().toLowerCase())) return true;
        }
      } else {
        // Web format inside app_membership_fee
        final m = (recMap['month'] ?? '').toString().toLowerCase();
        if (m.isNotEmpty && query.contains(m)) return true;
      }
    }
    return false;
  }

  // =========================================================================
  // DETAILED VIEW FOR SINGLE MEMBER
  // =========================================================================
  Widget _buildProfileView(Map<String, dynamic> combinedData) {
    final member = combinedData['memberData'] as Map<String, dynamic>;
    final membershipNo = member['membershipNo'] ?? 'Unknown';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Fee Approvals - $membershipNo',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.black87,
                size: 16,
              ),
              onPressed: () => setState(() => _selectedMember = null),
            ),
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('app_membership_fee')
            .doc(membershipNo)
            .snapshots(),
        builder: (context, appFeeSnapshot) {
          final appData =
              appFeeSnapshot.data?.data() as Map<String, dynamic>? ?? {};
          final pendingAppList = _safeList(appData['pending_payments']);
          final appApprovedList = _safeList(appData['payment_history']);

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('web_sync_membership_fee')
                .doc(membershipNo)
                .snapshots(),
            builder: (context, webFeeSnapshot) {
              final webData =
                  webFeeSnapshot.data?.data() as Map<String, dynamic>? ?? {};
              final pendingWebList = _safeList(webData['payment_history']);

              final totalPending =
                  pendingAppList.length + pendingWebList.length;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT COLUMN: Pending Requests (Both App & Web)
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Pending Approvals",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (totalPending == 0)
                            _buildEmptyState(
                              "Nothing to Approve",
                              "This member has no pending slips or web syncs.",
                              Icons.verified,
                              Colors.green,
                            )
                          else ...[
                            if (pendingAppList.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  "App Uploads (Slips)",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ...pendingAppList.map((item) {
                              if (item is! Map) return const SizedBox.shrink();
                              final pendingItem = Map<String, dynamic>.from(
                                item,
                              );
                              return _buildAppPendingCard(
                                context,
                                membershipNo,
                                pendingItem,
                                appApprovedList,
                              );
                            }),

                            if (pendingWebList.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.only(
                                  bottom: 8.0,
                                  top: 16.0,
                                ),
                                child: Text(
                                  "Web System Syncs",
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ...pendingWebList.map((item) {
                              if (item is! Map) return const SizedBox.shrink();
                              final pendingWebItem = Map<String, dynamic>.from(
                                item,
                              );
                              return _buildWebPendingCard(
                                context,
                                membershipNo,
                                pendingWebItem,
                                appApprovedList,
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),

                    // RIGHT COLUMN: Official History (app_membership_fee ONLY)
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Official Approved History",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildHistoryCard(
                            context,
                            membershipNo,
                            "Approved Payments",
                            appApprovedList,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAppPendingCard(
    BuildContext context,
    String membershipNo,
    Map<String, dynamic> pendingItem,
    List<dynamic> appApprovedList,
  ) {
    final slipUrl = pendingItem['slipUrl'] as String?;
    final dateStr = pendingItem['paymentDate'] ?? 'Unknown Date';
    final monthsRaw = _safeList(pendingItem['months']);
    final monthsStr = monthsRaw.join(', ');

    final isConflict = _isAlreadyPaidInApp(monthsStr, appApprovedList);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isConflict
            ? const BorderSide(color: Colors.redAccent, width: 2)
            : const BorderSide(color: Colors.orangeAccent, width: 1),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isConflict)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Warning: One or more of these months appear to be ALREADY APPROVED in the official history!",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (slipUrl != null)
                  GestureDetector(
                    onTap: () => _showSlipImage(context, slipUrl),
                    child: Container(
                      width: 100,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                        image: DecorationImage(
                          image: NetworkImage(slipUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.zoom_in,
                          color: Colors.white70,
                          size: 30,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 100,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "App Upload (Requested Months)",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        monthsStr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Uploaded On",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _showApprovalDialog(
                              context,
                              membershipNo,
                              pendingItem,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.edit_document, size: 18),
                            label: const Text("Approve Upload"),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => _rejectAppPayment(
                              context,
                              membershipNo,
                              pendingItem,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            icon: const Icon(Icons.cancel, size: 18),
                            label: const Text("Reject"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebPendingCard(
    BuildContext context,
    String membershipNo,
    Map<String, dynamic> pendingWebItem,
    List<dynamic> appApprovedList,
  ) {
    final month = pendingWebItem['month'] ?? 'Unknown';
    final year = pendingWebItem['year'] ?? '';
    final dateStr = pendingWebItem['date'] ?? 'Unknown Date';
    final amount = pendingWebItem['amount'] ?? '0';

    final isConflict = _isAlreadyPaidInApp(month.toString(), appApprovedList);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isConflict
            ? const BorderSide(color: Colors.grey, width: 1)
            : const BorderSide(color: Colors.blueAccent, width: 1),
      ),
      color: isConflict ? Colors.grey.shade50 : Colors.white,
      elevation: isConflict ? 0 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_sync,
                  size: 40,
                  color: isConflict
                      ? Colors.grey
                      : Colors.blue.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Web System Record",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        "$month $year",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isConflict ? Colors.grey : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "Date: $dateStr",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            "Amount: Rs. $amount",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isConflict ? Colors.grey : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isConflict)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text(
                          "Already Approved",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _approveWebPayment(
                      context,
                      membershipNo,
                      pendingWebItem,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text("Approve Web Sync"),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    String membershipNo,
    String title,
    List<dynamic> history,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, size: 18, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900,
                  ),
                ),
              ],
            ),
          ),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "No records found.",
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              separatorBuilder: (c, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                // Show latest first
                final rawRecord = history[history.length - 1 - index];
                if (rawRecord is! Map) return const SizedBox.shrink();

                final record = Map<String, dynamic>.from(rawRecord);
                String monthText = "";
                String dateText = "";
                String amountText = "";

                if (record.containsKey('months')) {
                  final m = _safeList(record['months']);
                  monthText = m.join(', ');
                  if (record.containsKey('year')) {
                    monthText += " ${record['year']}";
                  }
                  dateText = record['paymentDate'] ?? '-';

                  final amount = record['amount'];
                  amountText = (amount != null && amount.toString().isNotEmpty)
                      ? "Rs. $amount"
                      : "App Upload";
                } else {
                  monthText = "${record['month']} ${record['year'] ?? ''}";
                  dateText = record['date'] ?? '-';
                  amountText = "Rs. ${record['amount'] ?? '0'}";
                }

                return ListTile(
                  dense: true,
                  title: Text(
                    monthText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    dateText,
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (record.containsKey('slipUrl') &&
                          record['slipUrl'].toString().isNotEmpty)
                        IconButton(
                          icon: const Icon(
                            Icons.receipt_long,
                            color: Colors.blue,
                            size: 20,
                          ),
                          tooltip: "View Slip",
                          onPressed: () =>
                              _showSlipImage(context, record['slipUrl']),
                        ),
                      Text(
                        amountText,
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.orange,
                          size: 20,
                        ),
                        tooltip: "Edit Payment Record",
                        onPressed: () => _showEditPaymentDialog(
                          context,
                          membershipNo,
                          record,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        tooltip: "Delete Payment Record",
                        onPressed: () =>
                            _deletePaymentRecord(context, membershipNo, record),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 60, color: color.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // ACTIONS
  // =========================================================================

  Future<void> _showApprovalDialog(
    BuildContext context,
    String membershipNo,
    Map<String, dynamic> pendingItem,
  ) async {
    final currentYear = DateTime.now().year;
    String selectedYear = currentYear.toString();

    final allMonths = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    List<String> selectedMonths = [];
    final monthsRaw = _safeList(pendingItem['months']);
    for (var m in monthsRaw) {
      selectedMonths.add(m.toString());
    }

    String initialDate =
        pendingItem['paymentDate']?.toString() ??
        DateTime.now().toIso8601String().split('T').first;
    if (initialDate.contains('T'))
      initialDate = initialDate.split('T').first;
    else if (initialDate.contains(' '))
      initialDate = initialDate.split(' ').first;

    TextEditingController dateController = TextEditingController(
      text: initialDate,
    );
    TextEditingController amountController = TextEditingController();

    String selectedReason = "Monthly Membership Fee";
    String selectedMethod = "Bank Transfer";

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Approve Payment Record"),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Year Selection
                      const Text(
                        "Select Year for Payment:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedYear,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items:
                            List.generate(
                                  7,
                                  (index) => (2024 + index).toString(),
                                ) // 2024 to 2030
                                .map(
                                  (y) => DropdownMenuItem(
                                    value: y,
                                    child: Text(y),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => setState(() => selectedYear = val!),
                      ),
                      const SizedBox(height: 16),

                      // Months Selection
                      const Text(
                        "Select Paid Months:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: allMonths.map((m) {
                          final isSelected = selectedMonths.contains(m);
                          return FilterChip(
                            label: Text(m),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  selectedMonths.add(m);
                                } else {
                                  selectedMonths.remove(m);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Date and Amount
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Payment Date",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: dateController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    hintText: "YYYY-MM-DD",
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Amount (LKR)",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    hintText: "Enter Amount",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Reason and Method
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Reason",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: selectedReason,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items:
                                      [
                                            "Monthly Membership Fee",
                                            "Annual Fee",
                                            "Other",
                                          ]
                                          .map(
                                            (r) => DropdownMenuItem(
                                              value: r,
                                              child: Text(r),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (val) =>
                                      setState(() => selectedReason = val!),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Payment Method",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: selectedMethod,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: ["Cash", "Bank Transfer", "Card"]
                                      .map(
                                        (m) => DropdownMenuItem(
                                          value: m,
                                          child: Text(m),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => selectedMethod = val!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (selectedMonths.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please select at least one month!"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (amountController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter the amount!"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    _confirmApproveAppPayment(
                      context,
                      membershipNo,
                      pendingItem,
                      selectedYear,
                      selectedMonths,
                      dateController.text.trim(),
                      amountController.text.trim(),
                      selectedReason,
                      selectedMethod,
                    );
                  },
                  child: const Text("Confirm & Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmApproveAppPayment(
    BuildContext context,
    String documentId,
    Map<String, dynamic> paymentRecord,
    String year,
    List<String> months,
    String date,
    String amount,
    String reason,
    String method,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('app_membership_fee')
          .doc(documentId);

      List<Map<String, dynamic>> approvedRecords = [];
      for (String m in months) {
        approvedRecords.add({
          'month': m,
          'year': year,
          'date': date,
          'amount': amount,
          'reason': reason,
          'type': method,
          'status': 'approved',
          'approvedAt': DateTime.now().toIso8601String(),
          'source': 'app',
          'slipUrl': paymentRecord['slipUrl'],
        });
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.set(docRef, {
          'pending_payments': FieldValue.arrayRemove([paymentRecord]),
          'payment_history': FieldValue.arrayUnion(approvedRecords),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("App Upload Approved!"),
            backgroundColor: Colors.green,
          ),
        );
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
    }
  }

  Future<void> _rejectAppPayment(
    BuildContext context,
    String documentId,
    Map<String, dynamic> paymentRecord,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('app_membership_fee')
          .doc(documentId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.set(docRef, {
          'pending_payments': FieldValue.arrayRemove([paymentRecord]),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("App Upload Rejected."),
            backgroundColor: Colors.red,
          ),
        );
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
    }
  }

  Future<void> _approveWebPayment(
    BuildContext context,
    String documentId,
    Map<String, dynamic> webPaymentRecord,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('app_membership_fee')
          .doc(documentId);
      final approvedRecord = Map<String, dynamic>.from(webPaymentRecord);
      approvedRecord['status'] = 'approved';
      approvedRecord['approvedAt'] = DateTime.now().toIso8601String();
      approvedRecord['source'] = 'web';

      await docRef.set({
        'payment_history': FieldValue.arrayUnion([approvedRecord]),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Web Sync Approved!"),
            backgroundColor: Colors.blue,
          ),
        );
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
    }
  }

  Future<void> _showEditPaymentDialog(
    BuildContext context,
    String membershipNo,
    Map<String, dynamic> oldRecord,
  ) async {
    final currentYear = DateTime.now().year.toString();
    String selectedYear = oldRecord['year']?.toString() ?? currentYear;

    final allMonths = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    List<String> selectedMonths = [];
    if (oldRecord.containsKey('months')) {
      final monthsRaw = _safeList(oldRecord['months']);
      for (var m in monthsRaw) selectedMonths.add(m.toString());
    } else if (oldRecord.containsKey('month')) {
      selectedMonths.add(oldRecord['month'].toString());
    }

    String pd =
        oldRecord['paymentDate']?.toString() ??
        oldRecord['date']?.toString() ??
        '';
    if (pd.contains('T'))
      pd = pd.split('T')[0];
    else if (pd.contains(' '))
      pd = pd.split(' ')[0];
    TextEditingController dateController = TextEditingController(text: pd);
    TextEditingController amountController = TextEditingController(
      text: oldRecord['amount']?.toString() ?? '',
    );

    String selectedReason = oldRecord['reason'] ?? "Monthly Membership Fee";
    String selectedMethod =
        oldRecord['type'] ??
        "Cash"; // Default to Cash if not set, or Bank Transfer

    // Ensure the reason and method exist in the dropdown lists to prevent errors
    if (![
      "Monthly Membership Fee",
      "Annual Fee",
      "Other",
    ].contains(selectedReason))
      selectedReason = "Other";
    if (!["Cash", "Bank Transfer", "Card"].contains(selectedMethod))
      selectedMethod = "Cash";

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Edit Payment Record"),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Year Selection
                      const Text(
                        "Select Year for Payment:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedYear,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items:
                            List.generate(
                                  7,
                                  (index) => (2024 + index).toString(),
                                ) // 2024 to 2030
                                .map(
                                  (y) => DropdownMenuItem(
                                    value: y,
                                    child: Text(y),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) => setState(() => selectedYear = val!),
                      ),
                      const SizedBox(height: 16),

                      // Months Selection
                      const Text(
                        "Select Paid Months:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: allMonths.map((m) {
                          final isSelected = selectedMonths.contains(m);
                          return FilterChip(
                            label: Text(m),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  selectedMonths.add(m);
                                } else {
                                  selectedMonths.remove(m);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Date and Amount
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Payment Date",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: dateController,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    hintText: "YYYY-MM-DD",
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Amount (LKR)",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    hintText: "Enter Amount",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Reason and Method
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Reason",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: selectedReason,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items:
                                      [
                                            "Monthly Membership Fee",
                                            "Annual Fee",
                                            "Other",
                                          ]
                                          .map(
                                            (r) => DropdownMenuItem(
                                              value: r,
                                              child: Text(r),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (val) =>
                                      setState(() => selectedReason = val!),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Payment Method",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: selectedMethod,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: ["Cash", "Bank Transfer", "Card"]
                                      .map(
                                        (m) => DropdownMenuItem(
                                          value: m,
                                          child: Text(m),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => selectedMethod = val!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (selectedMonths.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please select at least one month!"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (amountController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter the amount!"),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    _confirmEditPaymentRecord(
                      context,
                      membershipNo,
                      oldRecord,
                      selectedYear,
                      selectedMonths,
                      dateController.text.trim(),
                      amountController.text.trim(),
                      selectedReason,
                      selectedMethod,
                    );
                  },
                  child: const Text("Update Record"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmEditPaymentRecord(
    BuildContext context,
    String documentId,
    Map<String, dynamic> oldRecord,
    String year,
    List<String> months,
    String date,
    String amount,
    String reason,
    String method,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('app_membership_fee')
          .doc(documentId);

      List<Map<String, dynamic>> newRecords = [];
      for (String m in months) {
        newRecords.add({
          'month': m,
          'year': year,
          'date': date,
          'amount': amount,
          'reason': reason,
          'type': method,
          'status': oldRecord['status'] ?? 'approved',
          'approvedAt':
              oldRecord['approvedAt'] ?? DateTime.now().toIso8601String(),
          'source': oldRecord['source'] ?? 'admin_edit',
          'slipUrl': oldRecord['slipUrl'], // Retain the old slip URL if any
        });
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        List<dynamic> history = _safeList(data['payment_history']).toList();

        // Remove oldRecord by checking deep equality keys
        history.removeWhere((item) {
          if (item is! Map) return false;
          if (item.length != oldRecord.length) return false;
          for (var key in oldRecord.keys) {
            if (item[key] != oldRecord[key]) return false;
          }
          return true;
        });

        // Add new records
        history.addAll(newRecords);

        transaction.update(docRef, {
          'payment_history': history,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });

      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment Record Updated Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
    }
  }

  Future<void> _deletePaymentRecord(
    BuildContext context,
    String documentId,
    Map<String, dynamic> record,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Record"),
        content: const Text(
          "Are you sure you want to permanently delete this payment record from the history?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('app_membership_fee')
          .doc(documentId);
      await docRef.set({
        'payment_history': FieldValue.arrayRemove([record]),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Record Deleted!"),
            backgroundColor: Colors.red,
          ),
        );
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
    }
  }

  void _showSlipImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => Container(
                  width: 300,
                  height: 300,
                  color: Colors.white,
                  child: const Center(child: Text("Error loading")),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
