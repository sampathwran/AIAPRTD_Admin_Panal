import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/admin_booking_card.dart';
import '../../../widgets/admin_empty_booking_state.dart';
import '../../../widgets/booking_detail_dialog.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Completed Tab
// Card click → BookingDetailDialog (static pickup→drop route + time taken)
// ═══════════════════════════════════════════════════════════════════════════════

class CompletedTab extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  const CompletedTab({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return const AdminEmptyBookingState(
        title: 'No Completed Trips',
        subtitle: 'No trips have been completed for this category yet.',
      );
    }

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
          final raw = Map<String, dynamic>.from(
              docs[index].data() as Map<String, dynamic>);
          raw['bookingId'] = docs[index].id;

          return InkWell(
            onTap: () {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) => BookingDetailDialog(bookingData: raw),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: AdminBookingCard(data: raw),
          );
        },
      );
    });
  }
}
