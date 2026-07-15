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
      padding: const EdgeInsets.all(16), // Reduced from 20
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AdminText.body.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12), // Reduced from 16
          Expanded( // Wrap in Expanded to prevent overflow if height is small
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AdminText.title.copyWith(fontSize: 24), // Slightly smaller font
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (bottomWidget != null) ...[
            const SizedBox(height: 12), // Reduced from 16
            bottomWidget!,
          ],
        ],
      ),
    );
  }
}
