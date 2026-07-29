import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class P2PTransfersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream for pending union payments
  Stream<List<Map<String, dynamic>>> streamPendingVerifications() {
    return _firestore
        .collection('p2p_debts')
        .where('status', isEqualTo: 'pending_admin_verification')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Stream for all P2P transactions
  Stream<List<Map<String, dynamic>>> streamAllP2PTransactions() {
    return _firestore
        .collection('p2p_debts')
        .orderBy('createdAt', descending: true)
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

  // Approve union payment
  Future<void> approveUnionPayment(String debtId, String creditorId, double amount) async {
    final batch = _firestore.batch();
    
    // 1. Update debt status
    final debtRef = _firestore.collection('p2p_debts').doc(debtId);
    batch.update(debtRef, {
      'status': 'settled',
      'settledAt': FieldValue.serverTimestamp(),
    });

    // 2. Add amount to creditor's savings balance
    final memberRef = _firestore.collection('member').doc(creditorId);
    batch.update(memberRef, {
      'savingsBalance': FieldValue.increment(amount),
    });

    // 3. Add notification for creditor
    final notifRef = _firestore.collection('notifications').doc();
    batch.set(notifRef, {
      'title': 'Commission Received',
      'message': 'Admin verified the Union payment for your shared trip. Rs.${amount.toStringAsFixed(2)} has been added to your Savings Balance.',
      'targetType': 'specific',
      'targetMembers': [creditorId],
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    // 4. Add transaction record for creditor
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final txnRef = _firestore
        .collection('finance_transactions')
        .doc(creditorId)
        .collection('history')
        .doc(dateStr)
        .collection('transactions')
        .doc();
        
    batch.set(txnRef, {
      'type': 'p2p_commission_received',
      'amount': amount,
      'debtId': debtId,
      'timestamp': FieldValue.serverTimestamp(),
      'description': 'Commission via Union Payment',
    });

    await batch.commit();
  }

  // Reject union payment (wait for re-upload)
  Future<void> rejectUnionPayment(String debtId, String debtorId, String reason) async {
    final batch = _firestore.batch();
    
    // 1. Set status back to pending so they can re-upload
    final debtRef = _firestore.collection('p2p_debts').doc(debtId);
    batch.update(debtRef, {
      'status': 'pending', // Revert to pending to allow re-upload
      'rejectReason': reason,
      'rejectedAt': FieldValue.serverTimestamp(),
    });

    // 2. Add notification for debtor
    final notifRef = _firestore.collection('notifications').doc();
    batch.set(notifRef, {
      'title': 'Payment Slip Rejected',
      'message': 'Your P2P payment slip was rejected by admin. Reason: $reason. Please upload a clear slip.',
      'targetType': 'specific',
      'targetMembers': [debtorId],
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
