import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aiaprtd_admin_dashboard/core/theme/admin_theme.dart';

class AppTutorialsPanel extends StatefulWidget {
  const AppTutorialsPanel({super.key});

  @override
  State<AppTutorialsPanel> createState() => _AppTutorialsPanelState();
}

class _AppTutorialsPanelState extends State<AppTutorialsPanel> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  bool _isSaving = false;

  Future<void> _addTutorial() async {
    final String title = _titleController.text.trim();
    final String link = _linkController.text.trim();

    if (title.isEmpty || link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both title and link.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('app_tutorials').add({
        'title': title,
        'youtubeLink': link,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _titleController.clear();
      _linkController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tutorial added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding tutorial: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _updateTutorial(String docId, String newTitle, String newLink) async {
    try {
      await FirebaseFirestore.instance.collection('app_tutorials').doc(docId).update({
        'title': newTitle,
        'youtubeLink': newLink,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tutorial updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating tutorial: $e')),
        );
      }
    }
  }

  Future<void> _deleteTutorial(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('app_tutorials').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tutorial deleted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting tutorial: $e')),
        );
      }
    }
  }

  void _showEditDialog(String docId, String currentTitle, String currentLink) {
    final TextEditingController editTitleCtrl = TextEditingController(text: currentTitle);
    final TextEditingController editLinkCtrl = TextEditingController(text: currentLink);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Edit Video Guide"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editTitleCtrl,
              decoration: const InputDecoration(labelText: "Video Title", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: editLinkCtrl,
              decoration: const InputDecoration(labelText: "YouTube Link", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              if (editTitleCtrl.text.trim().isNotEmpty && editLinkCtrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                _updateTutorial(docId, editTitleCtrl.text.trim(), editLinkCtrl.text.trim());
              }
            },
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Add Form
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AdminColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Add New Video Guide",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminColors.ink),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Video Title",
                      hintText: "e.g. How to Accept bookings",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _linkController,
                    decoration: const InputDecoration(
                      labelText: "YouTube Link",
                      hintText: "https://www.youtube.com/watch?v=...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSaving ? null : _addTutorial,
                      icon: _isSaving 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Icon(Icons.add),
                      label: Text(_isSaving ? "Saving..." : "Add Video"),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Right Side: List of Videos
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AdminColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Published App Guides",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AdminColors.ink),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      // Removing orderBy just in case it caused index issues, we will sort locally
                      stream: FirebaseFirestore.instance
                          .collection('app_tutorials')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text("Error loading tutorials: ${snapshot.error}"));
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text(
                              "No tutorials added yet.",
                              style: TextStyle(color: AdminColors.inkSoft),
                            ),
                          );
                        }

                        // Local sort to avoid requiring a composite index or missing documents due to missing timestamps
                        final docs = snapshot.data!.docs.toList();
                        docs.sort((a, b) {
                          final aData = a.data() as Map<String, dynamic>;
                          final bData = b.data() as Map<String, dynamic>;
                          final aTime = aData['timestamp'] as Timestamp?;
                          final bTime = bData['timestamp'] as Timestamp?;
                          if (aTime == null && bTime == null) return 0;
                          if (aTime == null) return 1;
                          if (bTime == null) return -1;
                          return bTime.compareTo(aTime); // Descending
                        });

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final title = data['title'] ?? 'Untitled';
                            final link = data['youtubeLink'] ?? '';

                            return Card(
                              elevation: 0,
                              color: AdminColors.surface,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: AdminColors.line),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.ondemand_video, color: Colors.red),
                                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(link, style: const TextStyle(color: Colors.blue)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                      onPressed: () => _showEditDialog(doc.id, title, link),
                                      tooltip: "Edit",
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      tooltip: "Delete",
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text("Delete Video?"),
                                            content: const Text("Are you sure you want to delete this video guide?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx),
                                                child: const Text("Cancel"),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  _deleteTutorial(doc.id);
                                                },
                                                child: const Text("Delete"),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
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
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    super.dispose();
  }
}
