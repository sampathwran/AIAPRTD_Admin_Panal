import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SystemSettingsPanel extends StatefulWidget {
  const SystemSettingsPanel({super.key});

  @override
  State<SystemSettingsPanel> createState() => _SystemSettingsPanelState();
}

class _SystemSettingsPanelState extends State<SystemSettingsPanel> {
  bool _isMigrating = false;
  String _migrationStatus = '';

  Future<void> _runEmailIdMigration() async {
    setState(() {
      _isMigrating = true;
      _migrationStatus = 'Starting migration...';
    });

    try {
      final db = FirebaseFirestore.instance;
      int migratedMembers = 0;
      int migratedFees = 0;

      // 1. Migrate Member collection
      final memberSnap = await db.collection('member').get();
      for (var doc in memberSnap.docs) {
        if (doc.id.contains('@')) {
          final data = doc.data();
          final memNo = (data['membershipNo']?.toString() ?? '').trim();
          
          if (memNo.isNotEmpty) {
            setState(() => _migrationStatus = 'Migrating member ${doc.id} -> $memNo');
            
            // Set under memNo
            await db.collection('member').doc(memNo).set(data, SetOptions(merge: true));
            // Delete old email doc
            await db.collection('member').doc(doc.id).delete();
            migratedMembers++;
          }
        }
      }

      // 2. Migrate App Membership Fee collection
      final feeSnap = await db.collection('app_membership_fee').get();
      for (var doc in feeSnap.docs) {
        if (doc.id.contains('@')) {
          final data = doc.data();
          final memNo = (data['membershipNo']?.toString() ?? '').trim();
          
          // If membershipNo is not directly in the fee doc, we must find it via member collection
          String targetMemNo = memNo;
          if (targetMemNo.isEmpty) {
             final memberQuery = await db.collection('member').where('user_email', isEqualTo: doc.id).limit(1).get();
             if (memberQuery.docs.isNotEmpty) {
               targetMemNo = (memberQuery.docs.first.data()['membershipNo']?.toString() ?? '').trim();
             } else {
               // Try checking if doc.id is email
               final memberQuery2 = await db.collection('member').where('email', isEqualTo: doc.id).limit(1).get();
               if (memberQuery2.docs.isNotEmpty) {
                 targetMemNo = (memberQuery2.docs.first.data()['membershipNo']?.toString() ?? '').trim();
               }
             }
          }

          if (targetMemNo.isNotEmpty) {
            setState(() => _migrationStatus = 'Migrating fee ${doc.id} -> $targetMemNo');
            
            await db.collection('app_membership_fee').doc(targetMemNo).set(data, SetOptions(merge: true));
            await db.collection('app_membership_fee').doc(doc.id).delete();
            migratedFees++;
          }
        }
      }

      // 3. Clean up Web Sync Collections (Delete email docs)
      final webSyncCols = ['web_sync_member', 'web_sync_membership_fee', 'web_sync_vehicle'];
      for (var col in webSyncCols) {
        final snap = await db.collection(col).get();
        for (var doc in snap.docs) {
          if (doc.id.contains('@')) {
            // Check if a Membership Number document already exists for this user data
            final memNo = (doc.data()['membershipNo']?.toString() ?? '').trim();
            if (memNo.isNotEmpty && memNo != doc.id) {
               setState(() => _migrationStatus = 'Deleting duplicate web sync email doc: ${doc.id} in $col');
               await db.collection(col).doc(doc.id).delete();
            } else {
               // If there is no Membership Number for some reason, maybe we should still delete the email document?
               // Yes, the prompt says "membership number eken witharai document eka hadenna one."
               setState(() => _migrationStatus = 'Deleting stray email doc: ${doc.id} in $col');
               await db.collection(col).doc(doc.id).delete();
            }
          }
        }
      }

      setState(() {
        _migrationStatus = 'Done! Migrated $migratedMembers members, $migratedFees fees, and cleaned web sync collections.';
      });
    } catch (e) {
      setState(() {
        _migrationStatus = 'Error: $e';
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Configurations',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Data Migration Tools',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Use this tool to fix users who logged in with their Email Address instead of their Membership Number. It will move their data to the correct Membership Number Document ID and clear up duplicate records.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isMigrating ? null : _runEmailIdMigration,
                    icon: _isMigrating 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.build),
                    label: const Text('Fix Email Login Data Mismatches'),
                  ),
                  if (_migrationStatus.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(_migrationStatus, style: TextStyle(color: _migrationStatus.startsWith('Error') ? Colors.red : Colors.green)),
                  ]
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
