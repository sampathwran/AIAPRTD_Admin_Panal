import 'package:flutter/material.dart';
import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/menu/driver_menu_constants.dart';

class AdminSidebar extends StatefulWidget {
  final String currentRoute;
  final List<AdminMenuItem> menuItems;
  final ValueChanged<String> onMenuSelected;
  final bool isDriverMode;
  final VoidCallback onToggleMode;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final Map<String, int> menuBadges;

  const AdminSidebar({
    super.key,
    required this.currentRoute,
    required this.menuItems,
    required this.onMenuSelected,
    required this.isDriverMode,
    required this.onToggleMode,
    required this.isCollapsed,
    required this.onToggleCollapse,
    this.menuBadges = const {},
  });

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  // Keep track of expanded state for items with children
  final Map<String, bool> _expandedState = {};

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isDriverMode ? AdminColors.driver : AdminColors.passenger;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: widget.isCollapsed ? 84 : 276,
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
                    child: const Icon(Icons.local_taxi_rounded, color: AdminColors.ink, size: 24),
                  ),
                  if (!widget.isCollapsed) ...[
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
                    message: widget.isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
                    child: IconButton(
                      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                      padding: EdgeInsets.zero,
                      onPressed: widget.onToggleCollapse,
                      icon: Icon(
                        widget.isCollapsed ? Icons.keyboard_double_arrow_right_rounded : Icons.keyboard_double_arrow_left_rounded,
                        color: const Color(0xFFD1D5DB),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.isCollapsed)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: _ModeSwitch(
                  isDriverMode: widget.isDriverMode,
                  accentColor: accentColor,
                  onTap: widget.onToggleMode,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Tooltip(
                  message: widget.isDriverMode ? 'Drivers zone' : 'Passengers zone',
                  child: InkWell(
                    onTap: widget.onToggleMode,
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
                        widget.isDriverMode ? Icons.badge_rounded : Icons.groups_2_rounded,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            const Divider(color: AdminColors.sidebarLine, height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
                itemCount: widget.menuItems.length,
                itemBuilder: (context, index) {
                  return _buildMenuItem(widget.menuItems[index], accentColor);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(AdminMenuItem item, Color accentColor) {
    if (item.children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: _SidebarItemWidget(
          item: item,
          isSelected: widget.currentRoute == item.route,
          isCollapsed: widget.isCollapsed,
          accentColor: accentColor,
          badgeCount: widget.menuBadges[item.title],
          onTap: () => widget.onMenuSelected(item.route),
        ),
      );
    }

    // Has children (Nested Menu)
    final bool isExpanded = _expandedState[item.route] ?? false;
    
    // Check if any child is selected
    final bool isAnyChildSelected = item.children.any((child) => widget.currentRoute == child.route);

    if (widget.isCollapsed) {
      // In collapsed mode, we can't easily show an expansion tile.
      // We can just show the parent as a regular icon, clicking it expands the sidebar and opens the menu.
      return Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: _SidebarItemWidget(
          item: item,
          isSelected: isAnyChildSelected,
          isCollapsed: true,
          accentColor: accentColor,
          badgeCount: _getTotalBadgeCountForParent(item),
          onTap: () {
            widget.onToggleCollapse(); // Expand sidebar
            setState(() {
              _expandedState[item.route] = true;
            });
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Column(
        children: [
          _SidebarItemWidget(
            item: item,
            isSelected: isAnyChildSelected && !isExpanded, // Highlight parent only if collapsed
            isCollapsed: false,
            accentColor: accentColor,
            badgeCount: _getTotalBadgeCountForParent(item),
            hasChildren: true,
            isExpanded: isExpanded,
            onTap: () {
              setState(() {
                _expandedState[item.route] = !isExpanded;
              });
            },
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 4.0),
              child: Column(
                children: item.children.map((child) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: _SidebarItemWidget(
                      item: child,
                      isSelected: widget.currentRoute == child.route,
                      isCollapsed: false,
                      accentColor: accentColor,
                      badgeCount: widget.menuBadges[child.title],
                      isSubItem: true,
                      onTap: () => widget.onMenuSelected(child.route),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  int? _getTotalBadgeCountForParent(AdminMenuItem parent) {
    int total = 0;
    if (widget.menuBadges.containsKey(parent.title)) {
      total += widget.menuBadges[parent.title]!;
    }
    for (var child in parent.children) {
      if (widget.menuBadges.containsKey(child.title)) {
        total += widget.menuBadges[child.title]!;
      }
    }
    return total > 0 ? total : null;
  }
}

class _SidebarItemWidget extends StatelessWidget {
  final AdminMenuItem item;
  final bool isSelected;
  final bool isCollapsed;
  final Color accentColor;
  final int? badgeCount;
  final VoidCallback onTap;
  final bool hasChildren;
  final bool isExpanded;
  final bool isSubItem;

  const _SidebarItemWidget({
    required this.item,
    required this.isSelected,
    required this.isCollapsed,
    required this.accentColor,
    required this.onTap,
    this.badgeCount,
    this.hasChildren = false,
    this.isExpanded = false,
    this.isSubItem = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isCollapsed ? item.title : '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: isSubItem ? 40 : 46,
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 0 : (isSubItem ? 16 : 12),
          ),
          foregroundDecoration: (isSelected && !isSubItem)
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(color: accentColor, width: 3),
                  ),
                )
              : null,
          decoration: BoxDecoration(
            color: isSelected ? AdminColors.sidebarSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AdminColors.sidebarLine : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                item.icon,
                color: isSelected ? accentColor : AdminColors.faint,
                size: isSubItem ? 16 : 20,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AdminColors.faint,
                      fontSize: isSubItem ? 13 : 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                if (badgeCount != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (hasChildren) ...[
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                    color: AdminColors.faint,
                    size: 16,
                  ),
                ]
              ],
            ],
          ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: AdminColors.sidebarSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AdminColors.sidebarLine),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              left: isDriverMode ? 2 : 118,
              right: isDriverMode ? 118 : 2,
              top: 2,
              bottom: 2,
              child: Container(
                decoration: BoxDecoration(
                  color: AdminColors.sidebar,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.badge_rounded,
                          size: 14,
                          color: isDriverMode ? accentColor : AdminColors.faint,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Drivers',
                          style: TextStyle(
                            color: isDriverMode ? Colors.white : AdminColors.faint,
                            fontSize: 12,
                            fontWeight: isDriverMode ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.groups_2_rounded,
                          size: 14,
                          color: !isDriverMode ? accentColor : AdminColors.faint,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Passengers',
                          style: TextStyle(
                            color: !isDriverMode ? Colors.white : AdminColors.faint,
                            fontSize: 12,
                            fontWeight: !isDriverMode ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
