import 'dart:async';
import 'dart:convert';

import 'package:autism_care_management_application/data/services/fcm_service.dart';
import 'package:autism_care_management_application/screen/caretaker/model/ActivityItem.dart';
import 'package:autism_care_management_application/screen/caretaker/model/NutritionItem.dart';
import 'package:autism_care_management_application/screen/caretaker/model/media_model.dart';
import 'package:autism_care_management_application/screen/parents/model/apply_model.dart';
import 'package:autism_care_management_application/screen/parents/model/caretaker_model.dart';
import 'package:autism_care_management_application/screen/parents/model/children_model.dart';
import 'package:autism_care_management_application/screen/parents/model/parents_model.dart';
import 'package:autism_care_management_application/screen/parents/model/review_model..dart';
import 'package:autism_care_management_application/screen/parents/model/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FcmService fcmService = FcmService();

  // Get current user
  String get currentUser => _auth.currentUser!.uid;

  // ======================== HELPER ===============================
  Future<String> _getCaretakerIdOnly() async {
    final currentUser = _auth.currentUser;

    // Verify user and email
    if (currentUser == null || currentUser.email == null) {
      debugPrint('No authenticated user');
      throw Exception('No authenticated user');
    }

    // Get parent document
    QuerySnapshot parentSnapshot = await FirebaseFirestore.instance
        .collection('parents')
        .where('authId', isEqualTo: currentUser.uid)
        .limit(1)
        .get();

    if (parentSnapshot.docs.isEmpty) {
      debugPrint('No parent found for current user');
      throw Exception('No parent found for current user');
    }

    // Get parent's ID
    final parentId = parentSnapshot.docs.first.id;

    // Get child document
    QuerySnapshot childSnapshot = await FirebaseFirestore.instance
        .collection('parents')
        .doc(parentId)
        .collection('child')
        .where('parentId', isEqualTo: parentId)
        .limit(1)
        .get();

    if (childSnapshot.docs.isEmpty) {
      debugPrint('No child found for current parent');
      throw Exception('No child found for current parent');
    }

    // Get child document data and return caretakerId
    final childData = childSnapshot.docs.first.data() as Map<String, dynamic>;
    final caretakerId = childData['caretakerId'] as String;

    if (caretakerId.isEmpty) {
      debugPrint('No caretaker assigned to this child');
      throw Exception('No caretaker assigned to this child');
    }

    debugPrint(caretakerId);

    return caretakerId;
  }

  Future<String> getParentIdOnly() async {
    final currentUser = _auth.currentUser;

    // Verify user and email
    if (currentUser == null || currentUser.email == null) {
      debugPrint('No authenticated user');
      throw Exception('No authenticated user');
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('parents')
        .where('authId', isEqualTo: currentUser.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      debugPrint('No caretaker found for current user');
      throw Exception('No caretaker found for current user');
    }

    final parentId = snapshot.docs.first.id;
    return parentId;
  }

  // ======================== ID GENERATION ========================
  Future<String> _getNextId(String collectionPath, String prefix) async {
    try {
      final counterRef = _firestore.collection('counters').doc(collectionPath);

      // First try to get the current count without transaction
      final currentDoc = await counterRef.get();
      int currentCount = 1;

      if (currentDoc.exists) {
        currentCount = (currentDoc.data()?['count'] ?? 0) + 1;
      }

      // Then attempt to update with transaction
      try {
        await _firestore.runTransaction((transaction) async {
          final doc = await transaction.get(counterRef);
          if (doc.exists) {
            currentCount = (doc.data()?['count'] ?? 0) + 1;
          }
          transaction.set(counterRef, {'count': currentCount});
        });
      } catch (e) {
        // If transaction fails, use the count we got before
        debugPrint('Transaction failed, using fallback count: $e');
      }

      return '$prefix${currentCount.toString().padLeft(3, '0')}';
    } catch (e) {
      debugPrint('Error in _getNextId: $e');
      debugPrint('Failed to generate ID. Please try again.');
      return ''; // Return an empty string or handle error as needed
    }
  }

  // ======================== GET CURRENT USER =====================
  Stream<Users>? getCurrentUser(BuildContext context) {
    try {
      User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        debugPrint('User not authenticated');
        return Stream.error('User not authenticated');
      }
      return _firestore
          .collection('users')
          .doc(currentUser)
          .snapshots()
          .map((snapshot) => Users.fromFirestore(snapshot));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting current user: ${e.toString()}')),
      );
      return null;
    }
  }

  Future<Users?> getCurrentUserF(BuildContext context) async {
    try {
      User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User not authenticated')));
        return null;
      }

      DocumentSnapshot snapshot =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!snapshot.exists) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User document not found')));
        return null;
      }

      return Users.fromFirestore(snapshot);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting current user: ${e.toString()}')),
      );
      return null;
    }
  }

  // ======================== PARENT CRUD ========================

  //UPDATE OR REGISTER
  Future<String?> registerParents({
    required String name,
    String? occupation,
    String? phone,
    String? employerAddress,
    double? monthlyIncome,
    String? maritalStatus,
  }) async {
    try {
      final parentId = await _getNextId('parents', 'P');
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        debugPrint('No authenticated user');
        return null;
      }

      final parent = Parent(
        id: parentId,
        authId: currentUser.uid,
        name: name,
        email: currentUser.email!,
        occupation: occupation,
        phone: phone,
        employerAddress: employerAddress,
        monthlyIncome: monthlyIncome,
        maritalStatus: maritalStatus,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('parents').doc(parentId).set(parent.toJson());
      return parent.authId;
    } catch (e) {
      debugPrint('Failed to register parent: ${e.toString()}');
      return null;
    }
  }

  //READ
  Future<Parent?> getParent() async {
    try {
      final currentUser = _auth.currentUser;

      // Verify user is authenticated
      if (currentUser == null) {
        debugPrint('No authenticated user');
        return null;
      }

      // Get parent document matching the auth UID
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('parents')
          .where('authId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null; // No parent found (or handle differently)
      }

      // Convert document to Parent model
      return Parent.fromMap(
        snapshot.docs.first.id,
        snapshot.docs.first.data() as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('Failed to get parent: ${e.toString()}');
      return null;
    }
  }

  //UPDATE
  Future<void> updateParent(Parent parent) async {
    try {
      await _firestore
          .collection('parents')
          .doc(parent.id)
          .update(parent.toMap());
    } catch (e) {
      debugPrint('Failed to update parent: ${e.toString()}');
    }
  }

  Future<void> deleteParent(String parentId) async {
    try {
      await _firestore.collection('parents').doc(parentId).delete();
    } catch (e) {
      debugPrint('Failed to delete parent: ${e.toString()}');
    }
  }

  // ======================== CARETAKER CRUD ========================
  //READ
  Future<Caretaker?> getCaretaker(String caretakerId) async {
    try {
      final doc =
          await _firestore.collection('caretaker').doc(caretakerId).get();
      return doc.exists ? Caretaker.fromMap(doc.id, doc.data()!) : null;
    } catch (e) {
      debugPrint('Failed to get caretaker: ${e.toString()}');
      return null;
    }
  }

  //DELETE
  Future<void> deleteCaretaker(String caretakerId) async {
    try {
      await _firestore.collection('caretaker').doc(caretakerId).delete();
    } catch (e) {
      debugPrint('Failed to delete caretaker: ${e.toString()}');
    }
  }

  //Get Images and Video
  //DISPLAY MEDIA
  Future<List<MediaItem>> getMediaItems(String caretakerId) async {
    try {
      debugPrint('Fetching all public media...');

      final snapshot = await _firestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('caretaker_media')
          .orderBy('createdAt', descending: true)
          .get();

      debugPrint('Found ${snapshot.docs.length} items');

      return snapshot.docs.map((doc) => MediaItem.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Fetch error: ${e.toString()}');
      throw Exception('Failed to get media: ${e.toString()}');
    }
  }

  // Get reviews for caretaker including user's existing review
  Future<List<Review>> getReviewsForCaretaker(
      String caretakerId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('reviews')
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return Review.fromMap(doc.data());
      }).toList();
    } catch (e) {
      print('Error fetching reviews: $e');
      return [];
    }
  }

  // Get user's existing review for this caretaker
  Future<Review?> getUserReview(String caretakerId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('reviews')
          .where('reviewerId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return Review.fromMap(querySnapshot.docs.first.data());
    } catch (e) {
      print('Error fetching user review: $e');
      return null;
    }
  }

  // Add or update review
  Future<bool> addOrUpdateReview({
    required String caretakerId,
    required String reviewerId,
    required String reviewerName,
    required int rating,
    required String comment,
  }) async {
    try {
      // Check if user already has a review
      final existingReview = await getUserReview(caretakerId, reviewerId);
      final reviewId =
          existingReview?.reviewId ?? await _getNextId('review', 'RW');

      final review = Review(
        reviewId: reviewId,
        caretakerId: caretakerId,
        reviewerId: reviewerId,
        reviewerName: reviewerName,
        date: DateTime.now().toIso8601String(),
        rating: rating,
        comment: comment,
      );

      await _firestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('reviews')
          .doc(reviewId)
          .set(review.toMap());

      return true;
    } catch (e) {
      print('Error adding/updating review: $e');
      return false;
    }
  }

  // Delete review
  Future<bool> deleteReview(
      String caretakerId, String reviewId, String userId) async {
    try {
      // Verify the review belongs to the user
      final doc = await _firestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('reviews')
          .doc(reviewId)
          .get();

      if (!doc.exists || doc.data()?['reviewerId'] != userId) {
        return false;
      }

      await _firestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('reviews')
          .doc(reviewId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }

  // ======================== CHILD CRUD ========================
  //CREATE
  Future<String?> registerChild({
    required String name,
    required String myKid,
    required String age,
    required String address,
    required DateTime birthDate,
    required String race,
    required String religion,
    required String citizenship,
    required String custodyStatus,
    String? otherCustody,
    required bool hasAttendedCenter,
    required String autismType,
    Child? childModel,
  }) async {
    try {
      final childId = await _getNextId('child', 'CD');
      final currentUser = _auth.currentUser;

      // Verify user and email
      if (currentUser == null || currentUser.email == null) {
        debugPrint('No authenticated user');
        return null;
      }

      // Get parent's document by matching authentication id
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('parents')
          .where('authId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      // Check if parent exists
      if (snapshot.docs.isEmpty) {
        debugPrint('No parent found with authentication id ${currentUser.uid}');
      }

      // Get parent's ID from the snapshot
      final parentId = snapshot.docs.first.id;

      //Child object with parentId to pass
      final child = Child(
        id: childId,
        parentId: parentId,
        caretakerId: '',
        autismCentreName: null,
        name: name,
        myKid: myKid,
        age: num.parse(age),
        address: address,
        birthDate: birthDate,
        race: race,
        religion: religion,
        citizenship: citizenship,
        custodyStatus: custodyStatus,
        otherCustody: otherCustody,
        hasAttendedCenter: hasAttendedCenter,
        autismType: autismType,
        createdAt: DateTime.now(),
      );

      // use child Model if have, otherwise use childTosave
      final childToSave =
          childModel?.copyWith(id: childId, parentId: parentId) ?? child;

      // Save to Firestore under the parent's children subcollection
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('child')
          .doc(childId)
          .set(childToSave.toJson());

      return childId;
    } catch (e) {
      debugPrint('Failed to create child: ${e.toString()}');
      return null;
    }
  }

  //READ
  Future<List<Child>> getChildrenByParent() async {
    try {
      final currentUser = _auth.currentUser;

      // Verify user and email
      if (currentUser == null || currentUser.email == null) {
        debugPrint('No authenticated user');
        return [];
      }

      // Get parent's document by matching authentication id
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('parents')
          .where('authId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      // Check if parent exists
      if (snapshot.docs.isEmpty) {
        debugPrint('No parent found with authentication id ${currentUser.uid}');
        return [];
      }

      // Get parent's ID from the snapshot
      final parentId = snapshot.docs.first.id;

      final query = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('child')
          .get();
      return query.docs
          .map((doc) => Child.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('No child in list, please register');
      debugPrint('Failed to get children: ${e.toString()}');
      return [];
    }
  }

  //UPDATE
  Future<void> updateChild(Child child) async {
    try {
      await _firestore
          .collection('parents')
          .doc(child.parentId)
          .collection('child')
          .doc(child.id)
          .update(child.toMap());
    } catch (e) {
      debugPrint('Failed to update child: ${e.toString()}');
    }
  }

  Future<void> deleteChild(String childId) async {
    try {
      final currentUser = _auth.currentUser;

      // Verify user and email
      if (currentUser == null || currentUser.email == null) {
        debugPrint('No authenticated user');
        return null;
      }

      // Get parent's document by matching authentication id
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('parents')
          .where('authId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      // Check if parent exists
      if (snapshot.docs.isEmpty) {
        debugPrint('No parent found with authentication id ${currentUser.uid}');
      }

      // Get parent's ID from the snapshot
      final parentId = snapshot.docs.first.id;

      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('child')
          .doc(childId)
          .delete();
    } catch (e) {
      debugPrint('Failed to delete child: ${e.toString()}');
    }
  }

  // ======================== APPLY CRUD ======================================

  Future<void> applyCaretaker(
    String caretakerId,
    Child child,
    Parent parent,
  ) async {
    try {
      // Generate new Id for application
      final applyId = await _getNextId('apply', 'A');

      final currentUser = _auth.currentUser;

      // Verify user and email
      if (currentUser == null || currentUser.email == null) {
        debugPrint('No authenticated user');
        return null;
      }

      // Get caretaker's document by matching caretaker name
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('caretaker')
          .where('id', isEqualTo: caretakerId)
          .limit(1)
          .get();

      // Check if caretakerId exists
      if (snapshot.docs.isEmpty) {
        debugPrint('No autism centre found from ${currentUser.uid.toString()}');
      }

      // Get caretakerId's ID from the snapshot
      final newCaretakerId = snapshot.docs.first.id;

      final apply = Apply(
        applyId: applyId,
        applyStatus: 'pending',
        childInfo: child,
        parentInfo: parent,
        requestDate: Timestamp.now(),
      );

      debugPrint(
        jsonEncode({
          'applyId': apply.applyId,
          'applyStatus': apply.applyStatus,
          'childInfo': apply.childInfo.toMap(), // assuming Child has toMap()
          'parentInfo': apply.parentInfo.toMap(), // assuming Parent has toMap()
        }),
      );

      await _firestore
          .collection('caretaker')
          .doc(newCaretakerId)
          .collection('apply')
          .doc(applyId)
          .set(apply.toJson());
    } catch (e) {
      debugPrint('Failed to apply child: ${e.toString()}');
    }
  }

// ======================== ATTENDANCE CRUD ========================

  // Get current work hours
  Future<Map<String, String>> getWorkHours() async {
    try {
      final caretakerId = await _getCaretakerIdOnly();

      final doc =
          await _firestore.collection('caretaker').doc(caretakerId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return Map<String, String>.from(data['workHours'] ?? {});
      }
      return {};
    } catch (e) {
      print('Error getting work hours: $e');
      return {};
    }
  }

  // Get default work hours structure
  Map<String, String> getDefaultWorkHours() {
    return {
      'monday': '8:30 AM - 5:00 PM',
      'tuesday': '8:30 AM - 5:00 PM',
      'wednesday': '8:30 AM - 5:00 PM',
      'thursday': '8:30 AM - 5:00 PM',
      'friday': '8:30 AM - 5:00 PM',
      'saturday': 'Closed',
      'sunday': 'Closed',
    };
  }

  Future<Map<String, dynamic>> getAttendanceLocation(String caretakerId) async {
    final snapshot = await _firestore
        .collection('caretaker')
        .where('id', isEqualTo: caretakerId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('Caretaker profile not found');
    }

    final caretakerData = snapshot.docs.first.data();
    return caretakerData;
  }

  Future<void> recordAttendance(TimeOfDay? timeClockIn, TimeOfDay? timeClockOut,
      bool isClockedIn, String caretakerId) async {
    try {
      // Check if already clocked in/out today
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final existingRecords = await _firestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThan: endOfDay)
          .get();

      if (isClockedIn) {
        // Check if already clocked in today
        if (existingRecords.docs.any((doc) => doc['isClockedIn'] == true)) {
          throw Exception('You have already clocked in today');
        }
      } else {
        // Check if already clocked out today
        if (existingRecords.docs.any((doc) => doc['isClockedIn'] == false)) {
          throw Exception('You have already clocked out today');
        }
        // Check if clocked in first
        if (!existingRecords.docs.any((doc) => doc['isClockedIn'] == true)) {
          throw Exception('You must clock in before clocking out');
        }
      }

      final location = await getCurrentLocationForAttendance();
      final attendanceId = await _getNextId('attendance', 'AT');

      // Prepare the data map
      Map<String, dynamic> attendanceData = {
        'id': attendanceId,
        'caretakerId': caretakerId,
        'date': FieldValue.serverTimestamp(),
        'isClockedIn': isClockedIn,
        'location': GeoPoint(location.latitude, location.longitude),
        'status': 'completed',
      };

      // Add timeClockIn only if it's not null
      if (timeClockIn != null) {
        attendanceData['timeClockIn'] = {
          'hour': timeClockIn.hour,
          'minute': timeClockIn.minute,
        };
      }

      // Add timeClockOut only if it's not null
      if (timeClockOut != null) {
        attendanceData['timeClockOut'] = {
          'hour': timeClockOut.hour,
          'minute': timeClockOut.minute,
        };
      }

      await _firestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('attendance')
          .doc(attendanceId)
          .set(attendanceData);
    } catch (e) {
      throw Exception('Failed to record attendance: $e');
    }
  }

  Future<Position> getCurrentLocationForAttendance() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  double calculateDistanceForAttendance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  bool isWithinRadius(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
    double radiusInMeters,
  ) {
    final distance = calculateDistanceForAttendance(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
    return distance <= radiusInMeters;
  }

// New method to get attendance history from Firestore
  Future<List<Map<String, dynamic>>> getAttendanceHistory() async {
    try {
      final caretakerId = await _getCaretakerIdOnly();

      final snapshot = await _firestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('attendance')
          .orderBy('timestamp', descending: true)
          .limit(50) // Limit to last 50 records
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': data['id'],
          'timestamp': data['timestamp'],
          'isClockedIn': data['isClockedIn'],
          'location': data['location'],
          'status': data['status'],
        };
      }).toList();
    } catch (e) {
      print('Error getting attendance history: $e');
      return [];
    }
  }

  // ======================== ACTIVITY TIMETABLE CRUD ========================

  // Get collection reference with user-specific data
  Future<CollectionReference> _getActivityCollection(String caretakerId) async {
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('caretaker')
        .doc(caretakerId)
        .collection('activitytimetable');
  }

  // Get activities for a specific date
  Future<List<ActivityItem>> getActivities(
      DateTime date, String caretakerId) async {
    try {
      // Format date to compare (without time)
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final activityCollection = await _getActivityCollection(caretakerId);

      final snapshot = await activityCollection
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      // Convert documents to ActivityItem objects
      final activities =
          snapshot.docs.map((doc) => ActivityItem.fromFirestore(doc)).toList();

      // Sort by start time
      activities.sort((a, b) {
        // Convert TimeOfDay to minutes for easier comparison
        final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
        final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
        return aMinutes.compareTo(bMinutes);
      });

      return activities;
    } catch (e) {
      print('Error getting activities: $e');
      rethrow;
    }
  }

  // ======================== NUTRITION TIMETABLE CRUD ========================
  // Get collection reference with user-specific data
  Future<CollectionReference> _getNutritionCollection(
      String caretakerId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    return _firestore
        .collection('caretaker')
        .doc(caretakerId)
        .collection('nutritiontimetable');
  }

  // Get nutrition items for a specific date
  Future<List<NutritionItem>> getNutritionItems(
      DateTime date, String caretakerId) async {
    try {
      // Format date to compare (without time)
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final nutritionCollection = await _getNutritionCollection(caretakerId);

      final snapshot = await nutritionCollection
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      // Convert documents to NutritionItem objects
      final nutritionItems =
          snapshot.docs.map((doc) => NutritionItem.fromFirestore(doc)).toList();

      // Sort by start time
      nutritionItems.sort((a, b) {
        // Convert TimeOfDay to minutes for easier comparison
        final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
        final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
        return aMinutes.compareTo(bMinutes);
      });

      return nutritionItems;
    } catch (e) {
      print('Error getting nutrition items: $e');
      rethrow;
    }
  }

  // ======================== PAYMENT CRUD ========================
  // Get unpaid payments (pending and overdue)
  Future<List<Map<String, dynamic>>> getUnpaidPayments() async {
    try {
      final parentId = await getParentIdOnly();

      QuerySnapshot querySnapshot = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('payments')
          .where('parentId', isEqualTo: parentId)
          .where('status', whereIn: ['Pending', 'Overdue'])
          .orderBy('dueDate', descending: false) // Show earliest due first
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'caretakerName': data['caretakerName'],
          'childName': data['childName'],
          'amount': data['amount'],
          'status': data['status'],
          'dueDate': data['dueDate'],
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      print('Error getting unpaid payments: $e');
      return [];
    }
  }

  // Get total deferred payment amount (sum of all pending payments)
  Future<double> getTotalDeferredPayment() async {
    try {
      final parentId = await getParentIdOnly();

      QuerySnapshot querySnapshot = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('payments')
          .where('parentId', isEqualTo: parentId)
          .where('status', isEqualTo: 'Pending')
          .get();

      double total = 0;
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['amount'] as num).toDouble();
      }
      return total;
    } catch (e) {
      print('Error getting deferred payment total: $e');
      return 0;
    }
  }

  // Process payment for all deferred payments
  Future<bool> doPayment() async {
    try {
      final parentId = await getParentIdOnly();
      final caretakerId = await _getCaretakerIdOnly();

      // Get all pending payments from parent's collection
      QuerySnapshot parentPaymentsSnapshot = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('payments')
          .where('parentId', isEqualTo: parentId)
          .where('status', whereIn: ['Pending', 'Overdue']).get();

      if (parentPaymentsSnapshot.docs.isEmpty) {
        throw Exception('No pending payments found');
      }

      // Prepare a list of payment IDs to update in caretaker's collection
      final paymentIds =
          parentPaymentsSnapshot.docs.map((doc) => doc.id).toList();

      // Get corresponding payments from caretaker's collection
      QuerySnapshot caretakerPaymentsSnapshot = await _firestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('payments')
          .where('id', whereIn: paymentIds)
          .get();

      // This is way Toyyibpay will intercept.
      // Batch update both collections
      WriteBatch batch = _firestore.batch();
      final now = DateTime.now();

      // Update parent's payments
      for (var doc in parentPaymentsSnapshot.docs) {
        batch.update(doc.reference, {
          'status': 'Paid',
          'updatedAt': now,
        });
      }

      // Update caretaker's payments
      for (var doc in caretakerPaymentsSnapshot.docs) {
        batch.update(doc.reference, {
          'status': 'Paid',
          'updatedAt': now,
        });
      }

      await batch.commit();

      // Verify updates
      print(
          'Successfully updated ${parentPaymentsSnapshot.size} parent payments');
      print(
          'Successfully updated ${caretakerPaymentsSnapshot.size} caretaker payments');
      return true;
    } catch (e) {
      print('Error processing payment: $e');
      return false;
    }
  }

  // Get payment history (successful and failed payments)
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    try {
      final parentId = await getParentIdOnly();

      QuerySnapshot querySnapshot = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('payments')
          .where('parentId', isEqualTo: parentId)
          .where('status', whereIn: ['Paid', 'Failed'])
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'amount': data['amount'],
          'status': data['status'],
          'caretakerName': data['caretakerName'],
          'childName': data['childName'],
          'updatedAt': data['updatedAt'],
          'paymentMethod': data['paymentMethod'] ?? 'Unknown',
        };
      }).toList();
    } catch (e) {
      print('Error getting payment history: $e');
      return [];
    }
  }

// ======================= NOTIFICATION AND INBOX ===============================

  StreamSubscription? _notificationsSubscription;

  Future<void> insertMessage(String title, String message) async {
    try {
      final parentId = await getParentIdOnly();

      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('notifications')
          .add({
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  Future<void> insertMessageP(
      String title, String message, String parentId) async {
    try {
      await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('notifications')
          .add({
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getUnreadMessages() async {
    final parentId = await getParentIdOnly();
    final querySnapshot = await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> readMessage(String messageId) async {
    try {
      final parentId = await getParentIdOnly();

      _firestore
          .collection('parents')
          .doc(parentId)
          .collection('notifications')
          .doc(messageId)
          .update({'read': true});
    } catch (e) {
      throw Exception('Failed to read message: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> getMessageInbox() async {
    try {
      final parentId = await getParentIdOnly();

      final querySnapshot = await _firestore
          .collection('parents')
          .doc(parentId)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'title': doc['title'],
          'message': doc['message'],
          'timestamp': doc['timestamp'],
          'read': doc['read'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch messages: ${e.toString()}');
    }
  }

  Stream<List<Map<String, dynamic>>> getMessageInboxStream() async* {
    final parentId = await getParentIdOnly();

    yield* _firestore
        .collection('parents')
        .doc(parentId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'title': doc['title'],
          'message': doc['message'],
          'timestamp': doc['timestamp'],
          'read': doc['read'],
        };
      }).toList();
    });
  }

  // Start listening for new notifications
  Future<void> startListeningForNewNotifications() async {
    final caretakerId = await _getCaretakerIdOnly();

    _notificationsSubscription = _firestore
        .collection('parents')
        .doc(caretakerId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docChanges.isNotEmpty) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added && !change.doc['read']) {
            await fcmService.sendFCMMessage(
              change.doc['title'].toString(),
              change.doc['message'].toString(),
            );
          }
        }
      }
    });
  }

  // Cancel the listener when no longer needed
  void dispose() {
    _notificationsSubscription?.cancel();
  }
}
