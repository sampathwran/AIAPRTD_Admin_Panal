import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> showDocumentMigrationDialog(BuildContext context) async {
  final oldIdController = TextEditingController();
  final newIdController = TextEditingController();
  bool isMigrating = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Migrate Document ID'),
          content: isMigrating 
            ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Warning: This will copy the member document to the new ID and delete the old one. Please ensure you update image URLs manually if needed.', style: TextStyle(color: Colors.red)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: oldIdController,
                    decoration: const InputDecoration(labelText: 'Old Document ID (e.g. AIAPRTD-26-0001)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: newIdController,
                    decoration: const InputDecoration(labelText: 'New Document ID (e.g. AIAPRTD-26-0891)', border: OutlineInputBorder()),
                  ),
                ],
              ),
          actions: [
            if (!isMigrating)
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            if (!isMigrating)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  final oldId = oldIdController.text.trim();
                  final newId = newIdController.text.trim();
                  if (oldId.isEmpty || newId.isEmpty) return;
                  
                  setState(() => isMigrating = true);
                  
                  try {
                    final collectionsToMigrate = [
                      'member',
                      'vehicles',
                      'verify_kyc',
                      'profile_images',
                      'app_membership_fee',
                      'web_sync_membership_fee',
                      'web_sync_member'
                    ];

                    bool foundAny = false;

                    for (String col in collectionsToMigrate) {
                      final oldDoc = await FirebaseFirestore.instance.collection(col).doc(oldId).get();
                      if (oldDoc.exists) {
                        foundAny = true;
                        final data = oldDoc.data()!;
                        
                        // Update IDs inside the document if they exist
                        if (data.containsKey('id')) data['id'] = newId;
                        if (data.containsKey('membershipNo')) data['membershipNo'] = newId;
                        if (data.containsKey('membership_no')) data['membership_no'] = newId;

                        await FirebaseFirestore.instance.collection(col).doc(newId).set(data);
                        await FirebaseFirestore.instance.collection(col).doc(oldId).delete();
                      }
                    }

                    if (foundAny) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Migrated successfully to $newId'), backgroundColor: Colors.green));
                      }
                    } else {
                      setState(() => isMigrating = false);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Old document not found in any collection!'), backgroundColor: Colors.red));
                    }
                  } catch (e) {
                    setState(() => isMigrating = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('Migrate', style: TextStyle(color: Colors.white)),
              ),
          ],
        );
      }
    ),
  );
}
