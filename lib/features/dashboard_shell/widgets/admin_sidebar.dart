import 'package:flutter/material.dart';

import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final List<String> menuTitles;
  final List<IconData> menuIcons;
  final ValueChanged<int> onMenuSelected;
  final bool isDriverMode;
  final VoidCallback onToggleMode;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.menuTitles,
    required this.menuIcons,
    required this.onMenuSelected,
    required this.isDriverMode,
    required this.onToggleMode,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isDriverMode
        ? AdminColors.driver
        : AdminColors.passenger;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: isCollapsed ? 84 : 276,
      decoration: const BoxDecoration(
        color: AdminColors.sidebar,
        border: Border(right: BorderSide(color: AdminColors.sidebarLine)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_taxi_rounded,
                      color: AdminColors.ink,
                      size: 24,
                    ),
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AIAPRTD',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Admin Command',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AdminColors.faint,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Tooltip(
                    message: isCollapsed
                        ? 'Expand sidebar'
                        : 'Collapse sidebar',
                    child: IconButton(
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 36,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: onToggleCollapse,
                      icon: Icon(
                        isCollapsed
                            ? Icons.keyboard_double_arrow_right_rounded
                            : Icons.keyboard_double_arrow_left_rounded,
                        color: const Color(0xFFD1D5DB),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isCollapsed)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: _ModeSwitch(
                  isDriverMode: isDriverMode,
                  accentColor: accentColor,
                  onTap: onToggleMode,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Tooltip(
                  message: isDriverMode ? 'Drivers zone' : 'Passengers zone',
                  child: InkWell(
                    onTap: onToggleMode,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AdminColors.sidebarSoft,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AdminColors.sidebarLine),
                      ),
                      child: Icon(
                        isDriverMode
                            ? Icons.badge_rounded
                            : Icons.groups_2_rounded,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            const Divider(color: AdminColors.sidebarLine, height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
                itemCount: menuTitles.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final isSelected = selectedIndex == index;
                  final title = menuTitles[index];
                  final icon = menuIcons[index];

                  return Tooltip(
                    message: isCollapsed ? title : '',
                    child: InkWell(
                      onTap: () => onMenuSelected(index),
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 46,
                        padding: EdgeInsets.symmetric(
                          horizontal: isCollapsed ? 0 : 12,
                        ),
                        foregroundDecoration: isSelected
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border(
                                  left: BorderSide(
                                    color: accentColor,
                                    width: 3,
                                  ),
                                ),
                              )
                            : null,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AdminColors.sidebarSoft
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AdminColors.sidebarLine
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: isCollapsed
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          children: [
                            Icon(
                              icon,
                              color: isSelected
                                  ? accentColor
                                  : AdminColors.faint,
                              size: 20,
                            ),
                            if (!isCollapsed) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFFD1D5DB),
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: accentColor,
                                  size: 18,
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isCollapsed ? 0 : 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1220),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AdminColors.sidebarLine),
                ),
                child: isCollapsed
                    ? const Icon(
                        Icons.verified_user_rounded,
                        color: AdminColors.faint,
                        size: 18,
                      )
                    : const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Super Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'v1.0 live console',
                            style: TextStyle(
                              color: AdminColors.faint,
                              fontSize: 11,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  final bool isDriverMode;
  final Color accentColor;
  final VoidCallback onTap;

  const _ModeSwitch({
    required this.isDriverMode,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1220),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AdminColors.sidebarLine),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: isDriverMode
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                _ModeLabel(
                  label: 'Drivers',
                  icon: Icons.badge_rounded,
                  selected: isDriverMode,
                ),
                _ModeLabel(
                  label: 'Passengers',
                  icon: Icons.groups_2_rounded,
                  selected: !isDriverMode,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;

  const _ModeLabel({
    required this.label,
    required this.icon,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? AdminColors.ink : AdminColors.faint,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AdminColors.ink : AdminColors.faint,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
