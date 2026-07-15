import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileUpdateRequests extends StatelessWidget {
  const ProfileUpdateRequests({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile Image Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('status', isEqualTo: 'pending')
            .where('requestType', isEqualTo: 'profile_update')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty)
            return const Center(child: Text("No pending requests"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: Image.network(
                  data['newImageUrl'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                title: Text("Mem No: ${data['membershipNo']}"),
                subtitle: const Text("Status: Pending"),
                trailing: IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () {
                    // මෙතන තමයි කලින් අපි කතා කරපු Approve logic එක දාන්නේ
                    _approveRequest(docs[index].id, data);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _approveRequest(String docId, Map<String, dynamic> data) async {
    // 1. Profile update එකේ තියෙන පින්තූරෙ update කිරීම
    await FirebaseFirestore.instance
        .collection('profileimage')
        .doc(data['membershipNo'])
        .set({'profileImageUrl': data['newImageUrl']}, SetOptions(merge: true));

    // 2. Request status එක 'approved' කිරීම
    await FirebaseFirestore.instance.collection('requests').doc(docId).update({
      'status': 'approved',
    });
  }
}
