import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../utils/app_icons_library.dart';

class MemberBenefitsPanel extends StatefulWidget {
  const MemberBenefitsPanel({super.key});

  @override
  State<MemberBenefitsPanel> createState() => _MemberBenefitsPanelState();
}

class _MemberBenefitsPanelState extends State<MemberBenefitsPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('🎁 Member Benefits Management', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade900,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue.shade900,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Manage Global Benefits'),
            Tab(icon: Icon(Icons.people_alt), text: 'Assign to Members'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ManageGlobalBenefitsTab(),
          AssignBenefitsTab(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 1: Manage Global Benefits (CRUD)
// ═══════════════════════════════════════════════════════════════════════════════
class ManageGlobalBenefitsTab extends StatelessWidget {
  const ManageGlobalBenefitsTab({super.key});

  IconData _getIconData(String iconName) {
    return AppIconsLibrary.getIcon(iconName);
  }

  void _showAddEditDialog(BuildContext context, [DocumentSnapshot? doc]) {
    final bool isEdit = doc != null;
    final Map<String, dynamic> data = isEdit ? doc.data() as Map<String, dynamic> : {};

    final TextEditingController titleCtrl = TextEditingController(text: data['title'] ?? '');
    final TextEditingController descCtrl = TextEditingController(text: data['description'] ?? '');
    String selectedIcon = data['icon'] ?? 'star';
    String? uploadedImageUrl = data['iconUrl'];
    XFile? pickedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Benefit' : 'Add New Benefit'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Benefit Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null) {
                              setState(() {
                                pickedImage = image;
                              });
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('Pick Custom PNG Icon'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: pickedImage != null
                              ? const Text('Image selected!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                              : uploadedImageUrl != null
                                  ? const Text('Existing image loaded', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))
                                  : const Text('No image selected', style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('OR Use Material Icon', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (val) {
                        setState(() { selectedIcon = val; });
                      },
                      decoration: InputDecoration(
                        labelText: 'Icon Hex Code / Name (e.g. e5f9 or gavel)', 
                        border: const OutlineInputBorder(),
                        hintText: 'gavel',
                        suffixIcon: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(AppIconsLibrary.getIcon(selectedIcon)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Applicable to All Members?'),
                      subtitle: const Text('Check this if every driver should get this benefit automatically.'),
                      value: data['isGlobal'] ?? false,
                      onChanged: (val) {
                        setState(() {
                          data['isGlobal'] = val;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title and Description are required', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                      return;
                    }
                    
                    if (pickedImage != null) {
                      setState(() { isUploading = true; });
                      try {
                        final bytes = await pickedImage!.readAsBytes();
                        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedImage!.name}';
                        final Reference ref = FirebaseStorage.instance.ref().child('benefits_icons/$fileName');
                        final UploadTask uploadTask = ref.putData(bytes);
                        final TaskSnapshot snapshot = await uploadTask;
                        uploadedImageUrl = await snapshot.ref.getDownloadURL();
                      } catch (e) {
                        setState(() { isUploading = false; });
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
                        return;
                      }
                    }

                    final payload = {
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'icon': selectedIcon,
                      if (uploadedImageUrl != null) 'iconUrl': uploadedImageUrl,
                      'isGlobal': data['isGlobal'] ?? false,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    try {
                      if (isEdit) {
                        await FirebaseFirestore.instance.collection('member_benefits').doc(doc!.id).update(payload);
                      } else {
                        payload['createdAt'] = FieldValue.serverTimestamp();
                        await FirebaseFirestore.instance.collection('member_benefits').add(payload);
                      }
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      setState(() { isUploading = false; });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save benefit: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red, duration: const Duration(seconds: 5)));
                      }
                    }
                  },
                  child: isUploading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isEdit ? 'Save Changes' : 'Add Benefit'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Benefit'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('member_benefits').orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No global benefits created yet."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: Icon(_getIconData(data['icon'] ?? 'star'), color: Colors.blue),
                  ),
                  title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(data['description'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.orange), onPressed: () => _showAddEditDialog(context, doc)),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Confirm Delete"),
                                content: Text("Are you sure you want to delete '${data['title'] ?? 'this benefit'}'? This action cannot be undone."),
                                actions: [
                                  TextButton(
                                    child: const Text("Cancel"),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () {
                                      FirebaseFirestore.instance.collection('member_benefits').doc(doc.id).delete();
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Benefit deleted successfully')));
                                    },
                                    child: const Text("Delete", style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              );
                            },
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tab 2: Assign Benefits to Members
// ═══════════════════════════════════════════════════════════════════════════════
class AssignBenefitsTab extends StatefulWidget {
  const AssignBenefitsTab({super.key});

  @override
  State<AssignBenefitsTab> createState() => _AssignBenefitsTabState();
}

class _AssignBenefitsTabState extends State<AssignBenefitsTab> {
  String _searchQuery = '';

  void _showAssignDialog(BuildContext context, DocumentSnapshot memberDoc) async {
    final memberData = memberDoc.data() as Map<String, dynamic>;
    final String memberName = memberData['fullName'] ?? 'Unknown Member';
    final String memberNo = memberData['membershipNo'] ?? memberDoc.id;
    
    // Ensure it's a modifiable list of strings
    List<String> currentGranted = [];
    if (memberData['grantedBenefits'] is List) {
      currentGranted = List<String>.from(memberData['grantedBenefits']);
    }

    // Fetch all available global benefits
    final benefitsSnap = await FirebaseFirestore.instance.collection('member_benefits').orderBy('createdAt').get();
    final benefits = benefitsSnap.docs;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Assign Benefits: $memberName ($memberNo)', style: const TextStyle(fontSize: 16)),
              content: SizedBox(
                width: double.maxFinite,
                child: benefits.isEmpty 
                  ? const Text("No global benefits found. Add them first in the other tab.")
                  : ListView.builder(
                  shrinkWrap: true,
                  itemCount: benefits.length,
                  itemBuilder: (context, index) {
                    final benefitDoc = benefits[index];
                    final bData = benefitDoc.data();
                    final bId = benefitDoc.id;
                    final isGranted = currentGranted.contains(bId);

                    return CheckboxListTile(
                      title: Text(bData['title'] ?? ''),
                      subtitle: Text(bData['description'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                      value: isGranted,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            currentGranted.add(bId);
                          } else {
                            currentGranted.remove(bId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('member').doc(memberDoc.id).update({
                      'grantedBenefits': currentGranted,
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Benefits Updated Successfully! ✅')));
                    }
                  },
                  child: const Text('Save Assignments', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Search by Name or Mobile',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('member').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              
              final members = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['fullName'] ?? '').toString().toLowerCase();
                final mobile = (data['mobile'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery) || mobile.contains(_searchQuery);
              }).toList();

              return ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final doc = members[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final grantedList = data['grantedBenefits'] is List ? (data['grantedBenefits'] as List).length : 0;
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(data['fullName'] ?? 'Unknown Member'),
                      subtitle: Text("${data['mobile'] ?? ''} • ${data['membershipNo'] ?? doc.id}"),
                      trailing: ElevatedButton(
                        onPressed: () => _showAssignDialog(context, doc),
                        child: Text("Assign Benefits ($grantedList)"),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}