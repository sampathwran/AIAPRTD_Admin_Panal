import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleRequestProvider with ChangeNotifier {
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  void _setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  // =========================================================================
  // 1. වාහනයක් අනුමත කිරීම (Approve Request)
  // =========================================================================
  Future<bool> approveRequest(String requestId) async {
    _setProcessing(true);
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final String membershipNo = requestId; // In vehicles collection, docId is membershipNo

      DocumentSnapshot snap = await firestore.collection('vehicles').doc(requestId).get();
      if (!snap.exists || snap.data() == null) {
        _setProcessing(false);
        return false;
      }

      Map<String, dynamic> data = snap.data() as Map<String, dynamic>;

      if (data['selectedCategory'] == null) {
        _setProcessing(false);
        return false; // Category එක නැත්නම් Approve කරන්න එපා
      }

      // 1. Find Member Document
      String? memberDocId;
      Map<String, dynamic>? memberData;

      QuerySnapshot memberQuery = await firestore.collection('member').where('membershipNo', isEqualTo: membershipNo).get();
      if (memberQuery.docs.isNotEmpty) {
        memberDocId = memberQuery.docs.first.id;
        memberData = memberQuery.docs.first.data() as Map<String, dynamic>?;
      } else {
        // Fallback: Check if document ID itself is the membershipNo
        DocumentSnapshot docSnap = await firestore.collection('member').doc(membershipNo).get();
        if (docSnap.exists) {
          memberDocId = docSnap.id;
          memberData = docSnap.data() as Map<String, dynamic>?;
        }
      }

      final WriteBatch batch = firestore.batch();

      if (memberDocId != null && memberData != null) {
        final DocumentReference memberRef = firestore.collection('member').doc(memberDocId);
        
        // 2. Handle Vehicle History
        if (memberData.containsKey('currentVehicle') && memberData['currentVehicle'] != null) {
          final Map<String, dynamic> oldVehicle = Map<String, dynamic>.from(memberData['currentVehicle']);
          List<dynamic> history = List.from(memberData['vehicleHistory'] ?? []);
          history.add(oldVehicle);
          
          batch.update(memberRef, {
            'vehicleHistory': history,
          });
        }

        // 3. Set New Current Vehicle
        batch.update(memberRef, {
          'currentVehicle': {
            ...data,
            'approvedAt': FieldValue.serverTimestamp(),
          }
        });
      }

      // 4. Update Vehicles Collection Status
      batch.update(firestore.collection('vehicles').doc(requestId), {
        'status': 'approved',
        'canEdit': false,
        'processedAt': FieldValue.serverTimestamp(),
      });
      
      await batch.commit();

      _setProcessing(false);
      return true;
    } catch (e) {
      debugPrint("Error approving request: $e");
      _setProcessing(false);
      return false;
    }
  }

  // =========================================================================
  // 2. වාහනයක් ප්‍රතික්ෂේප කිරීම (Reject Request)
  // =========================================================================
  Future<bool> rejectRequest(String requestId, String reason) async {
    _setProcessing(true);
    try {
      await FirebaseFirestore.instance.collection('vehicles').doc(requestId).update({
        'status': 'rejected',
        'canEdit': true,
        'rejectionReason': reason,
        'processedAt': FieldValue.serverTimestamp(),
      });
      _setProcessing(false);
      return true;
    } catch (e) {
      debugPrint("Error rejecting request: $e");
      _setProcessing(false);
      return false;
    }
  }

  // =========================================================================
  // 3. වාහනයේ පින්තූරයක් අනුමත කිරීම (Approve Photo)
  // =========================================================================
  Future<void> approveVehiclePhoto(String requestId, String label) async {
    try {
      DocumentReference docRef = FirebaseFirestore.instance.collection('vehicles').doc(requestId);
      DocumentSnapshot doc = await docRef.get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, dynamic> photos = Map<String, dynamic>.from(data['vehiclePhotos'] ?? {});

        if (photos.containsKey(label)) {
          photos[label]['status'] = 'approved';
          await docRef.update({'vehiclePhotos': photos});
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error approving photo: $e");
    }
  }

  // =========================================================================
  // 4. Document එකක් අනුමත කිරීම/ප්‍රතික්ෂේප කිරීම (Update Document Status)
  // =========================================================================
  Future<void> updateDocumentStatus(String requestId, int index, String status, Map<String, dynamic> details) async {
    try {
      DocumentReference docRef = FirebaseFirestore.instance.collection('vehicles').doc(requestId);
      DocumentSnapshot snap = await docRef.get();

      if (!snap.exists) return;

      List<dynamic> docs = List.from(snap.get('documents') ?? []);

      if (index >= 0 && index < docs.length) {
        docs[index]['status'] = status;
        docs[index]['reason'] = details['reason'] ?? "";
        docs[index]['reviewData'] = details;

        await docRef.update({'documents': docs});
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error updating document status: $e");
    }
  }

  // =========================================================================
  // 5. වාහන කාණ්ඩය (Category) Update කිරීම
  // =========================================================================
  Future<void> updateVehicleCategory(String requestId, String category) async {
    try {
      await FirebaseFirestore.instance.collection('vehicles').doc(requestId).update({
        'selectedCategory': category,
      });
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating category: $e");
    }
  }

  // =========================================================================
  // 6. Duplicate වාහන හඳුනා ගැනීම (Check Duplicate)
  // =========================================================================
  Future<Map<String, dynamic>?> checkDuplicateVehicle(String field, String value) async {
    try {
      var query = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('status', isEqualTo: 'approved')
          .where('details.$field', isEqualTo: value)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }
    } catch (e) {
      debugPrint("Error checking duplicate: $e");
    }
    return null;
  }

  // =========================================================================
  // 7. වාහනයේ පින්තූරයක් ප්‍රතික්ෂේප කිරීම (Reject Photo)
  // =========================================================================
  Future<void> rejectVehiclePhoto(String requestId, String label, String reason) async {
    try {
      DocumentReference docRef = FirebaseFirestore.instance.collection('vehicles').doc(requestId);
      DocumentSnapshot doc = await docRef.get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, dynamic> photos = Map<String, dynamic>.from(data['vehiclePhotos'] ?? {});

        if (photos.containsKey(label)) {
          photos[label]['status'] = 'rejected';
          photos[label]['rejectionReason'] = reason;
          await docRef.update({'vehiclePhotos': photos});
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error rejecting photo: $e");
    }
  }

  // =========================================================================
  // 7. Data Migration: Move existing approved vehicles to member collection
  // =========================================================================
  Future<void> migrateApprovedVehiclesToMemberCollection() async {
    _setProcessing(true);
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      // Get all approved vehicles
      QuerySnapshot vehiclesSnap = await firestore
          .collection('vehicles')
          .where('status', isEqualTo: 'approved')
          .get();

      debugPrint("Found ${vehiclesSnap.docs.length} approved vehicles to migrate.");

      final WriteBatch batch = firestore.batch();
      int count = 0;

      for (var vehicleDoc in vehiclesSnap.docs) {
        String membershipNo = vehicleDoc.id;
        Map<String, dynamic> vehicleData = vehicleDoc.data() as Map<String, dynamic>;

        // Find corresponding member
        String? memberDocId;
        QuerySnapshot memberQuery = await firestore.collection('member').where('membershipNo', isEqualTo: membershipNo).get();
        
        if (memberQuery.docs.isNotEmpty) {
          memberDocId = memberQuery.docs.first.id;
        } else {
          DocumentSnapshot docSnap = await firestore.collection('member').doc(membershipNo).get();
          if (docSnap.exists) {
            memberDocId = docSnap.id;
          }
        }

        if (memberDocId != null) {
          DocumentReference memberRef = firestore.collection('member').doc(memberDocId);
          
          batch.update(memberRef, {
            'currentVehicle': {
              ...vehicleData,
              'migratedAt': FieldValue.serverTimestamp(),
            }
          });
          count++;
        }
      }

      if (count > 0) {
        await batch.commit();
        debugPrint("Successfully migrated $count vehicles to member collection.");
      } else {
        debugPrint("No vehicles needed migration.");
      }
      
      _setProcessing(false);
    } catch (e) {
      debugPrint("Error migrating vehicles: $e");
      _setProcessing(false);
    }
  }

  // =========================================================================
  // 7.5 Fix Stuck Pending Vehicles
  // =========================================================================
  Future<void> fixStuckPendingVehicles() async {
    _setProcessing(true);
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      QuerySnapshot vehiclesSnap = await firestore
          .collection('vehicles')
          .where('status', isEqualTo: 'approved')
          .get();

      int fixedCount = 0;
      final WriteBatch batch = firestore.batch();

      for (var vehicleDoc in vehiclesSnap.docs) {
        Map<String, dynamic> data = vehicleDoc.data() as Map<String, dynamic>;
        
        bool hasPending = false;
        
        // Check documents
        List<dynamic> docs = data['documents'] ?? [];
        for (var docItem in docs) {
          if (docItem is Map && docItem['status'] == 'pending') {
            hasPending = true;
            break;
          }
        }
        
        // Check vehicle photos
        if (!hasPending && data['vehiclePhotos'] != null) {
          Map<String, dynamic> photos = Map<String, dynamic>.from(data['vehiclePhotos']);
          for (var photo in photos.values) {
            if (photo is Map && photo['status'] == 'pending') {
              hasPending = true;
              break;
            }
          }
        }

        if (hasPending) {
          batch.update(vehicleDoc.reference, {'status': 'pending'});
          fixedCount++;
        }
      }

      if (fixedCount > 0) {
        await batch.commit();
        debugPrint("Fixed $fixedCount stuck vehicles!");
      }

      _setProcessing(false);
    } catch (e) {
      debugPrint("Error fixing stuck vehicles: $e");
      _setProcessing(false);
    }
  }

  // =========================================================================
  // 📡 8. DYNAMIC FIXED RATES UPDATER ENGINE
  // =========================================================================
  Future<bool> updateVehicleRates({
    required String categoryId,      // 💡 උදා: 'budget', 'mini', '6_seater'
    required String vehicleDocId,     // 💡 උදා: 'AIAPRTD-25-0001'
    required double baseFare,
    required double baseDistance,
    required double perKm,
    required double perMinute,
    required double nightFarePct,
    required double peakFarePct,
  }) async {
    try {
      final Map<String, dynamic> rateData = {
        'categoryId': categoryId,
        'baseFare': baseFare,
        'baseDistance': baseDistance,
        'perKm': perKm,
        'perMinute': perMinute,
        'nightFarePct': nightFarePct,
        'peakFarePct': peakFarePct,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // I. ස්වාධීන 'rates' කලෙක්ෂන් එකට දත්ත ලියනවා මචං (Clean Architecture)
      await FirebaseFirestore.instance
          .collection('rates')
          .doc(categoryId)
          .set(rateData, SetOptions(merge: true));

      // II. වාහන ඩොකියුමන්ට් එක ඇතුළේ මුළු මැප් එකම ඩුප්ලිකේට් නොකර,
      // Rates කලෙක්ෂන් එකේ අදාළ Document ID (Reference Key) එක විතරක් සේව් කරනවා මචං
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleDocId)
          .set({
        'rateProfileRef': categoryId,
        'ratesLastSynced': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("❌ FIREBASE CENTRAL RATES SYNC ERROR: $e");
      return false;
    }
  }
}