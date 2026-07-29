import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class WithdrawalRequestsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream for pending requests
  Stream<List<Map<String, dynamic>>> streamPendingRequests() {
    return _firestore
        .collection('withdrawal_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Stream for approved/rejected requests (History)
  Stream<List<Map<String, dynamic>>> streamRequestHistory() {
    return _firestore
        .collection('withdrawal_requests')
        .where('status', whereIn: ['approved', 'rejected'])
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  // Get current savings balance of a member
  Future<double> getMemberSavingsBalance(String memberId) async {
    try {
      final doc = await _firestore.collection('member').doc(memberId).get();
      if (doc.exists) {
        return (doc.data()?['savingsBalance'] ?? 0.0).toDouble();
      }
    } catch (e) {
      debugPrint("Error fetching savings balance: $e");
    }
    return 0.0;
  }

  // Approve a withdrawal request
  Future<void> approveWithdrawal(String requestId, String memberId) async {
    final batch = _firestore.batch();

    // 1. Update request status
    final reqRef = _firestore.collection('withdrawal_requests').doc(requestId);
    batch.update(reqRef, {
      'status': 'approved',
      'processedAt': FieldValue.serverTimestamp(),
    });

    // 2. Add notification for member
    final notifRef = _firestore.collection('notifications').doc();
    batch.set(notifRef, {
      'title': 'Withdrawal Approved',
      'message': 'The amount will be credited to your account very soon.',
      'targetType': 'specific',
      'targetMembers': [memberId],
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Reject a withdrawal request and refund savings balance
  Future<void> rejectWithdrawal(
    String requestId,
    String memberId,
    double amount,
    String reason,
  ) async {
    final batch = _firestore.batch();

    // 1. Update request status
    final reqRef = _firestore.collection('withdrawal_requests').doc(requestId);
    batch.update(reqRef, {
      'status': 'rejected',
      'rejectReason': reason,
      'processedAt': FieldValue.serverTimestamp(),
    });

    // 2. Refund savings balance
    final memberRef = _firestore.collection('member').doc(memberId);
    batch.update(memberRef, {'savingsBalance': FieldValue.increment(amount)});

    // 3. Add notification for member
    final notifRef = _firestore.collection('notifications').doc();
    batch.set(notifRef, {
      'title': 'Withdrawal Rejected',
      'message':
          'Your withdrawal request was rejected. Reason: $reason. The amount has been refunded to your Savings Balance.',
      'targetType': 'specific',
      'targetMembers': [memberId],
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
