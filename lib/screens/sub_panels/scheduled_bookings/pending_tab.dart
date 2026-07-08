import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/admin_booking_card.dart';
import '../../../widgets/admin_empty_booking_state.dart';

/// Pending tab - no map needed, just list bookings
class PendingTab extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  const PendingTab({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return const AdminEmptyBookingState(
        title: 'No Pending Bookings',
        subtitle: 'There are no bookings waiting for a driver.',
      );
    }
    return _BookingGrid(
      docs: docs,
      onTap: null, // Pending → no special action
    );
  }
}

// ─── Shared grid used by all tabs ──────────────────────────────────────────────
class _BookingGrid extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final void Function(BuildContext ctx, Map<String, dynamic> data)? onTap;

  const _BookingGrid({required this.docs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final int cols = constraints.maxWidth > 1400
          ? 5
          : constraints.maxWidth > 1100
              ? 4
              : constraints.maxWidth > 800
                  ? 3
                  : 2;
      const double spacing = 16.0;
      const double itemHeight = 265.0;
      final double itemWidth =
          (constraints.maxWidth - spacing * (cols - 1)) / cols;
      final double ratio = itemWidth / itemHeight;

      return GridView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          childAspectRatio: ratio,
          crossAxisSpacing: spacing,
          mainAxisSpacing: 16,
        ),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final data = Map<String, dynamic>.from(
              docs[index].data() as Map<String, dynamic>);
          data['bookingId'] = docs[index].id;

          if (onTap != null) {
            return InkWell(
              onTap: () => onTap!(context, data),
              borderRadius: BorderRadius.circular(16),
              child: AdminBookingCard(data: data),
            );
          }
          return AdminBookingCard(data: data);
        },
      );
    });
  }
}
