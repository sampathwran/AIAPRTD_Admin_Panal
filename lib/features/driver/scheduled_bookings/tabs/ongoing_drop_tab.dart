import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/scheduled_bookings/widgets/admin_booking_card.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/scheduled_bookings/widgets/admin_empty_booking_state.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/scheduled_bookings/widgets/booking_detail_dialog.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Ongoing Drop Tab
// Card click → BookingDetailDialog (live map: driver → drop-off point)
// ═══════════════════════════════════════════════════════════════════════════════

class OngoingDropTab extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  const OngoingDropTab({super.key, required this.docs});

  @override
  Widget build(BuildContext context) {
    if (docs.isEmpty) {
      return const AdminEmptyBookingState(
        title: 'No Ongoing Drop Trips',
        subtitle: 'No driver is currently dropping off a passenger.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
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
              docs[index].data() as Map<String, dynamic>,
            );
            raw['bookingId'] = docs[index].id;
            final status = (raw['status'] ?? '').toString().toLowerCase();
            final hasStarted =
                raw['startedAt'] != null || raw['tripStartTime'] != null;
            if (status == 'arrived' ||
                status == 'ongoing' ||
                status == 'ongoing drop' ||
                ((status == 'accepted' || status == 'ongoing pickup') &&
                    hasStarted)) {
              raw['status'] = 'ongoing drop';
            }

            final driverRef =
                (raw['acceptedBy'] ??
                        raw['driverId'] ??
                        raw['driverMembershipNo'] ??
                        '')
                    .toString();
            raw['acceptedBy'] = driverRef;

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
      },
    );
  }
}
