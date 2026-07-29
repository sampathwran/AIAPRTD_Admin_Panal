import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdminEditAdDialog extends StatefulWidget {
  final String adId;
  final Map<String, dynamic> adData;

  const AdminEditAdDialog({
    super.key,
    required this.adId,
    required this.adData,
  });

  @override
  State<AdminEditAdDialog> createState() => _AdminEditAdDialogState();
}

class _AdminEditAdDialogState extends State<AdminEditAdDialog> {
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

  // Holds String (network URL) or XFile (newly picked image)
  List<dynamic> _selectedImages = [];
  bool _allowBidding = false;
  bool _isSubmitting = false;

  LatLng? _selectedLocation;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _titleCtrl.text = widget.adData['title'] ?? '';
    _priceCtrl.text = widget.adData['price']?.toString() ?? '';
    _descCtrl.text = widget.adData['description'] ?? '';
    _addressCtrl.text = widget.adData['address'] ?? '';
    _allowBidding = widget.adData['allowBidding'] == true;
    _selectedCategory = widget.adData['category'];
    _selectedSubcategory = widget.adData['subcategory'];

    if (widget.adData['lat'] != null && widget.adData['lng'] != null) {
      _selectedLocation = LatLng(
        (widget.adData['lat'] as num).toDouble(),
        (widget.adData['lng'] as num).toDouble(),
      );
    }

    if (widget.adData['imageUrls'] != null) {
      _selectedImages = List<dynamic>.from(widget.adData['imageUrls']);
    }

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

        if (_selectedCategory != null) {
          _currentSubcategories =
              _categoryToSubcategories[_selectedCategory!] ?? [];
        } else if (_categories.isNotEmpty) {
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

      for (int i = 0; i < _selectedImages.length; i++) {
        final item = _selectedImages[i];
        if (item is String) {
          // Already an uploaded URL
          imageUrls.add(item);
        } else if (item is XFile) {
          // New file to upload
          final ext = item.name.split('.').last;
          final fileName =
              'admin_ad_${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
          final ref = FirebaseStorage.instance.ref().child(
            'marketplace_ads/admin_ads/$fileName',
          );

          if (kIsWeb) {
            final bytes = await item.readAsBytes();
            await ref.putData(bytes);
          } else {
            await ref.putFile(File(item.path));
          }

          final url = await ref.getDownloadURL();
          imageUrls.add(url);
        }
      }

      await FirebaseFirestore.instance
          .collection('marketplace_ads')
          .doc(widget.adId)
          .update({
            'title': _titleCtrl.text.trim(),
            'price': _priceCtrl.text.trim(),
            'description': _descCtrl.text.trim(),
            'address': _addressCtrl.text.trim(),
            'category': _selectedCategory,
            'subcategory': _selectedSubcategory,
            'allowBidding': _allowBidding,
            'imageUrls': imageUrls,
            'lat': _selectedLocation!.latitude,
            'lng': _selectedLocation!.longitude,
          });

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad updated successfully!')),
        );
      }
    } catch (e) {
      debugPrint("Error updating ad: $e");
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
      title: const Text('Edit Admin Ad'),
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
                    // Left Column
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
                              value: _categories.contains(_selectedCategory)
                                  ? _selectedCategory
                                  : null,
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
                                value:
                                    _currentSubcategories.contains(
                                      _selectedSubcategory,
                                    )
                                    ? _selectedSubcategory
                                    : null,
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
                            SwitchListTile(
                              title: const Text('Allow Bidding'),
                              subtitle: const Text(
                                'Enable members to place bids on this ad',
                              ),
                              value: _allowBidding,
                              onChanged: (val) =>
                                  setState(() => _allowBidding = val),
                              contentPadding: EdgeInsets.zero,
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
                                  var item = entry.value;
                                  bool isUrl = item is String;

                                  return Stack(
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey,
                                          ),
                                        ),
                                        child: isUrl
                                            ? Image.network(
                                                item,
                                                fit: BoxFit.cover,
                                              )
                                            : kIsWeb
                                            ? Image.network(
                                                (item as XFile).path,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.file(
                                                File((item as XFile).path),
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: InkWell(
                                          onTap: () => setState(
                                            () => _selectedImages.removeAt(idx),
                                          ),
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
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          color: Colors.black54,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.arrow_left,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: idx > 0
                                                    ? () {
                                                        setState(() {
                                                          final movedItem =
                                                              _selectedImages
                                                                  .removeAt(
                                                                    idx,
                                                                  );
                                                          _selectedImages
                                                              .insert(
                                                                idx - 1,
                                                                movedItem,
                                                              );
                                                        });
                                                      }
                                                    : null,
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.arrow_right,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed:
                                                    idx <
                                                        _selectedImages.length -
                                                            1
                                                    ? () {
                                                        setState(() {
                                                          final movedItem =
                                                              _selectedImages
                                                                  .removeAt(
                                                                    idx,
                                                                  );
                                                          _selectedImages
                                                              .insert(
                                                                idx + 1,
                                                                movedItem,
                                                              );
                                                        });
                                                      }
                                                    : null,
                                              ),
                                            ],
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
                                      width: 100,
                                      height: 100,
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
                    // Right Column
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
                                  target:
                                      _selectedLocation ??
                                      const LatLng(6.9271, 79.8612),
                                  zoom: 12,
                                ),
                                myLocationEnabled: true,
                                myLocationButtonEnabled: true,
                                onMapCreated: (controller) {
                                  _mapController = controller;
                                  if (_selectedLocation != null) {
                                    _mapController?.animateCamera(
                                      CameraUpdate.newLatLng(
                                        _selectedLocation!,
                                      ),
                                    );
                                  }
                                },
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
              : const Text('Save Changes'),
        ),
      ],
    );
  }
}
