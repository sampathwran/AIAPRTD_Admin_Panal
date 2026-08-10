import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class EvChargerModel {
  String id;
  String? name;
  String type;
  double powerKw;
  String status;
  double pricePerKwh;

  EvChargerModel({
    required this.id,
    this.name,
    required this.type,
    required this.powerKw,
    required this.status,
    this.pricePerKwh = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'powerKw': powerKw,
    'status': status,
    'pricePerKwh': pricePerKwh,
  };
}

class AddEditEvStationDialog extends StatefulWidget {
  final DocumentSnapshot? station;

  const AddEditEvStationDialog({super.key, this.station});

  @override
  State<AddEditEvStationDialog> createState() => _AddEditEvStationDialogState();
}

class _AddEditEvStationDialogState extends State<AddEditEvStationDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _providerController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _priceController;

  Uint8List? _selectedImageBytes;
  String? _uploadedImageUrl;

  String _selectedProviderDropdown = 'ChargeNet';
  final List<String> _commonProviders = ['ChargeNet', 'CEB', 'Spark', 'VegaPoint', 'EV Club'];
  final List<String> _standardConnectors = ['Type 2', 'CCS2', 'CHAdeMO', 'GB/T', 'Yazaki (Type 1)', 'Schuko'];

  List<EvChargerModel> _chargers = [];
  bool _isLoading = false;
  bool _isSearchingAddress = false;
  Timer? _debounce;
  
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    final data = widget.station?.data() as Map<String, dynamic>?;

    _nameController = TextEditingController(text: data?['name'] ?? '');
    
    String p = data?['provider'] ?? '';
    if (_commonProviders.contains(p)) {
      _selectedProviderDropdown = p;
    } else if (p.isNotEmpty) {
      _selectedProviderDropdown = 'Other (Custom)';
    } else {
      _selectedProviderDropdown = 'ChargeNet';
      p = 'ChargeNet';
    }
    _providerController = TextEditingController(text: p);
    
    _addressController = TextEditingController(text: data?['address'] ?? '');
    _descriptionController = TextEditingController(text: data?['description'] ?? '');
    _latController = TextEditingController(text: data?['latitude']?.toString() ?? '');
    _lngController = TextEditingController(text: data?['longitude']?.toString() ?? '');
    _priceController = TextEditingController(text: data?['pricePerKwh']?.toString() ?? '0.0');
    _uploadedImageUrl = data?['imageUrl'];

    if (data != null && data['latitude'] != null && data['longitude'] != null) {
      double lat = (data['latitude']).toDouble();
      double lng = (data['longitude']).toDouble();
      _selectedLocation = LatLng(lat, lng);
      _markers.add(Marker(markerId: const MarkerId('selected'), position: _selectedLocation!));
    }

    if (data != null && data['chargers'] != null) {
      _chargers = (data['chargers'] as List).map((c) => EvChargerModel(
        id: c['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: c['name'],
        type: c['type'] ?? 'Type 2',
        powerKw: (c['powerKw'] ?? 0).toDouble(),
        status: c['status'] ?? 'Available',
        pricePerKwh: (c['pricePerKwh'] ?? 0.0).toDouble(),
      )).toList();
    } else if (data != null) {
      final types = List<String>.from(data['chargerTypes'] ?? ['Type 2']);
      final power = (data['powerKw'] ?? 0).toDouble();
      final status = data['status'] ?? 'Available';
      final legacyPrice = (data['pricePerKwh'] ?? 0.0).toDouble();
      
      for (int i = 0; i < types.length; i++) {
        _chargers.add(EvChargerModel(
          id: '${widget.station!.id}_$i',
          name: 'Port ${i + 1}',
          type: types[i],
          powerKw: power,
          status: status,
          pricePerKwh: legacyPrice,
        ));
      }
    }
  }
  
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _onMapTapped(LatLng position) async {
    setState(() {
      _selectedLocation = position;
      _latController.text = position.latitude.toStringAsFixed(6);
      _lngController.text = position.longitude.toStringAsFixed(6);
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        )
      };
    });

    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json&accept-language=en');
      final response = await http.get(url, headers: {'User-Agent': 'AIAPRTD-Admin/1.0'});
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['display_name'] != null) {
          setState(() {
            _addressController.text = data['display_name'];
          });
        }
      }
    } catch (e) {
      debugPrint("Reverse geocode failed: $e");
    }
  }

  void _updateMapTo(double lat, double lng) async {
    final newPos = LatLng(lat, lng);
    setState(() {
      _selectedLocation = newPos;
      _latController.text = lat.toStringAsFixed(6);
      _lngController.text = lng.toStringAsFixed(6);
      _markers = {
        Marker(
          markerId: const MarkerId('selected'),
          position: newPos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        )
      };
    });
    
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: newPos, zoom: 15),
    ));
  }

  Future<void> _searchAddressOnMap(String query) async {
    if (query.length < 5) return;
    
    // 1. Check if it's a raw Lat,Lng coordinate string
    final coordRegex = RegExp(r'^(-?\d+\.\d+),\s*(-?\d+\.\d+)$');
    final coordMatch = coordRegex.firstMatch(query.trim());
    if (coordMatch != null) {
      final double lat = double.parse(coordMatch.group(1)!);
      final double lng = double.parse(coordMatch.group(2)!);
      _updateMapTo(lat, lng);
      return;
    }

    // 2. Check if it's a Google Maps URL containing coordinates or a short URL
    final linkRegex = RegExp(r'https?://[^\s]+');
    final linkMatch = linkRegex.firstMatch(query);
    if (linkMatch != null) {
      String url = linkMatch.group(0)!;
      
      // If it's a shortened URL, resolve it first
      if (url.contains('goo.gl') || url.contains('maps.app.goo.gl')) {
        setState(() => _isSearchingAddress = true);
        try {
          final response = await http.get(Uri.parse(url));
          url = response.request?.url.toString() ?? url;
        } catch (e) {
          debugPrint('Failed to expand short URL: $e');
        }
      }

      // Look for coordinates in the resolved URL
      final urlRegex = RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)');
      final urlMatch = urlRegex.firstMatch(url);
      if (urlMatch != null) {
        final double lat = double.parse(urlMatch.group(1)!);
        final double lng = double.parse(urlMatch.group(2)!);
        _updateMapTo(lat, lng);
        if (mounted) setState(() => _isSearchingAddress = false);
        return;
      }
      
      // If it was a URL but we didn't find coordinates, continue to Nominatim search
      // just in case (though unlikely to work, it's safe).
    }

    // 3. Fallback to Nominatim OpenStreetMap Search
    setState(() => _isSearchingAddress = true);
    
    Future<bool> trySearch(String q) async {
      try {
        final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(q)}&format=json&limit=1&countrycodes=lk');
        final response = await http.get(url, headers: {'User-Agent': 'AIAPRTD-Admin/1.0'});
        
        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          if (data.isNotEmpty) {
            final double lat = double.parse(data[0]['lat']);
            final double lng = double.parse(data[0]['lon']);
            _updateMapTo(lat, lng);
            return true;
          }
        }
      } catch (e) {
        debugPrint("Forward geocode failed: $e");
      }
      return false;
    }

    try {
      // First try the full query
      bool found = await trySearch(query);
      
      // If not found, try stripping parts separated by comma (e.g. "No 162/5, Veyangoda" -> "Veyangoda")
      if (!found && query.contains(',')) {
        List<String> parts = query.split(',');
        while (!found && parts.length > 1) {
          parts.removeAt(0);
          found = await trySearch(parts.join(',').trim());
        }
      }

      if (!found) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not automatically find this address on the map. Please tap the exact location on the map manually.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSearchingAddress = false);
    }
  }

  void _onAddressChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), () {
      _searchAddressOnMap(value);
    });
  }

  void _addCharger() {
    setState(() {
      _chargers.add(EvChargerModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Port ${_chargers.length + 1}',
        type: 'Type 2',
        powerKw: 22.0,
        status: 'Available',
      ));
    });
  }

  void _removeCharger(int index) {
    setState(() {
      _chargers.removeAt(index);
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_chargers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one charging point!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Upload image if a new one was selected
    if (_selectedImageBytes != null) {
      try {
        final ref = FirebaseStorage.instance.ref().child('ev_stations/img_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putData(_selectedImageBytes!, SettableMetadata(contentType: 'image/jpeg'));
        _uploadedImageUrl = await ref.getDownloadURL();
      } catch (e) {
        debugPrint('Image upload failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
        }
      }
    }

    try {
      final data = {
        'name': _nameController.text.trim(),
        'provider': _providerController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'latitude': double.parse(_latController.text),
        'longitude': double.parse(_lngController.text),
        // We still save legacy price just in case old apps read it, but default to the first charger's price
        'pricePerKwh': _chargers.isNotEmpty ? _chargers.first.pricePerKwh : 0.0,
        'imageUrl': _uploadedImageUrl,
        'chargers': _chargers.map((c) => c.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.station == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['status'] = _chargers.first.status;
        data['powerKw'] = _chargers.first.powerKw;
        data['chargerTypes'] = _chargers.map((c) => c.type).toSet().toList();
        
        await FirebaseFirestore.instance.collection('ev_charging_stations').add(data);
      } else {
        await FirebaseFirestore.instance.collection('ev_charging_stations').doc(widget.station!.id).update(data);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 1000,
        height: 800,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.station == null ? 'Add New EV Station' : 'Edit EV Station',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Station Details
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Station Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(labelText: 'Station Name (e.g. ChargeNet BMICH)', border: OutlineInputBorder()),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedProviderDropdown,
                                decoration: const InputDecoration(labelText: 'Provider', border: OutlineInputBorder()),
                                items: [..._commonProviders, 'Other (Custom)'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                onChanged: (v) {
                                  setState(() {
                                    _selectedProviderDropdown = v!;
                                    if (v != 'Other (Custom)') {
                                      _providerController.text = v;
                                    } else {
                                      _providerController.text = '';
                                    }
                                  });
                                },
                              ),
                              if (_selectedProviderDropdown == 'Other (Custom)') ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _providerController,
                                  decoration: const InputDecoration(labelText: 'Custom Provider Name', border: OutlineInputBorder()),
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                              ],
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[400]!),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _selectedImageBytes != null
                                        ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                                        : (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty)
                                            ? Image.network(_uploadedImageUrl!, fit: BoxFit.cover)
                                            : const Icon(Icons.image, color: Colors.grey, size: 40),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.upload_file),
                                    label: const Text('Upload Image'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Description / Notes', 
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Middle Column: Location
                    Expanded(
                      flex: 1,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: 'Address (Paste address, coordinates, or Google Maps URL)', 
                                border: const OutlineInputBorder(),
                                suffixIcon: _isSearchingAddress 
                                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                                    : IconButton(
                                        icon: const Icon(Icons.search), 
                                        onPressed: () => _searchAddressOnMap(_addressController.text),
                                      ),
                              ),
                              onChanged: _onAddressChanged,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              height: 250,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: _selectedLocation ?? const LatLng(6.9271, 79.8612), // Default Colombo
                                    zoom: _selectedLocation == null ? 8 : 15,
                                  ),
                                  onMapCreated: (controller) => _mapController.complete(controller),
                                  onTap: _onMapTapped,
                                  markers: _markers,
                                  myLocationButtonEnabled: false,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _latController,
                                    decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                    readOnly: true,
                                    validator: (v) => v!.isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lngController,
                                    decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                                    keyboardType: TextInputType.number,
                                    readOnly: true,
                                    validator: (v) => v!.isEmpty ? 'Required' : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Right Column: Chargers
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Charging Points', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              ElevatedButton.icon(
                                onPressed: _addCharger,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Point'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _chargers.isEmpty
                                ? Center(child: Text('No charging points added.', style: TextStyle(color: Colors.grey[500])))
                                : ListView.builder(
                                    itemCount: _chargers.length,
                                    itemBuilder: (context, index) {
                                      final charger = _chargers[index];
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        elevation: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text('Service Point ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    onPressed: () => _removeCharger(index),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                initialValue: charger.name ?? '',
                                                decoration: const InputDecoration(labelText: 'Custom Name (Optional, e.g. Port A, CHAdeMO Fast)', border: OutlineInputBorder()),
                                                onChanged: (v) => charger.name = v.trim(),
                                              ),
                                              const SizedBox(height: 16),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Builder(
                                                      builder: (context) {
                                                        String dropdownValue = _standardConnectors.contains(charger.type) ? charger.type : 'Other (Custom)';
                                                        if (charger.type.isEmpty) dropdownValue = 'Other (Custom)';
                                                        
                                                        return Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            DropdownButtonFormField<String>(
                                                              value: dropdownValue,
                                                              decoration: const InputDecoration(labelText: 'Connector Type', border: OutlineInputBorder()),
                                                              items: [..._standardConnectors, 'Other (Custom)'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                                              onChanged: (v) {
                                                                setState(() {
                                                                  if (v != 'Other (Custom)') {
                                                                    charger.type = v!;
                                                                  } else {
                                                                    charger.type = '';
                                                                  }
                                                                });
                                                              },
                                                            ),
                                                            if (dropdownValue == 'Other (Custom)') ...[
                                                              const SizedBox(height: 8),
                                                              TextFormField(
                                                                initialValue: charger.type,
                                                                decoration: const InputDecoration(labelText: 'Custom Connector Type', border: OutlineInputBorder()),
                                                                onChanged: (v) => charger.type = v.trim(),
                                                              ),
                                                            ],
                                                          ],
                                                        );
                                                      }
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: charger.powerKw.toString(),
                                                      decoration: const InputDecoration(labelText: 'Power (kW)', border: OutlineInputBorder()),
                                                      keyboardType: TextInputType.number,
                                                      onChanged: (v) => charger.powerKw = double.tryParse(v) ?? 0.0,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: DropdownButtonFormField<String>(
                                                      decoration: const InputDecoration(labelText: 'Initial Status', border: OutlineInputBorder()),
                                                      value: charger.status,
                                                      items: ['Available', 'In Use', 'Broken', 'Offline'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                                      onChanged: (v) => setState(() => charger.status = v!),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: charger.pricePerKwh.toString(),
                                                      decoration: const InputDecoration(labelText: 'Price per kWh (Rs.)', border: OutlineInputBorder()),
                                                      keyboardType: TextInputType.number,
                                                      onChanged: (v) => charger.pricePerKwh = double.tryParse(v) ?? 0.0,
                                                    ),
                                                  ),
                                                ],
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save Station'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

