import 'package:flutter/material.dart';

import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';
import 'package:aiaprtd_admin_dashboard/core/widgets/modern_chart_card.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/widgets/dashboard_stats_grid.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/drivers_overview/live_tracking_map.dart';

class OverviewPanel extends StatefulWidget {
  final Function(String pageTitle) onSubPageSelected;

  const OverviewPanel({super.key, required this.onSubPageSelected});

  @override
  State<OverviewPanel> createState() => _OverviewPanelState();
}

class _OverviewPanelState extends State<OverviewPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.canvas,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _OverviewHeader(),
            const SizedBox(height: 24),
            DashboardStatsGrid(onCardTap: widget.onSubPageSelected),
            const SizedBox(height: 24),
            _OperationsPulse(),
            const SizedBox(height: 24),
            const _LiveMapSection(),
          ],
        ),
      ),
    );
  }
}

class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader();

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminStatusPill(
                  label: 'LIVE TAXI OPERATIONS',
                  color: AdminColors.driver,
                ),
                const SizedBox(height: 14),
                Text(
                  'Driver network overview',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminText.title.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  'Monitor members, bookings, support pressure, and live vehicle movement from one clean console.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AdminText.body,
                ),
              ],
            ),
          ),
          if (MediaQuery.of(context).size.width > 600)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AdminColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.data_usage_rounded,
                size: 64,
                color: AdminColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _OperationsPulse extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ModernChartCard(
      title: 'Operations Pulse',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final items = [
            _buildPulseItem(
              'High demand zones',
              'Colombo 07, Airport',
              0.85,
              AdminColors.danger,
              Icons.local_fire_department_rounded,
            ),
            _buildPulseItem(
              'Idle vehicles',
              'Ready for dispatch',
              0.4,
              AdminColors.warning,
              Icons.local_parking_rounded,
            ),
            _buildPulseItem(
              'Ongoing rides',
              'Passengers on board',
              0.65,
              AdminColors.success,
              Icons.directions_car_rounded,
            ),
          ];

          if (constraints.maxWidth > 800) {
            return Row(
              children: [
                Expanded(child: items[0]),
                const SizedBox(width: 32),
                Expanded(child: items[1]),
                const SizedBox(width: 32),
                Expanded(child: items[2]),
              ],
            );
          } else {
            return Column(
              children: [
                items[0],
                const SizedBox(height: 16),
                items[1],
                const SizedBox(height: 16),
                items[2],
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildPulseItem(
      String title, String detail, double progress, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AdminText.body.copyWith(
                          color: AdminColors.ink, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(progress * 100).round()}%',
                    style: AdminText.body.copyWith(
                        color: color, fontWeight: FontWeight.w900, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 6,
                  backgroundColor: AdminColors.line,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AdminText.body.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveMapSection extends StatefulWidget {
  const _LiveMapSection();

  @override
  State<_LiveMapSection> createState() => _LiveMapSectionState();
}

class _LiveMapSectionState extends State<_LiveMapSection> {
  String _selectedCategory = 'All';
  Map<String, int> _categoryCounts = {};

  final List<Map<String, String>> _categories = [
    {'id': 'All', 'label': 'All'},
    {'id': 'budget', 'label': 'Budget'},
    {'id': 'mini', 'label': 'Mini'},
    {'id': 'sedan', 'label': 'Sedan'},
    {'id': '6_seater', 'label': '6 Seater'},
    {'id': '9_seater', 'label': '9 Seater'},
    {'id': '14_seater', 'label': '14 Seater'},
  ];

  @override
  Widget build(BuildContext context) {
    return ModernChartCard(
      title: 'Live Tracking Map',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdminStatusPill(
            label: 'Live',
            color: AdminColors.success,
            icon: Icons.sensors_rounded,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Realtime driver positions and online state',
                style: AdminText.body,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat['id'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat['id']!;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AdminColors.primary : AdminColors.canvas,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AdminColors.primary : AdminColors.line,
                        ),
                      ),
                      child: Text(
                        "${cat['label']!} ${_categoryCounts[cat['id']] != null ? '(${_categoryCounts[cat['id']]})' : ''}",
                        style: TextStyle(
                          color: isSelected ? Colors.white : AdminColors.muted,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 550, // Increased height for full-width map
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LiveTrackingMap(
                selectedCategory: _selectedCategory,
                onCountsUpdated: (counts) {
                  if (mounted) {
                    setState(() {
                      _categoryCounts = counts;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
