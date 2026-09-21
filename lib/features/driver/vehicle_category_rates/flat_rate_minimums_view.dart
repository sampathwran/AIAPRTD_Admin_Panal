import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FlatRateMinimumsView extends StatefulWidget {
  const FlatRateMinimumsView({super.key});

  @override
  State<FlatRateMinimumsView> createState() => _FlatRateMinimumsViewState();
}

class _FlatRateMinimumsViewState extends State<FlatRateMinimumsView> {
  final List<String> categories = ['budget', 'mini', 'sedan', 'van_6', 'van_9', 'van_14'];
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (var cat in categories) {
      _controllers[cat] = TextEditingController();
    }
    _fetchRates();
  }

  Future<void> _fetchRates() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('rates').doc('flat_rate_minimums').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        for (var cat in categories) {
          if (data.containsKey(cat)) {
            _controllers[cat]?.text = data[cat].toString();
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching flat rates: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRates() async {
    setState(() => _isSaving = true);
    try {
      final Map<String, dynamic> dataToSave = {};
      for (var cat in categories) {
        final val = double.tryParse(_controllers[cat]?.text.trim() ?? '0') ?? 0.0;
        dataToSave[cat] = val;
      }
      
      await FirebaseFirestore.instance.collection('rates').doc('flat_rate_minimums').set(dataToSave, SetOptions(merge: true));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Flat Rate Minimums saved successfully!')),
        );
      }
    } catch (e) {
      debugPrint("Error saving flat rates: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving rates: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 5,
              )
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Flat Rate Minimums (Per KM)",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Set the minimum allowed rate per KM for flat rate bookings. If a member tries to book below this limit, it will be rejected.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              
              ...categories.map((cat) => _buildRateField(cat)),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveRates,
                  icon: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? "Saving..." : "Save Minimum Rates", style: const TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRateField(String category) {
    String displayName = category.toUpperCase().replaceAll('_', ' ');
    if (category == 'van_6') displayName = "6 SEATER VAN";
    if (category == 'van_9') displayName = "9 SEATER VAN";
    if (category == 'van_14') displayName = "14 SEATER VAN";

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _controllers[category],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: "Rs. ",
                labelText: "Min Rate per KM",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
