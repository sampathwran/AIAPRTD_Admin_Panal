import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdminAddAdDialog extends StatefulWidget {
  const AdminAddAdDialog({super.key});

  @override
  State<AdminAddAdDialog> createState() => _AdminAddAdDialogState();
}

class _AdminAddAdDialogState extends State<AdminAddAdDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();

  String? _selectedCategory;
  String? _selectedSubcategory;
  List<String> _categories = [];
  Map<String, List<String>> _categoryToSubcategories = {};
  List<String> _currentSubcategories = [];
  bool _isLoadingCategories = true;

  List<XFile> _selectedImages = [];
  bool _isSubmitting = false;

  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  final LatLng _defaultLocation = const LatLng(6.9271, 79.8612); // Colombo

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('marketplace_categories')
          .get();
      setState(() {
        _categories = [];
        _categoryToSubcategories = {};
        for (var doc in snap.docs) {
          final data = doc.data();
          final catName = data['name'] as String? ?? 'Unknown';
          _categories.add(catName);

          final subsRaw = data['subcategories'] as List<dynamic>? ?? [];
          final List<String> subs = subsRaw.map((sub) {
            if (sub is String) return sub;
            if (sub is Map) return sub['name'] as String? ?? 'Unknown';
            return 'Unknown';
          }).toList();

          _categoryToSubcategories[catName] = subs;
        }

        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
          _currentSubcategories =
              _categoryToSubcategories[_selectedCategory!] ?? [];
          if (_currentSubcategories.isNotEmpty) {
            _selectedSubcategory = _currentSubcategories.first;
          }
        }
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();
    if (images != null) {
      setState(() {
        _selectedImages.addAll(images);
        if (_selectedImages.length > 5) {
          _selectedImages = _selectedImages.sublist(0, 5);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 5 images allowed.')),
          );
        }
      });
    }
  }

  Future<void> _submitAd() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please mark the address on the map')),
      );
      return;
    }
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 1 image')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      List<String> imageUrls = [];

      // Upload images
      for (int i = 0; i < _selectedImages.length; i++) {
        final file = _selectedImages[i];
        final ext = file.name.split('.').last;
        final fileName =
            'admin_ad_${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
        final ref = FirebaseStorage.instance.ref().child(
          'marketplace_ads/admin_ads/$fileName',
        );

        if (kIsWeb) {
          final bytes = await file.readAsBytes();
          await ref.putData(bytes);
        } else {
          await ref.putFile(File(file.path));
        }

        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      // Save to Firestore
      await FirebaseFirestore.instance.collection('marketplace_ads').add({
        'title': _titleCtrl.text.trim(),
        'price': _priceCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'category': _selectedCategory,
        'subcategory': _selectedSubcategory,
        'imageUrls': imageUrls,
        'lat': _selectedLocation!.latitude,
        'lng': _selectedLocation!.longitude,
        'sellerId': 'ADMIN',
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad posted successfully!')),
        );
      }
    } catch (e) {
      debugPrint("Error posting ad: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Post Admin Ad'),
      content: SizedBox(
        width: 800,
        height: 600,
        child: _isLoadingCategories
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column - Form Fields
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _titleCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Title',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Price (LKR)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                              items: _categories
                                  .map(
                                    (cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedCategory = val;
                                  _currentSubcategories =
                                      _categoryToSubcategories[val] ?? [];
                                  _selectedSubcategory =
                                      _currentSubcategories.isNotEmpty
                                      ? _currentSubcategories.first
                                      : null;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            if (_currentSubcategories.isNotEmpty) ...[
                              DropdownButtonFormField<String>(
                                value: _selectedSubcategory,
                                decoration: const InputDecoration(
                                  labelText: 'Subcategory',
                                  border: OutlineInputBorder(),
                                ),
                                items: _currentSubcategories
                                    .map(
                                      (sub) => DropdownMenuItem(
                                        value: sub,
                                        child: Text(sub),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedSubcategory = val),
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _descCtrl,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Address',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Images (Max 5)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ..._selectedImages.asMap().entries.map((entry) {
                                  int idx = entry.key;
                                  XFile file = entry.value;
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey,
                                          ),
                                        ),
                                        child: kIsWeb
                                            ? Image.network(
                                                file.path,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.file(
                                                File(file.path),
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: InkWell(
                                          onTap: () {
                                            setState(
                                              () =>
                                                  _selectedImages.removeAt(idx),
                                            );
                                          },
                                          child: Container(
                                            color: Colors.red,
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                                if (_selectedImages.length < 5)
                                  InkWell(
                                    onTap: _pickImages,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                      ),
                                      child: const Icon(Icons.add_a_photo),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const VerticalDivider(),
                    // Right Column - Map
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Location on Map',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: _defaultLocation,
                                  zoom: 12,
                                ),
                                myLocationEnabled: true,
                                myLocationButtonEnabled: true,
                                onMapCreated: (controller) =>
                                    _mapController = controller,
                                onTap: (latLng) {
                                  setState(() => _selectedLocation = latLng);
                                },
                                markers: _selectedLocation != null
                                    ? {
                                        Marker(
                                          markerId: const MarkerId('selected'),
                                          position: _selectedLocation!,
                                        ),
                                      }
                                    : {},
                              ),
                            ),
                          ),
                          if (_selectedLocation != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Selected: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitAd,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Post Ad'),
        ),
      ],
    );
  }
}
