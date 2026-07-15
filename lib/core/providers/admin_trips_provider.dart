import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminTripModel {
  final String id;
  final String type; // "booking" or "road_pickup"
  final DateTime date; // Used for sorting (usually booking time or start time)
  final double estimatedFare;
  final double finalFare;
  final double distanceKm;
  final int waitingTimeSec;
  final String startAddress;
  final String endAddress;

  // Driver Info
  final String driverName;
  final String driverMembershipNo;

  // Passenger Info
  final String passengerName;
  final String passengerId;
  final String passengerPhone;

  // Timestamps
  final DateTime? bookingTime;
  final DateTime? driverReachedTime;
  final DateTime? tripStartTime;
  final DateTime? tripEndTime;

  final String status; // "completed", "cancelled", etc.
  final String paymentMethod;
  final String docId;

  AdminTripModel({
    required this.id,
    required this.type,
    required this.date,
    required this.estimatedFare,
    required this.finalFare,
    required this.distanceKm,
    this.waitingTimeSec = 0,
    required this.startAddress,
    required this.endAddress,
    required this.driverName,
    required this.driverMembershipNo,
    this.passengerName = 'Unknown',
    this.passengerId = '',
    this.passengerPhone = 'Unknown',
    this.bookingTime,
    this.driverReachedTime,
    this.tripStartTime,
    this.tripEndTime,
    required this.status,
    required this.paymentMethod,
    required this.docId,
  });
}

class AdminTripsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<AdminTripModel> _trips = [];
  List<AdminTripModel> get trips => _trips;

  // Filtered lists
  List<AdminTripModel> get completedTrips =>
      _trips.where((t) => t.status == 'completed').toList();
  List<AdminTripModel> get cancelledTrips =>
      _trips.where((t) => t.status == 'cancelled').toList();
  List<AdminTripModel> get bookingTrips =>
      _trips.where((t) => t.type == 'booking').toList();
  List<AdminTripModel> get pickupTrips =>
      _trips.where((t) => t.type == 'road_pickup').toList();

  // Summary Metrics
  double get totalBookingsRevenue => bookingTrips
      .where((t) => t.status == 'completed')
      .fold(0, (total, trip) => total + trip.finalFare);
  double get totalPickupsRevenue => pickupTrips
      .where((t) => t.status == 'completed')
      .fold(0, (total, trip) => total + trip.finalFare);
  int get totalCompletedCount => completedTrips.length;
  int get totalCancelledCount => cancelledTrips.length;

  Future<void> fetchTripsForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    _isLoading = true;
    _trips = [];
    notifyListeners();

    try {
      List<AdminTripModel> fetchedTrips = [];
      QuerySnapshot memberSnap = await _firestore.collection('member').get();
      List<String> allMembershipNumbers = memberSnap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final String originalMemNo = data['membershipNo']?.toString() ?? '';
        return originalMemNo.isNotEmpty && originalMemNo != '-'
            ? originalMemNo
            : doc.id;
      }).toList();

      // Calculate start and end bounds
      DateTime startOfDay = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );
      DateTime endOfDay = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      ).add(const Duration(days: 1));

      // 1. Fetch Bookings for this date range
      QuerySnapshot bookingsSnap = await _firestore
          .collection('all_bookings')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      for (var doc in bookingsSnap.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        String status = data['status']?.toString().toLowerCase() ?? '';
        String tripState = data['tripState']?.toString().toLowerCase() ?? '';
        String paymentStatus =
            data['paymentStatus']?.toString().toLowerCase() ?? '';

        String finalStatus = 'ongoing';
        if (status == 'completed' ||
            tripState == 'completed' ||
            paymentStatus == 'collected') {
          finalStatus = 'completed';
        } else if (status == 'cancelled' ||
            tripState == 'cancelled' ||
            status == 'rejected') {
          finalStatus = 'cancelled';
        }

        DateTime tripDate;
        if (data['pickupTime'] != null) {
          tripDate =
              DateTime.tryParse(data['pickupTime'].toString()) ?? startOfDay;
        } else if (data['timestamp'] != null &&
            data['timestamp'] is Timestamp) {
          tripDate = (data['timestamp'] as Timestamp).toDate();
        } else {
          tripDate = startOfDay;
        }

        DateTime? bookingTime;
        DateTime? driverReachedTime;
        DateTime? tripStartTime;
        DateTime? tripEndTime;

        if (data['createdAt'] != null && data['createdAt'] is Timestamp)
          bookingTime = (data['createdAt'] as Timestamp).toDate();
        if (bookingTime == null &&
            data['timestamp'] != null &&
            data['timestamp'] is Timestamp)
          bookingTime = (data['timestamp'] as Timestamp).toDate();
        if (data['arrivedAt'] != null && data['arrivedAt'] is Timestamp)
          driverReachedTime = (data['arrivedAt'] as Timestamp).toDate();
        if (data['startedAt'] != null && data['startedAt'] is Timestamp)
          tripStartTime = (data['startedAt'] as Timestamp).toDate();
        if (data['completedAt'] != null && data['completedAt'] is Timestamp)
          tripEndTime = (data['completedAt'] as Timestamp).toDate();

        double estimatedFare =
            double.tryParse(data['estimateFare']?.toString() ?? '0') ?? 0;
        double finalFare =
            double.tryParse(data['totalFare']?.toString() ?? '0') ?? 0;
        if (finalFare == 0)
          finalFare =
              double.tryParse(data['bidAmount']?.toString() ?? '0') ?? 0;

        String pickupLoc = 'Unknown Pickup';
        if (data['pickupLocation'] is Map) {
          pickupLoc =
              data['pickupLocation']['address']?.toString() ?? 'Unknown Pickup';
        } else if (data['pickupLocation'] != null) {
          pickupLoc = data['pickupLocation'].toString();
        }

        String dropLoc = 'Unknown Drop';
        if (data['dropLocation'] is Map) {
          dropLoc =
              data['dropLocation']['address']?.toString() ?? 'Unknown Drop';
        } else if (data['dropLocation'] != null) {
          dropLoc = data['dropLocation'].toString();
        }

        fetchedTrips.add(
          AdminTripModel(
            id: doc.id,
            type: 'booking',
            date: tripDate,
            estimatedFare: estimatedFare,
            finalFare: finalFare,
            distanceKm:
                double.tryParse(
                  data['distance']?.toString() ??
                      data['distanceKm']?.toString() ??
                      '0',
                ) ??
                0,
            waitingTimeSec:
                int.tryParse(
                  data['waitingTimeSec']?.toString() ??
                      data['waitingTime']?.toString() ??
                      '0',
                ) ??
                0,
            startAddress: pickupLoc,
            endAddress: dropLoc,
            driverName: data['driverName']?.toString() ?? 'Unknown',
            driverMembershipNo: data['acceptedBy']?.toString() ?? '-',
            passengerName: data['memberName']?.toString() ?? 'Unknown',
            passengerId: data['memberId']?.toString() ?? '',
            passengerPhone:
                data['memberPhone']?.toString() ??
                data['passengerPhone']?.toString() ??
                'Unknown',
            bookingTime: bookingTime,
            driverReachedTime: driverReachedTime,
            tripStartTime: tripStartTime,
            tripEndTime: tripEndTime,
            status: finalStatus,
            paymentMethod: data['paymentMethod']?.toString() ?? 'Cash',
            docId: doc.id,
          ),
        );
      }

      // 2. Fetch Road Pickups for all drivers for this date range
      List<String> dateStrings = [];
      for (int i = 0; i < endOfDay.difference(startOfDay).inDays; i++) {
        final d = startOfDay.add(Duration(days: i));
        dateStrings.add(
          "${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}",
        );
      }

      // We will batch the reads to avoid freezing the UI
      List<Future<void>> pickupFutures = [];
      for (String dateStr in dateStrings) {
        for (String membershipNo in allMembershipNumbers) {
          if (membershipNo.isEmpty || membershipNo == '-') continue;

          pickupFutures.add(
            _firestore
                .collection('roadpickups_hires')
                .doc(dateStr)
                .collection(membershipNo)
                .get()
                .then((snap) {
                  for (var doc in snap.docs) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    if (data.containsKey('tripId')) {
                      DateTime tripDate;
                      if (data['pickupTime'] != null) {
                        tripDate =
                            DateTime.tryParse(data['pickupTime'].toString()) ??
                            startOfDay;
                      } else {
                        tripDate = startOfDay;
                      }

                      String status =
                          'completed'; // Road pickups are generally recorded only when complete
                      if (data['paymentStatus']?.toString().toLowerCase() ==
                          'pending') {
                        status = 'ongoing';
                      }

                      double finalFare =
                          double.tryParse(
                            data['totalFare']?.toString() ?? '0',
                          ) ??
                          0;

                      fetchedTrips.add(
                        AdminTripModel(
                          id: data['tripId'] ?? doc.id,
                          type: 'road_pickup',
                          date: tripDate,
                          estimatedFare:
                              finalFare, // Road pickups don't have an estimate
                          finalFare: finalFare,
                          distanceKm:
                              double.tryParse(
                                data['distanceKm']?.toString() ?? '0',
                              ) ??
                              0,
                          waitingTimeSec:
                              int.tryParse(
                                data['waitingTimeSec']?.toString() ?? '0',
                              ) ??
                              0,
                          startAddress: data['startAddress'] ?? 'Street Pickup',
                          endAddress: data['endAddress'] ?? 'Street Drop',
                          driverName:
                              'Driver $membershipNo', // Meter provider often doesn't save name, so we use ID
                          driverMembershipNo: membershipNo,
                          passengerName: 'Street Passenger',
                          passengerId: '',
                          passengerPhone: '-',
                          bookingTime: null,
                          driverReachedTime: null,
                          tripStartTime: tripDate,
                          tripEndTime: status == 'completed'
                              ? tripDate.add(
                                  Duration(minutes: (finalFare / 100).round()),
                                )
                              : null,
                          status: status,
                          paymentMethod: 'Cash',
                          docId: doc.id,
                        ),
                      );
                    }
                  }
                })
                .catchError((e) {
                  // Ignore errors
                }),
          );
        }
      }

      // Wait for all road pickup queries to finish
      await Future.wait(pickupFutures);

      // 3. Sort by Date (Newest first)
      fetchedTrips.sort((a, b) => b.date.compareTo(a.date));

      _trips = fetchedTrips;
    } catch (e) {
      debugPrint("Error fetching trips: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTripsForDate(DateTime targetDate) async {
    return fetchTripsForDateRange(targetDate, targetDate);
  }

  Future<bool> deleteTrip(AdminTripModel trip) async {
    try {
      if (trip.type == 'booking') {
        await _firestore.collection('all_bookings').doc(trip.docId).delete();

        // Also delete from booking_hires (archive) if it exists
        final dateStr =
            "${trip.date.year}.${trip.date.month.toString().padLeft(2, '0')}.${trip.date.day.toString().padLeft(2, '0')}";
        if (trip.driverMembershipNo != '-' &&
            trip.driverMembershipNo.isNotEmpty) {
          await _firestore
              .collection('booking_hires')
              .doc(dateStr)
              .collection(trip.driverMembershipNo)
              .doc(trip.docId)
              .delete()
              .catchError((e) => debugPrint("Not in booking_hires, ignoring"));
        }
      } else if (trip.type == 'road_pickup') {
        final dateStr =
            "${trip.date.year}.${trip.date.month.toString().padLeft(2, '0')}.${trip.date.day.toString().padLeft(2, '0')}";
        await _firestore
            .collection('roadpickups_hires')
            .doc(dateStr)
            .collection(trip.driverMembershipNo)
            .doc(trip.docId)
            .delete();
      }

      // Remove from local list to update UI immediately
      _trips.removeWhere((t) => t.id == trip.id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error deleting trip: $e");
      return false;
    }
  }
}
