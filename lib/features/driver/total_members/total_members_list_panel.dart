// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aiaprtd_admin_dashboard/core/providers/member_provider.dart';
import 'package:aiaprtd_admin_dashboard/core/providers/profile_image_provider.dart';
import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';
import 'package:aiaprtd_admin_dashboard/core/utils/status_helpers.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/total_members/member_profile_cards.dart';

class TotalMembersListPanel extends StatefulWidget {
  const TotalMembersListPanel({super.key});

  @override
  State<TotalMembersListPanel> createState() => _TotalMembersListPanelState();
}

class _TotalMembersListPanelState extends State<TotalMembersListPanel> {
  Map<String, dynamic>? _selectedMember;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileImageProvider>().startListeningToProfileImages();
      final memberProvider = context.read<MemberProvider>();
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
      return SelectionArea(child: _buildProfileView(_selectedMember!));
    }

    final memberProvider = context.watch<MemberProvider>();
    final filteredMembers = memberProvider.allMembersList.where((member) {
      final membershipNo = (member['membershipNo'] ?? '')
          .toString()
          .toLowerCase();
      final fullName = (member['fullName'] ?? '').toString().toLowerCase();
      final mobile = (member['mobile'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return membershipNo.contains(query) ||
          fullName.contains(query) ||
          mobile.contains(query);
    }).toList();

    final activeCount = filteredMembers.where((d) {
      final statusResult = calculateMemberStatus(d);
      return statusResult['isActive'] == true;
    }).length;
    final onlineCount = filteredMembers.where((d) {
      return d['isOnline'] == true || d['onlineStatus'] == 'online';
    }).length;

    return AdminPageScaffold(
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            title: 'Registered members directory',
            subtitle:
                'Search, inspect, and open complete driver master profiles from a structured member table.',
            icon: Icons.people_alt_rounded,
            trailing: AdminStatusPill(
              label: '${filteredMembers.length} RECORDS',
              icon: Icons.storage_rounded,
              color: AdminColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          _DirectoryToolbar(
            controller: _searchController,
            query: _searchQuery,
            total: filteredMembers.length,
            active: activeCount,
            online: onlineCount,
            onChanged: (value) => setState(() => _searchQuery = value),
            onClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            onRefresh: () async {
              await memberProvider.syncAllMembersStatus();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Member statuses synced with database')),
                );
              }
            },
            isLoading: memberProvider.isLoading,
          ),
          const SizedBox(height: 14),
          Expanded(
            child: memberProvider.isLoading
                ? const AdminSurface(
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : filteredMembers.isEmpty
                ? const AdminSurface(
                    child: Center(
                      child: Text(
                        'No registered members found.',
                        style: TextStyle(color: AdminColors.muted),
                      ),
                    ),
                  )
                : _MembersTable(
                    members: filteredMembers,
                    verticalController: _verticalController,
                    horizontalController: _horizontalController,
                    onOpenMember: (member) {
                      setState(() => _selectedMember = member);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView(Map<String, dynamic> member) {
    return AdminPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            title: 'Member master profile',
            subtitle:
                '${member['membershipNo'] ?? '-'} · ${member['fullName'] ?? 'Unknown member'}',
            icon: Icons.badge_rounded,
            trailing: OutlinedButton.icon(
              onPressed: () => setState(() => _selectedMember = null),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back to directory'),
            ),
          ),
          const SizedBox(height: 18),
          ProfileHeaderCard(memberData: member),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumn = constraints.maxWidth >= 980;
              final left = Column(
                children: [
                  PersonalDetailsCard(memberData: member),
                  const SizedBox(height: 16),
                ],
              );
              final right = Column(
                children: [
                  VehicleInfoCard(memberData: member),
                  const SizedBox(height: 16),
                  BankDetailsCard(memberData: member),
                  const SizedBox(height: 16),
                ],
              );

              if (!twoColumn) {
                return Column(children: [left, right]);
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 16),
                  Expanded(child: right),
                ],
              );
            },
          ),
          PaymentHistoryCard(memberData: member),
        ],
      ),
    );
  }
}

class _DirectoryToolbar extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final int total;
  final int active;
  final int online;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onRefresh;
  final bool isLoading;

  const _DirectoryToolbar({
    required this.controller,
    required this.query,
    required this.total,
    required this.active,
    required this.online,
    required this.onChanged,
    required this.onClear,
    required this.onRefresh,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      elevated: true,
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 780;
          final search = TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Search membership number, name, or phone',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: query.isEmpty
                  ? null
                  : Tooltip(
                      message: 'Clear search',
                      child: IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: onClear,
                      ),
                    ),
            ),
          );
          final stats = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminStatusPill(
                label: '$total TOTAL',
                icon: Icons.storage_rounded,
                color: AdminColors.primary,
              ),
              AdminStatusPill(
                label: '$active ACTIVE',
                icon: Icons.verified_rounded,
                color: AdminColors.success,
              ),
              AdminStatusPill(
                label: '$online ONLINE',
                icon: Icons.sensors_rounded,
                color: AdminColors.passenger,
              ),
              Container(
                margin: const EdgeInsets.only(left: 8),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AdminColors.primary,
                        ),
                      )
                    : Tooltip(
                        message: 'Sync Member Status',
                        child: IconButton(
                          icon: const Icon(Icons.sync_rounded, color: AdminColors.primary, size: 22),
                          onPressed: onRefresh,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [search, const SizedBox(height: 12), stats],
            );
          }

          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 16),
              stats,
            ],
          );
        },
      ),
    );
  }
}

class _MembersTable extends StatelessWidget {
  final List<Map<String, dynamic>> members;
  final ScrollController verticalController;
  final ScrollController horizontalController;
  final ValueChanged<Map<String, dynamic>> onOpenMember;

  const _MembersTable({
    required this.members,
    required this.verticalController,
    required this.horizontalController,
    required this.onOpenMember,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      padding: EdgeInsets.zero,
      elevated: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            controller: horizontalController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: horizontalController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: constraints.maxWidth > 760 ? constraints.maxWidth : 760,
                child: Column(
                  children: [
                    const _TableHeader(),
                    const Divider(height: 1, color: AdminColors.line),
                    Expanded(
                      child: Scrollbar(
                        controller: verticalController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        child: ListView.separated(
                          controller: verticalController,
                          physics: const BouncingScrollPhysics(),
                          itemCount: members.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1, color: AdminColors.lineSoft),
                          itemBuilder: (context, index) {
                            final member = members[index];
                            return _MemberRow(
                              member: member,
                              onOpen: () => onOpenMember(member),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: AdminColors.surfaceAlt,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: const Row(
        children: [
          Expanded(flex: 2, child: _HeaderText('Membership No')),
          Expanded(flex: 3, child: _HeaderText('Full Name')),
          Expanded(flex: 2, child: _HeaderText('Status')),
          Expanded(flex: 2, child: _HeaderText('Connection')),
          SizedBox(width: 100, child: _HeaderText('Action')),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String label;

  const _HeaderText(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AdminText.overline);
  }
}

class _MemberRow extends StatelessWidget {
  final Map<String, dynamic> member;
  final VoidCallback onOpen;

  const _MemberRow({required this.member, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final statusResult = calculateMemberStatus(member);
    final bool isActive = statusResult['isActive'] == true;
    final String inactiveReason = statusResult['reason'] ?? '';
    final String statusText = isActive 
        ? 'ACTIVE MEMBER' 
        : (inactiveReason.isNotEmpty ? 'INACTIVE: $inactiveReason' : 'INACTIVE MEMBER');

    final bool isOnline =
        member['isOnline'] == true || member['onlineStatus'] == 'online';

    Color statusColor = isActive ? AdminColors.success : AdminColors.warning;
    IconData statusIcon = isActive ? Icons.verified_rounded : Icons.pending_rounded;

    return SizedBox(
      height: 52,
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    member['membershipNo']?.toString() ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AdminColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Text(
                      member['fullName']?.toString() ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AdminColors.inkSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Tooltip(
                      message: isActive 
                          ? 'Active Member'
                          : inactiveReason.isNotEmpty 
                              ? inactiveReason 
                              : 'Inactive Member',
                      child: AdminStatusPill(
                        label: statusText,
                        icon: statusIcon,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AdminStatusPill(
                      label: isOnline ? 'ONLINE' : 'OFFLINE',
                      icon: isOnline
                          ? Icons.sensors_rounded
                          : Icons.cloud_off_rounded,
                      color: isOnline ? AdminColors.passenger : AdminColors.muted,
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.visibility_rounded, size: 16),
                      label: const Text('View', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
