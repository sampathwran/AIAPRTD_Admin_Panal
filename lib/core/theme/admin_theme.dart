import 'package:flutter/material.dart';

class AdminColors {
  // Main Theme Colors matching modern light dashboard
  static const ink = Color(0xFF111827);         // Dark text
  static const inkSoft = Color(0xFF374151);     // Slightly muted text
  static const muted = Color(0xFF6B7280);       // Muted/Subtitles
  static const faint = Color(0xFF9CA3AF);
  static const line = Color(0xFFE5E7EB);        // Card borders
  static const lineSoft = Color(0xFFF1F5F9);    
  static const canvas = Color(0xFFF4F7FB);      // App background (Light Gray)
  static const surface = Colors.white;          // Card background
  static const surfaceAlt = Color(0xFFF8FAFC);  
  static const sidebar = Color(0xFF0F172A);     // Sidebar background
  static const sidebarSoft = Color(0xFF1E293B); 
  static const sidebarLine = Color(0xFF263244); 
  
  // Accents
  static const primary = Color(0xFF7367F0);     // Modern Purple/Blue accent
  static const driver = Color(0xFFF59E0B);      // Orange
  static const passenger = Color(0xFF00E396);   // Bright Teal
  static const success = Color(0xFF00E396);     // Green/Teal
  static const danger = Color(0xFFFF4560);      // Bright Red
  static const warning = Color(0xFFFEB019);     // Yellow
  static const purple = Color(0xFF775DD0);      
}

class AdminShadows {
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AdminColors.ink.withValues(alpha: .045),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: AdminColors.ink.withValues(alpha: .07),
      blurRadius: 28,
      offset: const Offset(0, 18),
    ),
  ];
}

class AdminText {
  static const overline = TextStyle(
    color: AdminColors.muted,
    fontSize: 11,
    fontWeight: FontWeight.w900,
    letterSpacing: .8,
  );

  static const title = TextStyle(
    color: AdminColors.ink,
    fontSize: 20,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
  );

  static const body = TextStyle(
    color: AdminColors.muted,
    fontSize: 13,
    height: 1.45,
    letterSpacing: 0,
  );
}

class AdminSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final bool elevated;

  const AdminSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = AdminColors.surface,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.line),
        boxShadow: elevated ? AdminShadows.soft : null,
      ),
      child: child,
    );
  }
}

class AdminPageScaffold extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  final bool scrollable;

  const AdminPageScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AdminColors.canvas,
      child: scrollable
          ? SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: padding,
              child: child,
            )
          : Padding(
              padding: padding,
              child: child,
            ),
    );
  }
}

class AdminSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  const AdminSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AdminColors.primary.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AdminColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AdminText.title,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AdminText.body,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 16), trailing!],
      ],
    );
  }
}

class AdminStatusPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const AdminStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
