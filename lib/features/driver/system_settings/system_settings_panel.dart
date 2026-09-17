import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/status_helpers.dart';

class SystemSettingsPanel extends StatefulWidget {
  const SystemSettingsPanel({super.key});

  @override
  State<SystemSettingsPanel> createState() => _SystemSettingsPanelState();
}

class _SystemSettingsPanelState extends State<SystemSettingsPanel> {
  bool _isMigrating = false;
  String _migrationStatus = '';

  Future<void> _repairInactiveReasons() async {
    setState(() {
      _isMigrating = true;
      _migrationStatus = 'Repairing inactive reasons...';
    });
    try {
      final db = FirebaseFirestore.instance;
      final membersSnap = await db.collection('member').get();
      int restored = 0;
      for (var doc in membersSnap.docs) {
        final id = doc.id;
        final inactiveRef = db.collection('member_inactive_reasons').doc(id);
        final inactiveDoc = await inactiveRef.get();
        final memData = doc.data();
        final uid = memData['auth_uid'] ?? memData['uid'] ?? '';
        
        final feeDoc = await db.collection('app_membership_fee').doc(id).get();
        String feeStatus = 'missing';
        if (feeDoc.exists) {
          final feeData = feeDoc.data() as Map<String, dynamic>;
          final feeCheck = checkMembershipFeeStatus(feeData);
          if (feeCheck['isFeePaidValid'] == true) {
            feeStatus = 'approved';
          } else {
            feeStatus = 'pending';
          }
        }

        bool needsRepair = false;
        
        if (!inactiveDoc.exists) {
          needsRepair = true;
        } else {
          final data = inactiveDoc.data() as Map<String, dynamic>;
          if (data.containsKey('restored_by_admin')) {
            needsRepair = true;
          } else if (data['membership_fee'] == 'missing' && feeStatus == 'approved') {
            needsRepair = true;
          }
        }

        if (needsRepair) {
          if (inactiveDoc.exists && !inactiveDoc.data()!.containsKey('restored_by_admin')) {
            await inactiveRef.update({'membership_fee': feeStatus});
          } else {
            await inactiveRef.set({
              'admin_block_permanently': false,
              'admin_block_temporarily': false,
              'driving_licence': 'missing',
              'face_verification': 'missing',
              'id_card_image': 'missing',
              'insurance_policy': 'missing',
              'kyc_details': 'missing',
              'last_updated': FieldValue.serverTimestamp(),
              'membershipNo': id,
              'membership_fee': feeStatus,
              'profile_image': 'missing',
              'revenue_licence': 'missing',
              'status': 'INACTIVE',
              'uid': uid,
              'vehicle_image_back': 'missing',
              'vehicle_image_front': 'missing',
              'vehicle_image_interior': 'missing',
              'vehicle_image_left_side': 'missing',
              'vehicle_image_right_side': 'missing',
              'vehicle_registration_document': 'missing',
              'inactive_reasons': FieldValue.delete(),
              'restored_by_admin': FieldValue.delete(),
            }, SetOptions(merge: true));
          }
          restored++;
        }
      }
      setState(() {
        _migrationStatus = 'Done! Repaired $restored documents.';
        _isMigrating = false;
      });
    } catch (e) {
      setState(() {
        _migrationStatus = 'Error: $e';
        _isMigrating = false;
      });
    }
  }

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
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isMigrating ? null : _repairInactiveReasons,
                      icon: const Icon(Icons.build),
                      label: const Text('Repair Missing Inactive Reasons Docs'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Legacy Data Migration',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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




