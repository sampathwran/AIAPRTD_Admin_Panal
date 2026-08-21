import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SpecialDaysPanel extends StatefulWidget {
  const SpecialDaysPanel({super.key});

  @override
  State<SpecialDaysPanel> createState() => _SpecialDaysPanelState();
}

class _SpecialDaysPanelState extends State<SpecialDaysPanel> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final doc = await _firestore.collection('system_settings').doc('special_days').get();
      if (doc.exists && doc.data() != null) {
        final List<dynamic> events = doc.data()!['events'] ?? [];
        _events = events.map((e) => Map<String, dynamic>.from(e)).toList();
      } else {
        // Default events if document doesn't exist
        _events = [
          {'date': '02-04', 'title': 'Happy Independence Day!', 'type': 'celebration', 'isActive': true},
          {'date': '04-13', 'title': 'Happy Sinhala & Tamil New Year!', 'type': 'new_year', 'isActive': true},
          {'date': '05-01', 'title': 'Happy May Day!', 'type': 'may_day', 'isActive': true},
          {'date': '05-23', 'title': 'Happy Vesak!', 'type': 'vesak', 'isActive': true}, // Dynamic dates can be updated here
        ];
        await _saveEvents();
      }
    } catch (e) {
      debugPrint('Error loading special days: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveEvents() async {
    try {
      await _firestore.collection('system_settings').doc('special_days').set({
        'events': _events,
      }, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Events saved successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving events: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _addOrEditEvent({Map<String, dynamic>? event, int? index}) {
    final titleCtrl = TextEditingController(text: event?['title'] ?? '');
    final dateCtrl = TextEditingController(text: event?['date'] ?? '');
    String selectedType = event?['type'] ?? 'celebration';
    bool isActive = event?['isActive'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(event == null ? 'Add Special Day' : 'Edit Special Day'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title (e.g., Happy Vesak!)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: dateCtrl,
                    decoration: const InputDecoration(labelText: 'Date (MM-DD, e.g., 05-23)'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Animation Type'),
                    items: const [
                      DropdownMenuItem(value: 'celebration', child: Text('Celebration (Confetti)')),
                      DropdownMenuItem(value: 'vesak', child: Text('Vesak / Poson (Lotus)')),
                      DropdownMenuItem(value: 'new_year', child: Text('New Year (Fireworks)')),
                      DropdownMenuItem(value: 'may_day', child: Text('May Day (Flags)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedType = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Is Active'),
                    value: isActive,
                    onChanged: (val) => setDialogState(() => isActive = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final newEvent = {
                    'title': titleCtrl.text,
                    'date': dateCtrl.text,
                    'type': selectedType,
                    'isActive': isActive,
                  };
                  setState(() {
                    if (index != null) {
                      _events[index] = newEvent;
                    } else {
                      _events.add(newEvent);
                    }
                  });
                  _saveEvents();
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  void _deleteEvent(int index) {
    setState(() {
      _events.removeAt(index);
    });
    _saveEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Special Days Animation Settings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Special Day'),
                onPressed: () => _addOrEditEvent(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Manage dates (MM-DD) to show a full-screen transparent animation on the Member App.'),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_events.isEmpty)
            const Center(child: Text('No special days configured.'))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        event['isActive'] ? Icons.event_available : Icons.event_busy,
                        color: event['isActive'] ? Colors.green : Colors.red,
                        size: 32,
                      ),
                      title: Text(event['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Date: ${event['date']} | Type: ${event['type']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _addOrEditEvent(event: event, index: index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteEvent(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
