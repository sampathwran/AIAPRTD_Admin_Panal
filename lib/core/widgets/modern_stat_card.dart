import 'package:flutter/material.dart';
import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';

class ModernStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Widget? bottomWidget;

  const ModernStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: AdminText.title.copyWith(fontSize: 18, height: 1.1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: AdminText.body.copyWith(fontWeight: FontWeight.w600, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (bottomWidget != null) ...[
                  DefaultTextStyle(
                    style: AdminText.body.copyWith(fontSize: 9, color: AdminColors.muted),
                    child: bottomWidget!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
