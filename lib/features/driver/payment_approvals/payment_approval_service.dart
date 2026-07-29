import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class PaymentApprovalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> approvePayment(
    String paymentId,
    String driverId,
    double amount,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final paymentRef = _firestore
            .collection('app_usage_payments')
            .doc(paymentId);
        final memberRef = _firestore.collection('member').doc(driverId);

        final memberSnapshot = await transaction.get(memberRef);
        final paymentSnapshot = await transaction.get(paymentRef);

        if (!paymentSnapshot.exists) {
          throw Exception("Payment not found");
        }

        final currentStatus = paymentSnapshot.data()?['status'] ?? 'pending';
        if (currentStatus != 'pending') {
          throw Exception("Payment already processed");
        }

        // Update payment status
        transaction.update(paymentRef, {
          'status': 'approved',
          'approvedAt': FieldValue.serverTimestamp(),
        });

        // Deduct from outstanding balance if member exists
        if (memberSnapshot.exists) {
          final currentBalance =
              (memberSnapshot.data()?['appUsageChargeBalance'] ?? 0.0)
                  .toDouble();
          final newBalance = (currentBalance - amount).clamp(
            0.0,
            double.infinity,
          );
          transaction.update(memberRef, {'appUsageChargeBalance': newBalance});
        }
      });
    } catch (e) {
      debugPrint("Error approving payment: $e");
      rethrow;
    }
  }

  Future<void> updateApprovedPayment(
    String paymentId,
    String driverId,
    double oldAmount,
    double newAmount,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final paymentRef = _firestore
            .collection('app_usage_payments')
            .doc(paymentId);
        final memberRef = _firestore.collection('member').doc(driverId);

        final memberSnapshot = await transaction.get(memberRef);
        final paymentSnapshot = await transaction.get(paymentRef);

        if (!paymentSnapshot.exists) {
          throw Exception("Payment not found");
        }

        final currentStatus = paymentSnapshot.data()?['status'];
        if (currentStatus != 'approved') {
          throw Exception("Only approved payments can be updated");
        }

        // Update payment amount
        transaction.update(paymentRef, {
          'amount': newAmount,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Adjust driver's outstanding balance
        if (memberSnapshot.exists) {
          final currentBalance =
              (memberSnapshot.data()?['appUsageChargeBalance'] ?? 0.0)
                  .toDouble();

          // Reverse the old amount (add it back), then deduct the new amount.
          // Example: balance=4000, old=1000, new=800 -> 4000 + 1000 - 800 = 4200.
          final newBalance = (currentBalance + oldAmount - newAmount).clamp(
            0.0,
            double.infinity,
          );

          transaction.update(memberRef, {'appUsageChargeBalance': newBalance});
        }
      });
    } catch (e) {
      debugPrint("Error updating payment: $e");
      rethrow;
    }
  }

  Future<void> rejectPayment(String paymentId, String reason) async {
    try {
      await _firestore.collection('app_usage_payments').doc(paymentId).update({
        'status': 'rejected',
        'rejectReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error rejecting payment: $e");
      rethrow;
    }
  }
}
