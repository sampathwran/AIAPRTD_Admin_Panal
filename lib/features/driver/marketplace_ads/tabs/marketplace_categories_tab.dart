import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class MarketplaceCategoriesTab extends StatefulWidget {
  const MarketplaceCategoriesTab({super.key});

  @override
  State<MarketplaceCategoriesTab> createState() =>
      _MarketplaceCategoriesTabState();
}

class _MarketplaceCategoriesTabState extends State<MarketplaceCategoriesTab> {
  final TextEditingController _catNameCtrl = TextEditingController();
  dynamic _catImageFile; // can be XFile or CroppedFile
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _catImageFile = picked);
    }
  }

  Future<void> _addCategory() async {
    if (_catNameCtrl.text.trim().isEmpty || _catImageFile == null) return;
    setState(() => _isLoading = true);
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('marketplace_categories')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putData(await _catImageFile!.readAsBytes());
      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('marketplace_categories')
          .add({
            'name': _catNameCtrl.text.trim(),
            'imageUrl': imageUrl,
            'subcategories': [],
            'order': 999,
          });
      _catNameCtrl.clear();
      setState(() => _catImageFile = null);
    } catch (e) {
      debugPrint("Error adding category: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _deleteCategory(String id) {
    FirebaseFirestore.instance
        .collection('marketplace_categories')
        .doc(id)
        .delete();
  }

  void _manageSubcategories(
    BuildContext context,
    String catId,
    List<dynamic> existingSubs,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return SubcategoriesManagerDialog(
          catId: catId,
          subcategories: existingSubs,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add Category Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: _catImageFile != null
                          ? (kIsWeb
                                ? Image.network(
                                    _catImageFile!.path,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(_catImageFile!.path),
                                    fit: BoxFit.cover,
                                  ))
                          : const Icon(
                              Icons.add_photo_alternate,
                              size: 40,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _catNameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Main Category Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _addCategory,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text("Add Category"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // List Categories
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('marketplace_categories')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs.toList();
                // Sort locally by 'order', defaulting to 999 if missing
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  int orderA = aData['order'] ?? 999;
                  int orderB = bData['order'] ?? 999;
                  return orderA.compareTo(orderB);
                });

                if (docs.isEmpty) return const Text("No categories found.");

                return ReorderableListView.builder(
                  itemCount: docs.length,
                  onReorderItem: (oldIndex, newIndex) async {
                    final item = docs.removeAt(oldIndex);
                    docs.insert(newIndex, item);

                    // Batch update orders in Firestore
                    final batch = FirebaseFirestore.instance.batch();
                    for (int i = 0; i < docs.length; i++) {
                      batch.update(docs[i].reference, {'order': i});
                    }
                    await batch.commit();
                  },
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final subs = data['subcategories'] as List<dynamic>? ?? [];

                    return Card(
                      key: ValueKey(docs[index].id),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: Image.network(
                          data['imageUrl'] ?? '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image),
                        ),
                        title: Text(data['name'] ?? ''),
                        subtitle: Text("${subs.length} subcategories"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.list, color: Colors.blue),
                              onPressed: () => _manageSubcategories(
                                context,
                                docs[index].id,
                                subs,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCategory(docs[index].id),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.drag_handle, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SubcategoriesManagerDialog extends StatefulWidget {
  final String catId;
  final List<dynamic> subcategories;

  const SubcategoriesManagerDialog({
    super.key,
    required this.catId,
    required this.subcategories,
  });

  @override
  State<SubcategoriesManagerDialog> createState() =>
      _SubcategoriesManagerDialogState();
}

class _SubcategoriesManagerDialogState
    extends State<SubcategoriesManagerDialog> {
  final TextEditingController _subNameCtrl = TextEditingController();
  dynamic _subIconFile;
  bool _isLoading = false;

  Future<void> _pickIcon() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _subIconFile = picked);
    }
  }

  Future<void> _addSubcategory() async {
    if (_subNameCtrl.text.trim().isEmpty || _subIconFile == null) return;
    setState(() => _isLoading = true);
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('marketplace_subcategories')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putData(await _subIconFile!.readAsBytes());
      final iconUrl = await ref.getDownloadURL();

      final newSub = {'name': _subNameCtrl.text.trim(), 'iconUrl': iconUrl};

      await FirebaseFirestore.instance
          .collection('marketplace_categories')
          .doc(widget.catId)
          .update({
            'subcategories': FieldValue.arrayUnion([newSub]),
          });

      _subNameCtrl.clear();
      setState(() {
        _subIconFile = null;
        widget.subcategories.add(newSub);
      });
    } catch (e) {
      debugPrint("Error adding subcategory: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeSub(Map<String, dynamic> sub) async {
    await FirebaseFirestore.instance
        .collection('marketplace_categories')
        .doc(widget.catId)
        .update({
          'subcategories': FieldValue.arrayRemove([sub]),
        });
    setState(() {
      widget.subcategories.remove(sub);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Manage Subcategories"),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _pickIcon,
                  child: Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey.shade200,
                    child: _subIconFile != null
                        ? (kIsWeb
                              ? Image.network(
                                  _subIconFile!.path,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_subIconFile!.path),
                                  fit: BoxFit.cover,
                                ))
                        : const Icon(Icons.add_photo_alternate),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _subNameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Subcategory Name",
                    ),
                  ),
                ),
                IconButton(
                  icon: _isLoading
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.add, color: Colors.blue),
                  onPressed: _isLoading ? null : _addSubcategory,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.subcategories.length,
                itemBuilder: (context, index) {
                  // handle both old string-based and new map-based subcategories for backward compatibility
                  final item = widget.subcategories[index];
                  String name = '';
                  String iconUrl = '';
                  if (item is String) {
                    name = item;
                  } else if (item is Map) {
                    name = item['name'] ?? '';
                    iconUrl = item['iconUrl'] ?? '';
                  }

                  return ListTile(
                    leading: iconUrl.isNotEmpty
                        ? Image.network(
                            iconUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.category),
                    title: Text(name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeSub(item),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }
}
