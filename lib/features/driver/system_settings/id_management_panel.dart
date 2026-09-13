import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IdManagementPanel extends StatefulWidget {
  const IdManagementPanel({super.key});

  @override
  State<IdManagementPanel> createState() => _IdManagementPanelState();
}

class _IdManagementPanelState extends State<IdManagementPanel> {
  final TextEditingController _prefixController = TextEditingController(text: '26');
  final TextEditingController _minRangeController = TextEditingController(text: '150');
  final TextEditingController _maxRangeController = TextEditingController(text: '1000');

  bool _isSearching = false;
  List<int> _missingNumbers = [];
  int _nextNumber = 0;
  int _totalUsed = 0;

  Future<void> _findEmptyNumbers() async {
    setState(() {
      _isSearching = true;
      _missingNumbers.clear();
      _nextNumber = 0;
      _totalUsed = 0;
    });

    try {
      String prefix = _prefixController.text.trim();
      int min = int.tryParse(_minRangeController.text.trim()) ?? 0;
      int max = int.tryParse(_maxRangeController.text.trim()) ?? 0;

      if (min == 0 || max == 0 || min > max) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid range'), backgroundColor: Colors.red));
        setState(() => _isSearching = false);
        return;
      }

      // Fetch all members that might match this prefix
      // Since document IDs or membershipNo start with AIAPRTD-26-
      final qs = await FirebaseFirestore.instance
          .collection('member')
          .where('membershipNo', isGreaterThanOrEqualTo: 'AIAPRTD-$prefix-')
          .where('membershipNo', isLessThan: 'AIAPRTD-$prefix-\uf8ff')
          .get();

      List<int> existingNumbers = [];
      for (var doc in qs.docs) {
        String memNo = doc.id; // e.g. AIAPRTD-26-0150
        List<String> parts = memNo.split('-');
        if (parts.length >= 3) {
          int? num = int.tryParse(parts[2]);
          if (num != null) {
            existingNumbers.add(num);
          }
        }
      }

      _totalUsed = existingNumbers.length;
      int highest = min - 1;
      for (var num in existingNumbers) {
        if (num > highest) {
          highest = num;
        }
      }

      // Find holes between min and max range
      for (int i = min; i <= max; i++) {
        if (!existingNumbers.contains(i)) {
          _missingNumbers.add(i);
        }
      }

      // Next number is the first available one (either a hole, or highest + 1)
      if (_missingNumbers.isNotEmpty) {
        _nextNumber = _missingNumbers.first;
      } else {
        _nextNumber = highest + 1;
      }

      // Save this to system_config so Add Member can use it!
      await FirebaseFirestore.instance.collection('system_config').doc('id_management').set({
        'prefix': prefix,
        'min_range': min,
        'max_range': max,
        'current_value': highest, // The highest assigned so far
        'next_available': _nextNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Membership ID Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Find empty (unused) Membership Numbers in a specific range.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Form
              Expanded(
                flex: 1,
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Search Range', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        TextField(
                          controller: _prefixController,
                          decoration: const InputDecoration(
                            labelText: 'Year Prefix (e.g. 26)',
                            prefixText: 'AIAPRTD-',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _minRangeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Min Range (Start)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _maxRangeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Max Range (End)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white),
                            onPressed: _isSearching ? null : _findEmptyNumbers,
                            icon: _isSearching ? const SizedBox.shrink() : const Icon(Icons.search),
                            label: _isSearching ? const CircularProgressIndicator(color: Colors.white) : const Text('Find Empty Numbers'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              
              // Results Area
              Expanded(
                flex: 2,
                child: Card(
                  elevation: 2,
                  color: const Color(0xFFF8FAFC),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Empty Numbers Result', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            if (_nextNumber > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  'Next ID: AIAPRTD-${_prefixController.text}-${_nextNumber.toString().padLeft(4, '0')}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 16),
                        if (_missingNumbers.isEmpty && !_isSearching && _nextNumber == 0)
                          const Center(child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text('Enter a range and search to see empty numbers.', style: TextStyle(color: Colors.grey)),
                          ))
                        else if (_missingNumbers.isEmpty && !_isSearching)
                          const Center(child: Text('No empty numbers found in this range!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)))
                        else
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                childAspectRatio: 2.5,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _missingNumbers.length,
                              itemBuilder: (context, index) {
                                int num = _missingNumbers[index];
                                return Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.red.shade200),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    num.toString().padLeft(4, '0'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

