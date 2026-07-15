import 'package:flutter/material.dart';

class PassengerProvider with ChangeNotifier {
  // ⚙️ Control States
  int _selectedMenuIndex = 0;
  bool _isLoading = false;

  // 🗖 Dummy Data Holders
  List<dynamic> _passengersList = [];
  List<dynamic> _refundRequests = [];

  // --- Getters ---
  int get selectedMenuIndex => _selectedMenuIndex;
  bool get isLoading => _isLoading;
  List<dynamic> get passengersList => _passengersList;
  List<dynamic> get refundRequests => _refundRequests;

  // --- Setters / Actions ---

  void updateMenuIndex(int index) {
    _selectedMenuIndex = index;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // 🔄 Fetch Passengers From API
  Future<void> fetchTotalPassengers() async {
    setLoading(true);
    try {
      // TODO: API Call Integration
      _passengersList = [];
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching passengers: $e");
    } finally {
      setLoading(false);
    }
  }
}
