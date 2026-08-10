import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'sub_services/police_traffic/police_traffic_management_page.dart';

class ServicesHubPanel extends StatefulWidget {
  const ServicesHubPanel({super.key});

  @override
  State<ServicesHubPanel> createState() => _ServicesHubPanelState();
}

class _ServicesHubPanelState extends State<ServicesHubPanel> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();

  String _selectedSubMenuRoute = 'marketplace'; // Replaces actionType & actionTarget
  String _selectedColorHex = '#2196F3'; // Default to Blue
  bool _isActive = true;
  bool _isLoading = false;

  String? _editingId;
  String? _existingImageUrl;

  final Map<String, String> _predefinedColors = {
    'Blue': '#2196F3',
    'Orange': '#FF9800',
    'Purple': '#9C27B0',
    'Green': '#4CAF50',
    'Red': '#F44336',
    'Teal': '#009688',
    'Pink': '#E91E63',
    'Indigo': '#3F51B5',
    'Deep Orange': '#FF5722',
    'Blue Grey': '#607D8B',
  };

  final Map<String, String> _availableSubMenus = {
    'Marketplace': 'marketplace',
    'Mobile Reload': 'mobile_reload',
    'Flight Tracking': 'flight_tracking',
    'Welfare Shops': 'welfare_shops',
    'Service Stations': 'service_stations',
    'Vehicle Parts': 'vehicle_parts',
    'Driver Loans': 'driver_loans',
    'Police & Traffic': 'report_traffic',
    'Emergency SOS': 'emergency_sos',
    'EV Charging': 'ev_charging',
    'App Tutorials': 'app_tutorials',
  };

  dynamic _iconImageFile; // XFile or CroppedFile

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _iconImageFile = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Service Hub Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Form to add new service
            Expanded(
              flex: 1,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _editingId == null ? 'Add New Service' : 'Edit Service',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              if (_editingId != null)
                                TextButton(
                                  onPressed: _resetForm,
                                  child: const Text('Cancel Edit'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Image Picker
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: _iconImageFile != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: kIsWeb
                                            ? Image.network(_iconImageFile!.path, fit: BoxFit.cover)
                                            : Image.file(File(_iconImageFile!.path), fit: BoxFit.cover),
                                      )
                                    : (_existingImageUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(_existingImageUrl!, fit: BoxFit.cover),
                                          )
                                        : const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                                              SizedBox(height: 4),
                                              Text('Icon', style: TextStyle(color: Colors.grey)),
                                            ],
                                          )),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _labelController,
                            decoration: const InputDecoration(labelText: 'Label (e.g. Marketplace)'),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedColorHex,
                            decoration: const InputDecoration(labelText: 'Background Color'),
                            items: _predefinedColors.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.value,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Color(int.parse(entry.value.replaceAll('#', 'FF'), radix: 16)),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(entry.key),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedColorHex = v);
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedSubMenuRoute,
                            decoration: const InputDecoration(labelText: 'Link to Service Module'),
                            items: _availableSubMenus.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.value,
                                child: Text(entry.key),
                              );
                            }).toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedSubMenuRoute = v!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Is Active?'),
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveService,
                              child: _isLoading 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(_editingId == null ? 'Add Service' : 'Update Service'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Right Side: List of current services
            Expanded(
              flex: 2,
              child: Card(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('driver_services_hub').orderBy('order').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) return const Center(child: Text('No services added yet.'));

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final imageUrl = data['imageUrl'] as String?;
                        final colorHex = data['colorHex'] as String? ?? '#2196F3';
                        // Convert hex to color
                        Color bgColor = Colors.blue;
                        try {
                          String cleanHex = colorHex.toUpperCase().replaceAll("#", "");
                          if (cleanHex.length == 6) cleanHex = "FF$cleanHex";
                          bgColor = Color(int.parse(cleanHex, radix: 16));
                        } catch (_) {}

                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: bgColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: bgColor.withValues(alpha: 0.3)),
                            ),
                            child: Center(
                              child: imageUrl != null && imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(imageUrl, width: 24, height: 24, fit: BoxFit.cover),
                                    )
                                  : Icon(Icons.apps, color: bgColor, size: 24),
                            ),
                          ),
                          title: Text(data['label'] ?? ''),
                          subtitle: Text('Type: ${data['actionType']} | Target: ${data['actionTarget']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  data['isActive'] == true ? Icons.visibility : Icons.visibility_off,
                                  color: data['isActive'] == true ? Colors.green : Colors.grey,
                                ),
                                onPressed: () => _confirmAction(
                                  'Change Status',
                                  'Are you sure you want to  this service?',
                                  () {
                                    FirebaseFirestore.instance.collection('driver_services_hub').doc(docs[index].id).update({
                                      'isActive': !(data['isActive'] == true),
                                    });
                                  }
                                ),
                                tooltip: data['isActive'] == true ? 'Hold Service' : 'Publish Service',
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _confirmAction(
                                  'Edit Service',
                                  'Are you sure you want to edit this service?',
                                  () => _startEditing(docs[index].id, data)
                                ),
                                tooltip: 'Edit Service',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmAction(
                                  'Delete Service',
                                  'Are you sure you want to permanently delete this service?',
                                  () {
                                    FirebaseFirestore.instance.collection('driver_services_hub').doc(docs[index].id).delete();
                                  }
                                ),
                                tooltip: 'Delete Service',
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveService() async {
    if (_formKey.currentState!.validate()) {
      if (_iconImageFile == null && _existingImageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an icon image.')));
        return;
      }

      setState(() => _isLoading = true);
      try {
        String? imageUrl = _existingImageUrl;
        
        // Upload new image if selected
        if (_iconImageFile != null) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('driver_services_hub_icons')
              .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
          
          await ref.putData(await _iconImageFile!.readAsBytes());
          imageUrl = await ref.getDownloadURL();
        }

        final isUpdate = _editingId != null;

        // Save or Update Firestore
        if (isUpdate) {
          await FirebaseFirestore.instance.collection('driver_services_hub').doc(_editingId).update({
            'label': _labelController.text,
            'imageUrl': imageUrl,
            'colorHex': _selectedColorHex,
            'actionTarget': _selectedSubMenuRoute,
            'isActive': _isActive,
          });
        } else {
          final docRef = FirebaseFirestore.instance.collection('driver_services_hub').doc();
          await docRef.set({
            'id': docRef.id,
            'label': _labelController.text,
            'imageUrl': imageUrl,
            'colorHex': _selectedColorHex,
            'actionType': 'internal_route', // Hardcoded as requested
            'actionTarget': _selectedSubMenuRoute,
            'isActive': _isActive,
            'order': DateTime.now().millisecondsSinceEpoch,
          });
        }

        _resetForm();

        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isUpdate ? 'Service updated!' : 'Service added!')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _resetForm() {
    setState(() {
      _editingId = null;
      _existingImageUrl = null;
      _iconImageFile = null;
      _labelController.clear();
      _selectedColorHex = '#2196F3';
      _selectedSubMenuRoute = 'marketplace';
      _isActive = true;
    });
  }

  void _startEditing(String id, Map<String, dynamic> data) {
    setState(() {
      _editingId = id;
      _labelController.text = data['label'] ?? '';
      _selectedColorHex = data['colorHex'] ?? '#2196F3';
      _selectedSubMenuRoute = data['actionTarget'] ?? 'marketplace';
      _isActive = data['isActive'] ?? true;
      _existingImageUrl = data['imageUrl'];
      _iconImageFile = null;
    });
  }

  void _confirmAction(String title, String content, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}


