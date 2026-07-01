import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class KycRequestProvider with ChangeNotifier {
  StreamSubscription<QuerySnapshot>? _kycSubscription;

  bool _isLoading = false;
  List<Map<String, dynamic>> _allKycRequests = [];

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get allKycRequests => _allKycRequests;

  // =========================================================================
  // 📊 GETTERS: STATUS SEPARATION (Pending, Approved, Rejected)
  // =========================================================================
  List<Map<String, dynamic>> get pendingRequests =>
      _allKycRequests.where((k) => k['status'] == 'pending').toList();

  List<Map<String, dynamic>> get approvedRequests =>
      _allKycRequests.where((k) => k['status'] == 'approved').toList();

  List<Map<String, dynamic>> get rejectedRequests =>
      _allKycRequests.where((k) => k['status'] == 'rejected').toList();

  int get totalPendingCount => pendingRequests.length;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // =========================================================================
  // 📡 REAL-TIME KYC STREAMING FROM 'verify_kyc' COLLECTION
  // =========================================================================
  void startListeningToKycRequests() {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    debugPrint("🔄 KYC PROVIDER: startListeningToKycRequests() කෝල් වුණා මචං!");

    if (_kycSubscription != null) {
      _kycSubscription?.cancel();
    }

    setLoading(true);

    _kycSubscription = firestore.collection('verify_kyc').snapshots().listen(
          (querySnapshot) {
        debugPrint("🔥 KYC PROVIDER: ඩේටාබේස් එකෙන් ලයිව් සිග්නල් එකක් ආවා!");

        _allKycRequests = querySnapshot.docs.map((doc) {
          final Map<String, dynamic> data = Map<String, dynamic>.from(doc.data());
          data['doc_id'] = doc.id;

          // 🛠️ SAFETY LAYER: Null Values හැන්ඩල් කිරීම
          data['membershipNo'] = data['membershipNo']?.toString() ?? '-';
          data['fullName'] = data['fullName']?.toString() ?? 'Unknown';
          data['user_email'] = data['user_email']?.toString() ?? '-';
          data['mobile'] = data['mobile']?.toString() ?? '-';
          data['nic'] = data['nic']?.toString() ?? '-';
          data['address'] = data['address']?.toString() ?? '-';
          data['dob'] = data['dob']?.toString() ?? '-';
          data['religion'] = data['religion']?.toString() ?? '-';

          // 📸 පින්තූර ලින්ක්ස් (Face & ID Cards)
          data['idCardFrontUrl'] = data['idCardFrontUrl']?.toString() ?? '';
          data['idCardBackUrl'] = data['idCardBackUrl']?.toString() ?? '';
          data['faceVerificationUrl'] = data['faceVerificationUrl']?.toString() ?? '';

          // 🟢 ස්ටේටස්
          data['status'] = data['status']?.toString() ?? 'pending';

          // 🕒 වෙලාව හැන්ඩල් කිරීම
          if (data['submittedAt'] != null && data['submittedAt'] is Timestamp) {
            data['submittedAt'] = (data['submittedAt'] as Timestamp).toDate().toString();
          } else {
            data['submittedAt'] = 'Unknown Time';
          }

          return data;
        }).toList();

        _isLoading = false;
        notifyListeners(); // 💡 UI එකට ලයිව් ඩේටා යවනවා
      },
      onError: (error) {
        debugPrint("❌ KYC PROVIDER ERROR: Firebase Error: $error");
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _kycSubscription?.cancel();
    super.dispose();
  }
}