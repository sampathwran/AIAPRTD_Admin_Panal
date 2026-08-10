import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final docRef = FirebaseFirestore.instance.collection('driver_services_hub').doc();
  await docRef.set({
    'id': docRef.id,
    'label': 'Marketplace',
    'icon': 'storefront',
    'colorHex': '#FF9800',
    'actionType': 'internal_route',
    'actionTarget': '/marketplace',
    'isActive': true,
    'order': 1,
  });
  
  print('Marketplace added to driver_services_hub');
}
