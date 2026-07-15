import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class ProfileImageProvider with ChangeNotifier {
  StreamSubscription<QuerySnapshot>? _imageSubscription;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 💡 Membership No එකට අදාළව Profile Image URL එක ගබඩා කරන Map එක
  Map<String, String> _profileImages = {};

  Map<String, String> get profileImages => _profileImages;

  // =========================================================================
  // 📸 1. FETCH ALL PROFILE IMAGES FROM REQUESTS COLLECTION
  // =========================================================================
  void startListeningToProfileImages() {
    debugPrint("🔄 IMAGE PROVIDER: startListeningToProfileImages() කෝල් වුණා!");

    if (_imageSubscription != null) {
      _imageSubscription?.cancel();
    }

    _isLoading = true;
    notifyListeners();

    // 💡 'requests' collection එකෙන් පින්තූර විතරක් කියවලා Map එකකට දාගන්නවා
    _imageSubscription = FirebaseFirestore.instance
        .collection('requests')
        .snapshots()
        .listen(
          (querySnapshot) {
            Map<String, String> tempImages = {};

            for (var doc in querySnapshot.docs) {
              // 💡 "Unnecessary cast" warning එක එන්නේ නැති වෙන්න කෙලින්ම doc.data() ගත්තා
              final data = doc.data();

              final membershipNo = data['membershipNo']?.toString() ?? '-';

              // 💡 උඹේ requests collection එකේ ෆොටෝ එක සේව් වෙන්නේ newImageUrl කියන නමින්
              final imageUrl = data['newImageUrl']?.toString() ?? '';

              if (membershipNo != '-' && imageUrl.isNotEmpty) {
                tempImages[membershipNo] = imageUrl;
              }
            }

            _profileImages = tempImages;
            _isLoading = false;
            debugPrint(
              "✅ IMAGE PROVIDER: Requests Collection එකෙන් පින්තූර ${_profileImages.length} ක් අප්ඩේට් වුණා!",
            );
            notifyListeners();
          },
          onError: (error) {
            debugPrint("❌ IMAGE PROVIDER ERROR: $error");
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // =========================================================================
  // 🔍 2. GET IMAGE BY MEMBERSHIP NO (පින්තූරය ඕනෙම තැනකින් ගන්න)
  // =========================================================================
  /// මෙම Function එකට membershipNo එක ලබා දුන් විට අදාළ පින්තූරයේ URL එක ලබා දෙනු ඇත.
  /// පින්තූරයක් නොමැති නම් හිස් String එකක් ('') return කරයි.
  String getImageUrl(String membershipNo) {
    return _profileImages[membershipNo] ?? '';
  }

  @override
  void dispose() {
    _imageSubscription?.cancel();
    super.dispose();
  }
}
