import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final webMembers = await FirebaseFirestore.instance.collection('web_sync_member').get();
  print('Found ${webMembers.docs.length} members to sync');
  int count = 0;
  for (var doc in webMembers.docs) {
    await FirebaseFirestore.instance.collection('member').doc(doc.id).set(doc.data(), SetOptions(merge: true));
    count++;
    print('Synced $count');
  }
  print('Done!');
}
