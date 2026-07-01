// ignore_for_file: spell_check_on_languages
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class ChangeBankDetailsProvider with ChangeNotifier {
  StreamSubscription<QuerySnapshot>? _bankSubscription;

  bool _isLoading = false;
  List<Map<String, dynamic>> _pendingRequests = [];

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get pendingRequests => _pendingRequests;
  int get totalPendingCount => _pendingRequests.length;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // =========================================================================
  // 📡 REAL-TIME STREAMING FROM 'verify_bank' COLLECTION
  // =========================================================================
  void startListeningToBankRequests() {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    if (_bankSubscription != null) {
      _bankSubscription?.cancel();
    }

    setLoading(true);

    _bankSubscription = firestore
        .collection('verify_bank')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen(
          (querySnapshot) {
        _pendingRequests = querySnapshot.docs.map((doc) {
          final Map<String, dynamic> data = Map<String, dynamic>.from(doc.data());
          data['doc_id'] = doc.id; // Usually membershipNo
          return data;
        }).toList();

        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("❌ Bank Request Provider Error: $error");
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _bankSubscription?.cancel();
    super.dispose();
  }

  // =========================================================================
  // ✅ APPROVE BANK REQUEST LOGIC
  // =========================================================================
  Future<bool> approveBankRequest(String membershipNo, Map<String, dynamic> data) async {
    try {
      final firestore = FirebaseFirestore.instance;
      WriteBatch batch = firestore.batch();

      // 1. 'verify_bank' එකේ status එක approved කරනවා
      batch.update(firestore.collection('verify_bank').doc(membershipNo), {
        'status': 'approved',
      });

      // 2. 'member' collection එක හොයාගෙන ඒක අප්ඩේට් කරනවා
      var memberSnapshot = await firestore.collection('member').where('membershipNo', isEqualTo: membershipNo).get();
      for (var doc in memberSnapshot.docs) {
        batch.update(doc.reference, {
          'bankName': data['bankName'],
          'branchName': data['branchName'],
          'accountNumber': data['accountNumber'],
          'accountHolderName': data['accountHolderName'],
          'bankUpdateStatus': 'approved', // Pending screen එක අයින් වෙන්න
        });
      }

      // 3. 'payments' collection එකේ Bank info update කරනවා (Member App එකේ PaymentProvider එක ඩේටා ගන්නේ මේකෙන්)
      batch.set(firestore.collection('payments').doc('${membershipNo}_bank'), {
        'membershipNo': membershipNo,
        'bankName': data['bankName'],
        'branchName': data['branchName'],
        'accountNumber': data['accountNumber'],
        'accountHolderName': data['accountHolderName'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint("Approval Error: $e");
      return false;
    }
  }

  // =========================================================================
  // ❌ REJECT BANK REQUEST LOGIC (UPDATED WITH REASON)
  // =========================================================================
  Future<bool> rejectBankRequest(String membershipNo, String reason) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. 'verify_bank' එක rejected කරනවා හේතුවත් එක්ක
      await firestore.collection('verify_bank').doc(membershipNo).update({
        'status': 'rejected',
        'rejectReason': reason, // 👈 හේතුව සේව් වෙනවා
      });

      // 2. 'member' එකේ pending status එක අයින් කරනවා
      var memberSnapshot = await firestore.collection('member').where('membershipNo', isEqualTo: membershipNo).get();
      for (var doc in memberSnapshot.docs) {
        await doc.reference.update({
          'bankUpdateStatus': 'rejected',
          'bankRejectReason': reason, // 👈 Member app එකට පෙන්නන්න මේක පාවිච්චි කරන්න පුළුවන්
        });
      }

      return true;
    } catch (e) {
      debugPrint("Reject Error: $e");
      return false;
    }
  }
}