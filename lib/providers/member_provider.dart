import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class MemberProvider with ChangeNotifier {
  StreamSubscription<QuerySnapshot>? _memberSubscription;

  int _selectedMenuIndex = 0;
  bool _isLoading = false;
  List<Map<String, dynamic>> _allMembersList = [];

  int get selectedMenuIndex => _selectedMenuIndex;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get allMembersList => _allMembersList;

  // =========================================================================
  // 🗺️ 1. NEW GETTERS: ONLINE / OFFLINE STATUS SEPARATION
  // =========================================================================
  List<Map<String, dynamic>> get onlineMembersList =>
      _allMembersList.where((m) => m['onlineStatus'] == 'online').toList();

  List<Map<String, dynamic>> get offlineMembersList =>
      _allMembersList.where((m) => m['onlineStatus'] == 'offline' || m['onlineStatus'] == null).toList();

  int get totalOnlineCount => onlineMembersList.length;
  int get totalOfflineCount => offlineMembersList.length;

  // =========================================================================
  // OLD GETTERS
  // =========================================================================
  List<Map<String, dynamic>> get activeMembersList =>
      _allMembersList.where((m) => m['status'] == 'active').toList();

  List<Map<String, dynamic>> get activationRequests =>
      _allMembersList.where((m) => m['isApproved'] == false || m['status'] == 'pending').toList();

  void updateMenuIndex(int index) {
    _selectedMenuIndex = index;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void startListeningToMembers() {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    debugPrint("🔄 PROVIDER: startListeningToMembers() කෝල් වුණා මචං!");

    if (_memberSubscription != null) {
      _memberSubscription?.cancel();
    }

    setLoading(true);

    _memberSubscription = firestore.collection('member').snapshots().listen(
          (querySnapshot) {
        debugPrint("🔥 PROVIDER FIRESTORE: ඩේටාබේස් එකෙන් ලයිව් සිග්නල් එකක් ආවා!");

        _allMembersList = querySnapshot.docs.map((doc) {
          final Map<String, dynamic> data = Map<String, dynamic>.from(doc.data());
          data['doc_id'] = doc.id;

          if (data['payment_history'] != null && data['payment_history'] is List) {
            final List<dynamic> rawHistory = data['payment_history'];
            data['payment_history'] = rawHistory.map((item) => Map<String, dynamic>.from(item as Map)).toList();
          } else {
            data['payment_history'] = <Map<String, dynamic>>[];
          }

          // 🛠️ SAFETY LAYER
          data['membershipNo'] = data['membershipNo']?.toString() ?? '-';
          data['nic'] = data['nic']?.toString() ?? '-';
          data['mobile'] = data['mobile']?.toString() ?? '-';
          data['fullName'] = data['fullName']?.toString() ?? 'Unknown';
          data['firstName'] = data['firstName']?.toString() ?? '';
          data['lastName'] = data['lastName']?.toString() ?? '';
          data['vehicleNumber'] = data['vehicleNumber']?.toString() ?? '-';
          data['vehicleType'] = data['vehicleType'] ?? '-';
          data['address'] = data['address']?.toString() ?? '-';
          data['dob'] = data['dob']?.toString() ?? '-';
          data['gender'] = data['gender']?.toString() ?? '-';
          data['religion'] = data['religion']?.toString() ?? '-';
          data['primaryVehicle'] = data['primaryVehicle']?.toString() ?? '-';
          data['user_email'] = data['user_email']?.toString() ?? '-';
          data['wp_id'] = data['wp_id']?.toString() ?? '-';
          data['status'] = data['status']?.toString() ?? 'pending';
          data['isApproved'] = data['isApproved'] ?? false;
          data['profileImage'] = data['profileImage']?.toString() ?? '';

          data['isOnline'] = data['isOnline'] ?? false;
          data['onlineStatus'] = data['onlineStatus']?.toString() ?? 'offline';

          if (data['lastSeen'] != null && data['lastSeen'] is Timestamp) {
            data['lastSeen'] = (data['lastSeen'] as Timestamp).toDate().toString();
          } else {
            data['lastSeen'] = 'Never';
          }

          if (data['rating'] != null) {
            data['rating'] = int.tryParse(data['rating'].toString()) ?? 5;
          } else {
            data['rating'] = 5;
          }

          if (data['lastSync'] != null && data['lastSync'] is Timestamp) {
            data['lastSync'] = (data['lastSync'] as Timestamp).toDate().toString();
          } else {
            data['lastSync'] = '-';
          }

          // 🏦 බැංකු විස්තර වලට හිස් අගයන් ලබාදීම (Load වෙනකම් Error එන්නේ නැති වෙන්න)
          data['bankName'] = 'Loading...';
          data['accountHolderName'] = 'Loading...';
          data['accountNumber'] = 'Loading...';
          data['branchName'] = 'Loading...';
          data['branchCode'] = 'Loading...';

          return data;
        }).toList();

        _isLoading = false;
        notifyListeners(); // 💡 UI එකට පරක්කු නොකර Data ටික යවනවා

        // 💡 ඊට පස්සේ Background එකේ බැංකු විස්තර Fetch කරලා ලිස්ට් එක අප්ඩේට් කරනවා
        _fetchBankDetailsInBackground();
      },
      onError: (error) {
        debugPrint("❌ PROVIDER ERROR: Firebase Error: $error");
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // =========================================================================
  // 🏦 BACKGROUND FETCH: Bank Details (Stream එක හිරවෙන්නේ නැති වෙන්න)
  // =========================================================================
  Future<void> _fetchBankDetailsInBackground() async {
    bool hasUpdates = false;

    for (var i = 0; i < _allMembersList.length; i++) {
      final String mNo = _allMembersList[i]['membershipNo'];
      if (mNo != '-') {
        try {
          final bankDoc = await FirebaseFirestore.instance.collection('bank_details').doc(mNo).get();
          if (bankDoc.exists && bankDoc.data() != null) {
            final bankData = bankDoc.data()!;
            _allMembersList[i]['bankName'] = bankData['bankName']?.toString() ?? '-';
            _allMembersList[i]['accountHolderName'] = bankData['accountHolderName']?.toString() ?? '-';
            _allMembersList[i]['accountNumber'] = bankData['accountNumber']?.toString() ?? '-';
            _allMembersList[i]['branchName'] = bankData['branchName']?.toString() ?? '-';
            _allMembersList[i]['branchCode'] = bankData['branchCode']?.toString() ?? '-';
            hasUpdates = true;
          } else {
            _setEmptyBankData(i);
          }
        } catch (e) {
          _setEmptyBankData(i);
        }
      } else {
        _setEmptyBankData(i);
      }
    }

    if (hasUpdates) {
      notifyListeners(); // 💡 බැංකු විස්තර ආවට පස්සේ ආයෙත් UI එක අලුත් කරනවා
    }
  }

  void _setEmptyBankData(int index) {
    _allMembersList[index]['bankName'] = '-';
    _allMembersList[index]['accountHolderName'] = '-';
    _allMembersList[index]['accountNumber'] = '-';
    _allMembersList[index]['branchName'] = '-';
    _allMembersList[index]['branchCode'] = '-';
  }

  @override
  void dispose() {
    _memberSubscription?.cancel();
    super.dispose();
  }
}