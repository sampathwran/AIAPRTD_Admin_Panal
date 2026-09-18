import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:aiaprtd_admin_dashboard/core/services/history_service.dart';
import 'package:aiaprtd_admin_dashboard/core/utils/notification_helper.dart';

class VehicleRequestProvider with ChangeNotifier {
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  void _setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  // =========================================================================
  // Fix ALL Members Sync and Unknown Names
  // =========================================================================
  Future<void> fixAllMembersGlobalSync() async {
    try {
      _setProcessing(true);
      final firestore = FirebaseFirestore.instance;
      
      final vehiclesSnap = await firestore.collection('vehicles').get();
      int updatedCount = 0;

      for (var vDoc in vehiclesSnap.docs) {
        String membershipNo = vDoc.id;
        Map<String, dynamic> vData = vDoc.data();
        bool needsUpdate = false;
        Map<String, dynamic> updates = {};

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
            
            // Also grab uid if available
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
           }
        }
      }
      
      print("Global sync finished! Updated $updatedCount vehicles.");

    } catch (e) {
      print('Error in fixAllMembersGlobalSync: $e');
    } finally {
      _setProcessing(false);
    }
  }

  // =========================================================================
  // Fix Member Sync (Manually sync 'member_inactive_reasons' and 'vehicles')
  // =========================================================================
  Future<void> fixMemberSync(String membershipNo, String uid) async {
    try {
      _setProcessing(true);
      
      // 1. Fetch member_inactive_reasons
      final query = await FirebaseFirestore.instance
          .collection('member_inactive_reasons')
          .where('membershipNo', isEqualTo: membershipNo)
          .limit(1)
          .get();
          
      if (query.docs.isEmpty) {
        _setProcessing(false);
        return;
      }
      
      final reasonDoc = query.docs.first;
      final data = reasonDoc.data();
      
      // Fields to check
      final fields = [
        'vehicle_registration_document',
        'revenue_licence',
        'insurance_policy',
        'driving_licence',
        'vehicle_image_front',
        'vehicle_image_back',
        'vehicle_image_left_side',
        'vehicle_image_right_side',
        'vehicle_image_interior',
      ];
      
      bool hasPending = false;
      for (var field in fields) {
        if (data.containsKey(field) && (data[field] == 'pending_approval' || data[field] == 'pending')) {
          hasPending = true;
          break;
        }
      }
      
      // 2. Fetch vehicles document
      final vehicleRef = FirebaseFirestore.instance.collection('vehicles').doc(membershipNo);
      final vehicleDoc = await vehicleRef.get();
      
      if (hasPending) {
        // If they genuinely have pending fields but the vehicle is not pending, force it!
        if (vehicleDoc.exists) {
          final vData = vehicleDoc.data()!;
          if (vData['status'] != 'pending') {
            await vehicleRef.update({'status': 'pending'});
          }
        }
      } else {
        // If they have NO pending fields but are still stuck in INACTIVE!
        // We should clear their lock! (Or mark everything approved).
        final updateData = <String, dynamic>{};
        for (var field in fields) {
          if (data.containsKey(field) && data[field] == 'missing') {
             // Leave missing alone
          } else {
             // updateData[field] = 'approved'; 
          }
        }
        
        if (data['status'] == 'INACTIVE' && updateData.isNotEmpty) {
           await reasonDoc.reference.update(updateData);
        }
      }
      
    } catch (e) {
      print('Error fixing sync: $e');
    } finally {
      _setProcessing(false);
    }
  }

  // =========================================================================
  // Fix Missing Image URLs (Scans Firebase Storage and updates DB if URL is empty)
  // =========================================================================
  Future<void> fixMissingImageUrls(String membershipNo) async {
    try {
      _setProcessing(true);
      final docRef = FirebaseFirestore.instance.collection('vehicles').doc(membershipNo);
      final snap = await docRef.get();
      if (!snap.exists) return;

      final data = snap.data()!;
      bool updated = false;

      // 1. Fix Documents (doc_0.jpg, doc_1.jpg etc.)
      if (data.containsKey('documents')) {
        List<dynamic> docs = List.from(data['documents']);
        for (int i = 0; i < docs.length; i++) {
          if ((docs[i]['url'] == null || docs[i]['url'].toString().isEmpty) &&
              (docs[i]['status'] == 'pending_approval' || docs[i]['status'] == 'approved' || docs[i]['status'] == 'pending')) {
            try {
               final ref = FirebaseStorage.instance.ref().child('compliance_docs/$membershipNo/doc_$i.jpg');
               final url = await ref.getDownloadURL();
               docs[i]['url'] = url;
               updated = true;
               print("Fixed URL for doc_$i");
            } catch(e) {
               try {
                  final ref = FirebaseStorage.instance.ref().child('compliance_docs/$membershipNo/doc_$i.png');
                  final url = await ref.getDownloadURL();
                  docs[i]['url'] = url;
                  updated = true;
               } catch(e2) {}
            }
          }
        }
        if (updated) {
          await docRef.update({'documents': docs});
        }
      }

      // 2. Fix Vehicle Photos
      if (data.containsKey('vehiclePhotos')) {
        Map<String, dynamic> photos = Map<String, dynamic>.from(data['vehiclePhotos']);
        bool photosUpdated = false;

        // Cleanup duplicates (e.g. keep "Front" instead of "Front View" if both exist, or rename "Front View" to "Front")
        final standardLabels = ['Front', 'Back', 'Left Side', 'Right Side', 'Interior'];
        final Map<String, dynamic> cleanedPhotos = {};
        
        for (var label in standardLabels) {
           if (photos.containsKey(label)) {
              cleanedPhotos[label] = photos[label];
           } else if (photos.containsKey('$label View')) {
              cleanedPhotos[label] = photos['$label View'];
              photosUpdated = true;
           } else {
              // Not uploaded yet
           }
        }
        
        if (photos.length != cleanedPhotos.length) {
           photos = cleanedPhotos;
           photosUpdated = true;
        }

        try {
          final listResult = await FirebaseStorage.instance.ref().child('vehicle_photos/$membershipNo').listAll();
          final availableFiles = listResult.items;

          for (var entry in photos.entries) {
            String label = entry.key; // e.g. "Front", "Back"
            var photoData = entry.value as Map<String, dynamic>;
            
            if ((photoData['url'] == null || photoData['url'].toString().isEmpty) &&
               (photoData['status'] == 'pending_approval' || photoData['status'] == 'approved' || photoData['status'] == 'pending')) {
              
              String guessName = label.toLowerCase().split(' ').first; // "front", "back", "left", "right", "interior"
              for(var item in availableFiles) {
                 if(item.name.toLowerCase().contains(guessName)) {
                    final url = await item.getDownloadURL();
                    photos[label]['url'] = url;
                    photosUpdated = true;
                    print("Fixed URL for photo $label using file ${item.name}");
                    break;
                 }
              }
            }
          }
          if(photosUpdated) {
             await docRef.update({'vehiclePhotos': photos});
          }
        } catch(e) {
           print("Error listing vehicle photos: $e");
        }
      }

    } catch (e) {
      print('Error fixing URLs: $e');
    } finally {
      _setProcessing(false);
    }
  }

  // =========================================================================
  // 1. වාහනයක් අනුමත කිරීම (Approve Request)
  // =========================================================================
  Future<bool> approveRequest(String requestId) async {
    _setProcessing(true);
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final String membershipNo =
          requestId; // In vehicles collection, docId is membershipNo

      DocumentSnapshot snap = await firestore
          .collection('vehicles')
          .doc(requestId)
          .get();
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

      QuerySnapshot memberQuery = await firestore
          .collection('member')
          .where('membershipNo', isEqualTo: membershipNo)
          .get();
      if (memberQuery.docs.isNotEmpty) {
        memberDocId = memberQuery.docs.first.id;
        memberData = memberQuery.docs.first.data() as Map<String, dynamic>?;
      } else {
        // Fallback: Check if document ID itself is the membershipNo
        DocumentSnapshot docSnap = await firestore
            .collection('member')
            .doc(membershipNo)
            .get();
        if (docSnap.exists) {
          memberDocId = docSnap.id;
          memberData = docSnap.data() as Map<String, dynamic>?;
        }
      }

      final WriteBatch batch = firestore.batch();

      if (memberDocId != null && memberData != null) {
        final DocumentReference memberRef = firestore
            .collection('member')
            .doc(memberDocId);

        // 2. Handle Vehicle History
        if (memberData.containsKey('currentVehicle') &&
            memberData['currentVehicle'] != null) {
          final Map<String, dynamic> oldVehicle = Map<String, dynamic>.from(
            memberData['currentVehicle'],
          );
          List<dynamic> history = List.from(memberData['vehicleHistory'] ?? []);
          history.add(oldVehicle);

          batch.update(memberRef, {'vehicleHistory': history});
        }

        // 3. Set New Current Vehicle
        batch.update(memberRef, {
          'currentVehicle': {
            ...data,
            'approvedAt': FieldValue.serverTimestamp(),
          },
        });
      }

      // 4. Update Vehicles Collection Status
      batch.update(firestore.collection('vehicles').doc(requestId), {
        'status': 'approved',
        'canEdit': false,
        'processedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      await HistoryService.logActivationAction(
        type: 'VEHICLE_CHANGE',
        membershipNo: membershipNo,
        status: 'approved',
        requestData: data,
      );

      await NotificationHelper.sendNotification(
        membershipNo: membershipNo,
        title: 'Vehicle Approved',
        body: 'Your vehicle details have been approved!',
      );

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
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(requestId)
          .update({
            'status': 'rejected',
            'canEdit': true,
            'rejectionReason': reason,
            'processedAt': FieldValue.serverTimestamp(),
          });

      await HistoryService.logActivationAction(
        type: 'VEHICLE_CHANGE',
        membershipNo: requestId,
        status: 'rejected',
        requestData: {'reason': reason},
        remarks: reason,
      );

      await NotificationHelper.sendNotification(
        membershipNo: requestId,
        title: 'Vehicle Rejected',
        body: 'Your vehicle details were rejected.\n\nREASON: $reason',
      );

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
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('vehicles')
          .doc(requestId);
      DocumentSnapshot doc = await docRef.get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, dynamic> photos = Map<String, dynamic>.from(
          data['vehiclePhotos'] ?? {},
        );

        if (photos.containsKey(label)) {
          photos[label]['status'] = 'approved';
          await docRef.update({'vehiclePhotos': photos});
          
          // Sync to inactive reasons
          String fieldName = '';
          if (label == 'Front') fieldName = 'vehicle_image_front';
          else if (label == 'Back') fieldName = 'vehicle_image_back';
          else if (label == 'Left Side') fieldName = 'vehicle_image_left_side';
          else if (label == 'Right Side') fieldName = 'vehicle_image_right_side';
          else if (label == 'Interior') fieldName = 'vehicle_image_interior';
          
          if (fieldName.isNotEmpty) {
            await _syncToInactiveReasons(requestId, fieldName, 'approved');
          }
          
          await NotificationHelper.sendNotification(
            membershipNo: requestId,
            title: 'Vehicle Photo Approved',
            body: 'Your vehicle photo ($label) has been approved!',
          );
          
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
  Future<void> updateDocumentStatus(
    String requestId,
    int index,
    String status,
    Map<String, dynamic> details,
  ) async {
    try {
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('vehicles')
          .doc(requestId);
      DocumentSnapshot snap = await docRef.get();

      if (!snap.exists) return;

      List<dynamic> docs = List.from(snap.get('documents') ?? []);

      if (index >= 0 && index < docs.length) {
        docs[index]['status'] = status;
        docs[index]['reason'] = details['reason'] ?? "";
        docs[index]['reviewData'] = details;

        await docRef.update({'documents': docs});
        
        // Sync to inactive reasons
        String fieldName = '';
        if (index == 0) fieldName = 'vehicle_registration_document';
        else if (index == 1) fieldName = 'revenue_licence';
        else if (index == 2) fieldName = 'insurance_policy';
        else if (index == 3 || index == 4) fieldName = 'driving_licence';
        
        if (fieldName.isNotEmpty) {
          await _syncToInactiveReasons(requestId, fieldName, status);
        }
        
        final titles = [
          "Revenue License",
          "Insurance Policy",
          "Registration Document",
          "Driving License (Front)",
          "Driving License (Back)",
        ];
        String docTitle = titles.length > index ? titles[index] : "Document";
        
        if (status == 'approved') {
          await NotificationHelper.sendNotification(
            membershipNo: requestId,
            title: '$docTitle Approved',
            body: 'Your $docTitle has been approved!',
          );
        } else if (status == 'rejected') {
          String reason = details['reason'] ?? 'No reason provided';
          await NotificationHelper.sendNotification(
            membershipNo: requestId,
            title: '$docTitle Rejected',
            body: 'Your $docTitle was rejected.\n\nREASON: $reason',
          );
        }
        
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
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(requestId)
          .update({'selectedCategory': category});
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating category: $e");
    }
  }

  // =========================================================================
  // 6. Duplicate වාහන හඳුනා ගැනීම (Check Duplicate)
  // =========================================================================
  Future<Map<String, dynamic>?> checkDuplicateVehicle(
    String field,
    String value,
  ) async {
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
  Future<void> rejectVehiclePhoto(
    String requestId,
    String label,
    String reason,
  ) async {
    try {
      DocumentReference docRef = FirebaseFirestore.instance
          .collection('vehicles')
          .doc(requestId);
      DocumentSnapshot doc = await docRef.get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, dynamic> photos = Map<String, dynamic>.from(
          data['vehiclePhotos'] ?? {},
        );

        if (photos.containsKey(label)) {
          photos[label]['status'] = 'rejected';
          photos[label]['rejectionReason'] = reason;
          await docRef.update({'vehiclePhotos': photos});
          
          // Sync to inactive reasons
          String fieldName = '';
          if (label == 'Front') fieldName = 'vehicle_image_front';
          else if (label == 'Back') fieldName = 'vehicle_image_back';
          else if (label == 'Left Side') fieldName = 'vehicle_image_left_side';
          else if (label == 'Right Side') fieldName = 'vehicle_image_right_side';
          else if (label == 'Interior') fieldName = 'vehicle_image_interior';
          
          if (fieldName.isNotEmpty) {
            await _syncToInactiveReasons(requestId, fieldName, 'rejected');
          }
          
          await NotificationHelper.sendNotification(
            membershipNo: requestId,
            title: 'Vehicle Photo Rejected',
            body: 'Your vehicle photo ($label) was rejected.\n\nREASON: $reason',
          );
          
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error rejecting photo: $e");
    }
  }

  // =========================================================================
  // SYNC WITH MEMBER INACTIVE REASONS
  // =========================================================================
  Future<void> _syncToInactiveReasons(String membershipNo, String fieldName, String status) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('member_inactive_reasons')
          .where('membershipNo', isEqualTo: membershipNo)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          fieldName: status,
        });
      }
    } catch (e) {
      print('Error syncing to inactive reasons: $e');
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

      debugPrint(
        "Found ${vehiclesSnap.docs.length} approved vehicles to migrate.",
      );

      final WriteBatch batch = firestore.batch();
      int count = 0;

      for (var vehicleDoc in vehiclesSnap.docs) {
        String membershipNo = vehicleDoc.id;
        Map<String, dynamic> vehicleData =
            vehicleDoc.data() as Map<String, dynamic>;

        // Find corresponding member
        String? memberDocId;
        QuerySnapshot memberQuery = await firestore
            .collection('member')
            .where('membershipNo', isEqualTo: membershipNo)
            .get();

        if (memberQuery.docs.isNotEmpty) {
          memberDocId = memberQuery.docs.first.id;
        } else {
          DocumentSnapshot docSnap = await firestore
              .collection('member')
              .doc(membershipNo)
              .get();
          if (docSnap.exists) {
            memberDocId = docSnap.id;
          }
        }

        if (memberDocId != null) {
          DocumentReference memberRef = firestore
              .collection('member')
              .doc(memberDocId);

          batch.update(memberRef, {
            'currentVehicle': {
              ...vehicleData,
              'migratedAt': FieldValue.serverTimestamp(),
            },
          });
          count++;
        }
      }

      if (count > 0) {
        await batch.commit();
        debugPrint(
          "Successfully migrated $count vehicles to member collection.",
        );
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
          Map<String, dynamic> photos = Map<String, dynamic>.from(
            data['vehiclePhotos'],
          );
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
  // 7.6 පරණ බාගෙට අප්ලෝඩ් කරපු Pending ටික අයින් කිරීම (Clear Pending List)
  // =========================================================================
  Future<void> archiveAllPendingRequests() async {
    _setProcessing(true);
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot pendingSnap = await firestore
          .collection('vehicles')
          .where('status', isEqualTo: 'pending')
          .get();

      if (pendingSnap.docs.isNotEmpty) {
        // Use batch to update all at once
        final WriteBatch batch = firestore.batch();
        for (var doc in pendingSnap.docs) {
          batch.update(doc.reference, {'status': 'archived'});
        }
        await batch.commit();
        debugPrint("Archived ${pendingSnap.docs.length} pending requests.");
      }
      _setProcessing(false);
    } catch (e) {
      debugPrint("Error archiving pending requests: $e");
      _setProcessing(false);
    }
  }

  // =========================================================================
  // 📡 8. DYNAMIC FIXED RATES UPDATER ENGINE
  // =========================================================================
  Future<bool> updateVehicleRates({
    required String categoryId, // 💡 උදා: 'budget', 'mini', '6_seater'
    required String vehicleDocId, // 💡 උදා: 'AIAPRTD-25-0001'
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
