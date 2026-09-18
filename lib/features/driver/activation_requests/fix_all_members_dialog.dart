import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FixAllMembersDialog extends StatefulWidget {
  const FixAllMembersDialog({super.key});

  @override
  State<FixAllMembersDialog> createState() => _FixAllMembersDialogState();
}

class _FixAllMembersDialogState extends State<FixAllMembersDialog> {
  bool isProcessing = true;
  int totalScanned = 0;
  List<String> fixedMembers = [];
  String currentStatus = "Initializing...";

  @override
  void initState() {
    super.initState();
    _startFixProcess();
  }

  Future<void> _startFixProcess() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      setState(() {
        currentStatus = "Fetching all vehicles...";
      });
      final vehiclesSnap = await firestore.collection('vehicles').get();
      
      int updatedCount = 0;

      for (int i = 0; i < vehiclesSnap.docs.length; i++) {
        var vDoc = vehiclesSnap.docs[i];
        String membershipNo = vDoc.id;
        Map<String, dynamic> vData = vDoc.data();
        bool needsUpdate = false;
        Map<String, dynamic> updates = {};
        
        setState(() {
           totalScanned = i + 1;
           currentStatus = "Scanning " + membershipNo + "...";
        });

        // 1. Fix missing membershipNo
        if (vData['membershipNo'] == null || vData['membershipNo'].toString().isEmpty) {
          updates['membershipNo'] = membershipNo;
          needsUpdate = true;
        }

        // 2. Fix missing memberName
        if (vData['memberName'] == null || vData['memberName'] == 'Unknown Member' || vData['memberName'].toString().isEmpty) {
          final membersQuery = await firestore.collection('members').where('membershipNo', isEqualTo: membershipNo).limit(1).get();
          if (membersQuery.docs.isNotEmpty) {
            String realName = membersQuery.docs.first.data()['name'] ?? 'Unknown Member';
            updates['memberName'] = realName;
            
            if (membersQuery.docs.first.data()['uid'] != null) {
                updates['uid'] = membersQuery.docs.first.data()['uid'];
            }
            needsUpdate = true;
          }
        }

        // Apply direct vehicle updates
        if (needsUpdate) {
          await vDoc.reference.update(updates);
          updatedCount++;
          
          setState(() {
             fixedMembers.add(membershipNo + " (Name Fixed)");
          });
        }

        // 3. Fix Sync Lock
        final reasonQuery = await firestore.collection('member_inactive_reasons').where('membershipNo', isEqualTo: membershipNo).limit(1).get();
        if (reasonQuery.docs.isNotEmpty) {
           final reasonDoc = reasonQuery.docs.first;
           final rData = reasonDoc.data();
           final fields = [
             'vehicle_registration_document', 'revenue_licence', 'insurance_policy', 'driving_licence',
             'vehicle_image_front', 'vehicle_image_back', 'vehicle_image_left_side', 'vehicle_image_right_side', 'vehicle_image_interior',
           ];
           bool hasPending = false;
           for (var field in fields) {
             if (rData.containsKey(field) && (rData[field] == 'pending_approval' || rData[field] == 'pending')) {
               hasPending = true;
               break;
             }
           }
           
           if (hasPending && vData['status'] != 'pending') {
              await vDoc.reference.update({'status': 'pending'});
              setState(() {
                 if (!fixedMembers.contains(membershipNo + " (Name Fixed)")) {
                    fixedMembers.add(membershipNo + " (Sync Fixed)");
                 } else {
                    fixedMembers[fixedMembers.length - 1] = membershipNo + " (Name & Sync Fixed)";
                 }
              });
           }
        }
      }
      
      setState(() {
        isProcessing = false;
        currentStatus = "Finished! Scanned " + totalScanned.toString() + ", Fixed " + fixedMembers.length.toString() + ".";
      });

    } catch (e) {
      setState(() {
        isProcessing = false;
        currentStatus = "Error: " + e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Fixing Member Sync Issues"),
      content: SizedBox(
        width: 600,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isProcessing) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                if (isProcessing) const SizedBox(width: 16),
                Expanded(child: Text(currentStatus, style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 16),
            const Text("Fixed Members:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                child: ListView.builder(
                  itemCount: fixedMembers.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text((index + 1).toString() + ". " + fixedMembers[index]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!isProcessing)
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
      ],
    );
  }
}
