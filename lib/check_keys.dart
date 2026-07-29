import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final snap = await FirebaseFirestore.instance
      .collection('all_bookings')
      .limit(5)
      .get();
  for (var doc in snap.docs) {
    print("----- BOOKING ${doc.id} -----");
    final data = doc.data();
    data.forEach((key, value) {
      if (key.toLowerCase().contains('time') ||
          key.toLowerCase().contains('date') ||
          key.toLowerCase().contains('at') ||
          value is Timestamp) {
        print("$key: $value");
      }
    });
  }
}
