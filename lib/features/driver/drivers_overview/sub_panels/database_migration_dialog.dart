import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/member_provider.dart';

Future<void> showFullDatabaseMigrationDialog(BuildContext context) async {
  bool isLoading = true;
  List<DocumentSnapshot> invalidMembers = [];

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        
        // Fetch invalid members on load
        if (isLoading && invalidMembers.isEmpty) {
          FirebaseFirestore.instance.collection('member').get().then((snapshot) {
            final List<DocumentSnapshot> temp = [];
            for (var doc in snapshot.docs) {
              if (!doc.id.startsWith('AIAPRTD-')) {
                temp.add(doc);
              }
            }
            if (context.mounted) {
              setState(() {
                invalidMembers = temp;
                isLoading = false;
              });
            }
          });
        }

        return AlertDialog(
          title: const Text('Member ID Migration Panel'),
          content: SizedBox(
            width: 700,
            height: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Below is the list of members who have an Email or Phone Number as their Document ID instead of a proper Membership Number.\n'
                  'Click "Migrate" to automatically fix their profile, vehicles, and fees using the Membership Number saved in their profile.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                
                // Copy Web Sync Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('1. Copy ALL Web Sync Data to Main (Optional)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting Sync (Please Wait)...')));
                    
                    final db = FirebaseFirestore.instance;
                    WriteBatch batch = db.batch();
                    int count = 0;

                    final webMembers = await db.collection('web_sync_member').get();
                    for (var doc in webMembers.docs) {
                      batch.set(db.collection('member').doc(doc.id), doc.data(), SetOptions(merge: true));
                      count++;
                      if (count % 400 == 0) { await batch.commit(); batch = db.batch(); }
                    }

                    final webVehicles = await db.collection('web_sync_vehicle').get();
                    for (var doc in webVehicles.docs) {
                      batch.set(db.collection('vehicles').doc(doc.id), doc.data(), SetOptions(merge: true));
                      count++;
                      if (count % 400 == 0) { await batch.commit(); batch = db.batch(); }
                    }

                    final webFees = await db.collection('web_sync_membership_fee').get();
                    for (var doc in webFees.docs) {
                      batch.set(db.collection('app_membership_fee').doc(doc.id), doc.data(), SetOptions(merge: true));
                      count++;
                      if (count % 400 == 0) { await batch.commit(); batch = db.batch(); }
                    }
                    
                    await batch.commit();
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync Completed Successfully!'), backgroundColor: Colors.green));
                    }
                  }
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (invalidMembers.isEmpty)
                  const Center(child: Text('No invalid IDs found!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)))
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: invalidMembers.length,
                      itemBuilder: (context, index) {
                        final doc = invalidMembers[index];
                        final data = doc.data() as Map<String, dynamic>? ?? {};
                        final oldId = doc.id;
                        final String existingMemNo = data['membershipNo']?.toString() ?? 'MISSING';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(data['fullName']?.toString() ?? 'Unknown Name'),
                            subtitle: Text('Old ID: $oldId\nTarget ID: $existingMemNo'),
                            isThreeLine: true,
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
                              onPressed: existingMemNo == 'MISSING' || existingMemNo.isEmpty ? null : () async {
                                final bool confirm = await showDialog(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Confirm'),
                                    content: Text('Migrate $oldId to $existingMemNo?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
                                      ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Yes')),
                                    ],
                                  )
                                );
                                
                                if (confirm == true) {
                                  try {
                                    final batch = FirebaseFirestore.instance.batch();
                                    
                                    // 1. Member
                                    batch.set(FirebaseFirestore.instance.collection('member').doc(existingMemNo), data);
                                    batch.delete(doc.reference);
                                    
                                    // 2. Vehicle
                                    var vDoc = await FirebaseFirestore.instance.collection('vehicles').doc(oldId).get();
                                    if (vDoc.exists) {
                                      batch.set(FirebaseFirestore.instance.collection('vehicles').doc(existingMemNo), vDoc.data()!);
                                      batch.delete(vDoc.reference);
                                    }
                                    
                                    // 3. Fees
                                    var fDoc = await FirebaseFirestore.instance.collection('app_membership_fee').doc(oldId).get();
                                    if (fDoc.exists) {
                                      batch.set(FirebaseFirestore.instance.collection('app_membership_fee').doc(existingMemNo), fDoc.data()!);
                                      batch.delete(fDoc.reference);
                                    }
                                    
                                    // 4. Bank
                                    var bDoc = await FirebaseFirestore.instance.collection('bank_details').doc(oldId).get();
                                    if (bDoc.exists) {
                                      batch.set(FirebaseFirestore.instance.collection('bank_details').doc(existingMemNo), bDoc.data()!);
                                      batch.delete(bDoc.reference);
                                    }

                                    await batch.commit();

                                    setState(() {
                                      invalidMembers.removeAt(index);
                                    });
                                    
                                    if(context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Migrated Successfully!'), backgroundColor: Colors.green));
                                        Provider.of<MemberProvider>(context, listen: false).startListeningToMembers();
                                    }

                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                                    }
                                  }
                                }
                              },
                              child: const Text('Migrate'),
                            ),
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
              child: const Text('Close'),
            ),
          ],
        );
      },
    ),
  );
}

