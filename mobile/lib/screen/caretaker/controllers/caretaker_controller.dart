import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:autism_care_management_application/data/services/fcm_service.dart';
import 'package:autism_care_management_application/screen/caretaker/model/ActivityItem.dart';
import 'package:autism_care_management_application/screen/caretaker/model/ActivityPost.dart';
import 'package:autism_care_management_application/screen/caretaker/model/Approval.dart';
import 'package:autism_care_management_application/screen/caretaker/model/Attendance.dart';
import 'package:autism_care_management_application/screen/caretaker/model/NutritionItem.dart';
import 'package:autism_care_management_application/screen/caretaker/model/Payment.dart';
import 'package:autism_care_management_application/screen/caretaker/model/Staff.dart';
import 'package:autism_care_management_application/screen/caretaker/model/caretaker_model.dart';
import 'package:autism_care_management_application/screen/caretaker/model/children_model.dart';
import 'package:autism_care_management_application/screen/caretaker/model/media_model.dart';
import 'package:autism_care_management_application/screen/caretaker/model/parents_model.dart';
import 'package:autism_care_management_application/screen/caretaker/model/review_model..dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

class CaretakerController {
  final auth = FirebaseAuth.instance;
  final caretakerfirestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final FcmService fcmService = FcmService();
  final _dateFormat = DateFormat('yyyy-MM-dd');
  DateTime _selectedDate = DateTime.now();

  // ======================== HELPER ===============================
  Future<String> _getCaretakerIdOnly() async {
    final currentUser = auth.currentUser;

    // Verify user and email
    if (currentUser == null || currentUser.email == null) {
      debugPrint('No authenticated user');
      throw Exception('No authenticated user');
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('caretaker')
        .where('authId', isEqualTo: currentUser.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      debugPrint('No caretaker found for current user');
      throw Exception('No caretaker found for current user');
    }

    final caretakerId = snapshot.docs.first.id;
    return caretakerId;
  }

  Future<String> _getParentIdFromCaretaker() async {
    final caretakerId = await _getCaretakerIdOnly();

    QuerySnapshot parentSnapshot = await FirebaseFirestore.instance
        .collection('caretaker')
        .doc(caretakerId)
        .collection('parent')
        .where('caretakerId', isEqualTo: caretakerId)
        .limit(1)
        .get();

    if (parentSnapshot.docs.isEmpty) {
      debugPrint('No parents found for current user');
      throw Exception('No parents found for current user');
    }

    final parentId = parentSnapshot.docs.first.id;

    return parentId;
  }

  Future<String> _getCaretakerName() async {
    final caretakerId = await _getCaretakerIdOnly();

    final doc =
        await caretakerfirestore.collection('caretaker').doc(caretakerId).get();
    return doc['name'] ?? 'Unknown Centre';
  }

  // ======================== ID GENERATION ========================
  Future<String> _getNextId(String collectionPath, String prefix) async {
    try {
      final counterRef =
          caretakerfirestore.collection('counters').doc(collectionPath);

      // First try to get the current count without transaction
      final currentDoc = await counterRef.get();
      int currentCount = 1;

      if (currentDoc.exists) {
        currentCount = (currentDoc.data()?['count'] ?? 0) + 1;
      }

      // Then attempt to update with transaction
      try {
        await caretakerfirestore.runTransaction((transaction) async {
          final doc = await transaction.get(counterRef);
          if (doc.exists) {
            currentCount = (doc.data()?['count'] ?? 0) + 1;
          }
          transaction.set(counterRef, {'count': currentCount});
        });
      } catch (e) {
        // If transaction fails, use the count we got before
        print('Transaction failed, using fallback count: $e');
      }

      return '$prefix${currentCount.toString().padLeft(3, '0')}';
    } catch (e) {
      print('Error in _getNextId: $e');
      debugPrint('Failed to generate ID. Please try again.');
      return ''; // Return an empty string or handle error as needed
    }
  }

  // ======================== CARETAKER CRUD ========================

  //READ
  Future<Caretaker?> getCaretaker() async {
    final currentUser = auth.currentUser;

    if (currentUser == null || currentUser.email == null) {
      debugPrint('User is not authenticated');
    }

    try {
      //QUERY SNAPSHOT.
      QuerySnapshot snapshot = await caretakerfirestore
          .collection('caretaker')
          .where('authId', isEqualTo: currentUser!.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint(
          'No authenticated id ${currentUser.uid} inside caretaker collection selected',
        );
      }

      final caretakerId = snapshot.docs.first.id;

      final doc = await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .get();
      return doc.exists ? Caretaker.fromMap(doc.id, doc.data()!) : null;
    } catch (e) {
      debugPrint('Error: try again later. ${e.toString()}');
      return null;
    }
  }

  //UPDATE CARETAKER PHONE NUMBER
  Future<void> updatePhoneNumber(BuildContext context, String newPhone) async {
    try {
      final caretakerId = await _getCaretakerIdOnly();

      await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .update({'phone': newPhone});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully updated phone number'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Failed to update phone number. ${e.toString()}');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          SnackBar(content: Text('Failed to update phone number: $e')));
    }
  }

  //UPDATE CARETAKER SPECIALIZATION
  Future<void> updateSpecialization(
      BuildContext context, String specialization) async {
    try {
      final caretakerId = await _getCaretakerIdOnly();

      await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .update({'specialization': specialization});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully updated autism centre types'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          SnackBar(content: Text('Failed to update autism centre type: $e')));
    }
  }

  //UPDATE CARETAKER ABOUT (DESCRIPTION)
  Future<void> updateDescription(
      BuildContext context, String newDescription) async {
    try {
      final caretakerId = await _getCaretakerIdOnly();

      await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .update({'description': newDescription});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully updated about'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error updating about: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update about: $e')));
    }
  }

  //UPDATE CARETAKER SERVICES
  Future<void> updateServices(
      BuildContext context, List<String> newServices) async {
    try {
      final caretakerId = await _getCaretakerIdOnly();

      await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .update({'services': newServices});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully updated about'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error updating services: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update services: $e')));
    }
  }

  //CREATE or UPDATE LOCATION
  Future<Caretaker?> updateLocation(
    BuildContext context,
    LatLng selectedLocation,
    Map<String, dynamic> locationDetails,
  ) async {
    final currentUser = auth.currentUser;

    if (currentUser == null || currentUser.email == null) {
      debugPrint('User is not authenticated');
    }

    // Update caretaker in Firebase
    try {
      final locationMap = {
        'latitude': selectedLocation.latitude,
        'longitude': selectedLocation.longitude,
      };

      QuerySnapshot snapshot = await caretakerfirestore
          .collection('caretaker')
          .where('authId', isEqualTo: currentUser!.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint(
          'No authenticated id ${currentUser.uid} inside caretaker collection selected',
        );
      }

      final caretakerId = snapshot.docs.first.id;

      await FirebaseFirestore.instance
          .collection('caretaker')
          .doc(caretakerId)
          .update({
        'location': locationMap,
        'address': locationDetails['placeAddress'],
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Location updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update location: $e')));
    }
    return null;
  }

  //================= UPDATE MEDIA IMAGE AND VIDEO =============================

  //UPLOAD MEDIA
  Future<void> uploadMedia(XFile file, MediaType type) async {
    try {
      debugPrint('Starting public upload...');

      final caretakerId = await _getCaretakerIdOnly();

      // Read file
      final fileBytes = await file.readAsBytes();
      final fileExt = file.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'public_uploads/$caretakerId/$fileName';

      debugPrint('Uploading to path: $filePath');

      // Upload to Supabase
      await _supabase.storage
          .from('caretakerimages')
          .uploadBinary(filePath, fileBytes);

      // Get URL
      final urlResponse =
          _supabase.storage.from('caretakerimages').getPublicUrl(filePath);

      debugPrint('Public URL: $urlResponse');

      // Save to Firestore
      await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('caretaker_media')
          .add({
        'url': urlResponse,
        'type': type == MediaType.image ? 'image' : 'video',
        'createdAt': Timestamp.now(),
        'caretakerId': caretakerId,
      });

      debugPrint('Upload completed successfully');
    } catch (e) {
      debugPrint('Upload error: ${e.toString()}');
      throw Exception('Upload failed: ${e.toString()}');
    }
  }

  //DISPLAY MEDIA
  Future<List<MediaItem>> getMediaItems() async {
    try {
      debugPrint('Fetching all public media...');

      final caretakerId = await _getCaretakerIdOnly();

      final snapshot = await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('caretaker_media') // Consistent collection name
          .orderBy('createdAt', descending: true)
          .get();

      debugPrint('Found ${snapshot.docs.length} items');

      return snapshot.docs.map((doc) => MediaItem.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Fetch error: ${e.toString()}');
      throw Exception('Failed to get media: ${e.toString()}');
    }
  }

  //DELETE MEDIA
  Future<void> deleteMedia(String mediaId) async {
    try {
      debugPrint('Attempting to delete media ID: $mediaId');

      final caretakerId = await _getCaretakerIdOnly();

      // First get the media item
      final doc = await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('caretaker_media') // Consistent collection name
          .doc(mediaId)
          .get();

      if (!doc.exists) {
        debugPrint('Document not found');
        return;
      }

      // Extract file path from URL
      final url = doc.data()!['url'] as String;
      final filePath = url.split('/caretakerimages/$caretakerId').last;
      debugPrint('Extracted file path: $filePath');

      // Delete from storage
      await _supabase.storage.from('caretakerimages').remove([filePath]);

      // Delete from Firestore
      await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('caretaker_media')
          .doc(mediaId)
          .delete();

      debugPrint('Deletion successful');
    } catch (e) {
      debugPrint('Deletion error: ${e.toString()}');
      throw Exception('Failed to delete: ${e.toString()}');
    }
  }

  // ======================== STAFF CRUD ========================

  // ADD NEW STAFF
  Future<void> addStaff(StaffMember staff) async {
    final caretaker = await getCaretaker();
    if (caretaker == null) {
      debugPrint('Caretaker not found');
      return;
    }

    final staffId = await _getNextId('staff', 'ST');
    final currentUser = auth.currentUser;

    // Verify user and email
    if (currentUser == null || currentUser.email == null) {
      debugPrint('No authenticated user');
      return;
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('caretaker')
        .where('authId', isEqualTo: currentUser.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      debugPrint('No caretaker found for current user');
      return;
    }

    final caretakerId = snapshot.docs.first.id;

    // Create an updated staff object with the generated ID
    final staffWithId = StaffMember(
      id: staffId,
      caretakerId: caretakerId,
      name: staff.name,
      dob: staff.dob,
      email: staff.email,
      createdAt: Timestamp.now(),
    );

    await caretakerfirestore
        .collection('caretaker')
        .doc(caretakerId)
        .collection('staff')
        .doc(staffId)
        .set(staffWithId.toMap());
  }

  // UPDATE EXISTING STAFF
  Future<void> updateStaff(StaffMember staff, String staffId) async {
    final caretaker = await getCaretaker();
    if (caretaker == null) {
      debugPrint('Caretaker not found');
      return;
    }

    final currentUser = auth.currentUser;

    // Verify user and email
    if (currentUser == null || currentUser.email == null) {
      debugPrint('No authenticated user');
      return;
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('caretaker')
        .where('authId', isEqualTo: currentUser.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      debugPrint('No caretaker found for current user');
      return;
    }

    final caretakerId = snapshot.docs.first.id;
    // Create an updated staff object with the generated ID
    final staffWithId = StaffMember(
      id: staffId,
      caretakerId: caretakerId,
      name: staff.name,
      dob: staff.dob,
      email: staff.email,
      createdAt: Timestamp.now(),
    );

    await caretakerfirestore
        .collection('caretaker')
        .doc(caretakerId)
        .collection('staff')
        .doc(staffId)
        .update(staffWithId.toMap());
  }

  // DELETE STAFF
  Future<void> deleteStaff(String staffId) async {
    final caretaker = await getCaretaker();
    if (caretaker == null) {
      debugPrint('Caretaker not found');
      return;
    }

    final currentUser = auth.currentUser;

    // Verify user and email
    if (currentUser == null || currentUser.email == null) {
      debugPrint('No authenticated user');
      return;
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('caretaker')
        .where('authId', isEqualTo: currentUser.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      debugPrint('No caretaker found for current user');
      return;
    }

    final caretakerId = snapshot.docs.first.id;

    await caretakerfirestore
        .collection('caretaker')
        .doc(caretakerId)
        .collection('staff')
        .doc(staffId)
        .delete();
  }

  // GET ALL STAFF MEMBER FROM CARETAKER
  Stream<List<StaffMember>> getStaff(String caretakerId) {
    return caretakerfirestore
        .collection('caretaker')
        .doc(caretakerId)
        .collection('staff')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StaffMember.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // GET A SINGLE STAFF MEMBER
  Future<StaffMember?> getStaffMember(String staffId) async {
    final caretaker = await getCaretaker();
    if (caretaker == null) {
      debugPrint('Caretaker not found');
      return null;
    }

    final currentUser = auth.currentUser;

    // Verify user and email
    if (currentUser == null || currentUser.email == null) {
      debugPrint('No authenticated user');
      return null;
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('caretaker')
        .where('authId', isEqualTo: currentUser.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      debugPrint('No caretaker found for current user');
      return null;
    }

    final caretakerId = snapshot.docs.first.id;

    final doc = await caretakerfirestore
        .collection('caretaker')
        .doc(caretakerId)
        .collection('staff')
        .doc(staffId)
        .get();

    return doc.exists ? StaffMember.fromMap(doc.id, doc.data()!) : null;
  }

  // TAKE A SNAPSHOT FROM STAFF
  Future<Stream<QuerySnapshot<Object?>>> snapshots() async {
    final currentUser = auth.currentUser;

    // Verify user and email
    if (currentUser == null || currentUser.email == null) {
      debugPrint('No authenticated user');
      throw Exception(
        'No authenticated user',
      ); // Keep this as it's a fundamental requirement
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('caretaker')
        .where('authId', isEqualTo: currentUser.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      debugPrint('No caretaker found for current user');
      throw Exception(
        'No caretaker found for current user',
      ); // Keep this as it's a fundamental requirement
    }

    final caretakerId = snapshot.docs.first.id;
    return caretakerfirestore
        .collection('caretaker')
        .doc(caretakerId)
        .collection('staff')
        .snapshots();
  }

  // ======================== APPROVAL ACCEPT DECLINER ==================================

  Future<CollectionReference> getApprovalCollection() async {
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final caretakerId = await _getCaretakerIdOnly();

    return caretakerfirestore
        .collection('caretaker')
        .doc(caretakerId)
        .collection('apply');
  }

  Future<List<Approval>> getApprovalList() async {
    try {
      final applyCollection = await getApprovalCollection();
      final querySnapshot = await applyCollection.get();

      return querySnapshot.docs
          .map((doc) => Approval.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching approval list: $e');
      return [];
    }
  }

  Future<List<Approval>> getPendingApprovals() async {
    try {
      final applyCollection = await getApprovalCollection();
      final querySnapshot = await applyCollection
          .where('applyStatus', isEqualTo: 'pending')
          .get();

      debugPrint('=== FULL QUERY SNAPSHOT DEBUG ===');
      debugPrint('Size: ${querySnapshot.size}');
      debugPrint('Metadata: ${querySnapshot.metadata}');

      querySnapshot.docs.asMap().forEach((index, doc) {
        debugPrint('\nDocument #$index:');
        debugPrint('ID: ${doc.id}');
        debugPrint('Path: ${doc.reference.path}');
        debugPrint('Exists: ${doc.exists}');
        debugPrint('Data: ${doc.data()}');
        debugPrint('Metadata: ${doc.metadata}');
      });

      return querySnapshot.docs
          .map((doc) => Approval.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching pending approvals: $e');
      return [];
    }
  }

  Future<List<Approval>> getApprovalHistory() async {
    try {
      final applyCollection = await getApprovalCollection();
      final querySnapshot = await applyCollection
          .where('applyStatus', whereIn: ['approved', 'declined']).get();

      return querySnapshot.docs
          .map((doc) => Approval.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching approval history: $e');
      return [];
    }
  }

  Future<void> approveRequest(String applyId) async {
    try {
      final applyCollection = await getApprovalCollection();
      final approvalDoc = await applyCollection.doc(applyId).get();

      if (!approvalDoc.exists) {
        throw Exception('Approval document not found');
      }

      // Parse the approval data
      final approval = Approval.fromJson(
        approvalDoc.data() as Map<String, dynamic>?,
      );
      final parentId = approval.parentInfo?.id;
      final childId = approval.childInfo?.id;

      if (parentId == null || childId == null) {
        throw Exception('Missing parentId or childId in approval data');
      }

      // Get current caretaker information
      final caretaker = await getCaretaker();
      if (caretaker == null) {
        throw Exception('Caretaker information not available');
      }

      // Create a batch to perform atomic updates
      final batch = caretakerfirestore.batch();

      // 1. Update the approval status
      final approvalRef = applyCollection.doc(applyId);
      batch.update(approvalRef, {
        'applyStatus': 'approved',
        'decisionDate': Timestamp.now(),
      });

      // 2. Update the child document in parents collection
      final childInParentsRef = caretakerfirestore
          .collection('parents')
          .doc(parentId)
          .collection('child')
          .doc(childId);

      batch.update(childInParentsRef, {
        'caretakerId': caretaker.id,
        'autismCentreName': caretaker.name,
        'lastUpdated': Timestamp.now(),
      });

      // 3. Add child to caretaker's children collection
      final childInCaretakerRef = caretakerfirestore
          .collection('caretaker')
          .doc(caretaker.id)
          .collection('child')
          .doc(childId);

      // Convert Child object to map and add caretaker-specific fields
      final childData = approval.childInfo?.toJson() ?? {};
      childData.addAll({
        'caretakerId': caretaker.id,
        'assignedDate': Timestamp.now(),
      });
      batch.set(childInCaretakerRef, childData, SetOptions(merge: true));

      // 4. Add parent to caretaker's parents collection
      final parentInCaretakerRef = caretakerfirestore
          .collection('caretaker')
          .doc(caretaker.id)
          .collection('parent')
          .doc(parentId);

      final parentData = approval.parentInfo?.toJson() ?? {};
      parentData.addAll({
        'caretakerId': caretaker.id,
        'assignedDate': Timestamp.now(),
      });
      batch.set(parentInCaretakerRef, parentData, SetOptions(merge: true));

      // Commit all updates as a single transaction
      await batch.commit();

      debugPrint('''
Successfully approved request $applyId and updated records:
- Updated approval status
- Updated child document in parents collection
- Added child to caretaker's children collection
- Added parent to caretaker's parents collection
''');
    } catch (e, stackTrace) {
      debugPrint('Error approving request: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to approve request: ${e.toString()}');
    }
  }

  Future<void> declineRequest(String applyId) async {
    try {
      final applyCollection = await getApprovalCollection();
      await applyCollection.doc(applyId).update({
        'applyStatus': 'declined',
        'decisionDate': Timestamp.now(),
      });
    } catch (e) {
      print('Error declining request: $e');
      throw e;
    }
  }

  // ======================== ATTENDANCE CRUD ========================

  // Get current work hours
  Future<Map<String, String>> getWorkHours() async {
    try {
      final caretakerId = await _getCaretakerIdOnly();

      final doc = await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .get();
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

  // Update all work hours at once
  Future<void> updateAllWorkHours(Map<String, String> workHours) async {
    try {
      final caretakerId = await _getCaretakerIdOnly();

      await caretakerfirestore.collection('caretaker').doc(caretakerId).update({
        'workHours': workHours,
      });
    } catch (e) {
      print('Error updating work hours: $e');
      throw Exception('Failed to update work hours');
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

  // Helper to format TimeOfDay to string
  String formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  //Add Attendance List
  Future<void> addAttendance(
    BuildContext context,
    String childId,
    String childName,
    String parentId,
    String parentName,
  ) async {
    try {
      final caretakerId = await _getCaretakerIdOnly();

      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final timeStr = DateFormat('HH:mm').format(now);

      // Check if attendance already exists for today
      final existingAttendance = await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('attendance')
          .where('childId', isEqualTo: childId)
          .where('date', isEqualTo: dateStr)
          .get();

      if (existingAttendance.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Attendance already recorded for today')),
        );
        return;
      }

      // Add new attendance record
      await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('attendance')
          .add({
        'childId': childId,
        'childName': childName,
        'parentId': parentId,
        'parentName': parentName,
        'clockIn': timeStr,
        'clockOut': '',
        'date': dateStr,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clock-in recorded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recording attendance: $e')),
      );
    }
  }

  Future<void> clockOutAttendance(
    BuildContext context,
    String childId,
    String dateStr,
  ) async {
    try {
      final caretakerId = await _getCaretakerIdOnly();

      final now = DateTime.now();
      final timeStr = DateFormat('HH:mm').format(now);

      // Find today's attendance record
      final attendanceQuery = await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('attendance')
          .where('childId', isEqualTo: childId)
          .where('date', isEqualTo: dateStr)
          .get();

      if (attendanceQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No attendance record found for today')),
        );
        return;
      }

      final doc = attendanceQuery.docs.first;
      if (doc['clockOut'].isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clock-out already recorded')),
        );
        return;
      }

      // Update with clock-out time
      await doc.reference.update({
        'clockOut': timeStr,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clock-out recorded successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recording clock-out: $e')),
      );
    }
  }

  Future<List<AttendanceRecord>> getAttendanceForDate(String dateStr) async {
    try {
      final caretakerId = await _getCaretakerIdOnly();
      final snapshot = await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('attendance')
          .where('date', isEqualTo: dateStr)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceRecord.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch attendance: $e');
    }
  }

  // ======================== ACTIVITY TIMETABLE CRUD ========================

  // Get collection reference with user-specific data
  Future<CollectionReference> _getActivityCollection() async {
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final caretakerId = await _getCaretakerIdOnly();

    return caretakerfirestore
        .collection('caretaker')
        .doc(caretakerId)
        .collection('activitytimetable');
  }

  // Get activities for a specific date
  Future<List<ActivityItem>> getActivities(DateTime date) async {
    try {
      // Format date to compare (without time)
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final activityCollection = await _getActivityCollection();

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

  // Add a new activity
  Future<void> addActivity(
    TimeOfDay startTime,
    TimeOfDay endTime,
    String task,
    String description,
    DateTime date,
  ) async {
    try {
      // Generate custom ID
      final activityTimetableId = await _getNextId('activitytimetable', 'AT');

      // Create activity data
      final activityData = {
        'startTime': {'hour': startTime.hour, 'minute': startTime.minute},
        'endTime': {'hour': endTime.hour, 'minute': endTime.minute},
        'task': task,
        'description': description,
        'date': Timestamp.fromDate(date),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final activityCollection = await _getActivityCollection();

      await activityCollection.doc(activityTimetableId).set(activityData);
    } catch (e) {
      print('Error adding activity: $e');
      rethrow;
    }
  }

  // Add multiple activities at once
  Future<void> addMultipleActivities(
    List<Map<String, dynamic>> activitiesData,
    DateTime date,
  ) async {
    try {
      final batch = caretakerfirestore.batch();
      final activityCollection = await _getActivityCollection();

      for (var data in activitiesData) {
        // Generate custom ID for each activity
        final activityTimetableId = await _getNextId('activitytimetable', 'AT');

        final activityData = {
          'startTime': {
            'hour': data['startTime'].hour,
            'minute': data['startTime'].minute,
          },
          'endTime': {
            'hour': data['endTime'].hour,
            'minute': data['endTime'].minute,
          },
          'task': data['task'],
          'description': data['description'],
          'date': Timestamp.fromDate(date),
          'createdAt': FieldValue.serverTimestamp(),
        };

        batch.set(activityCollection.doc(activityTimetableId), activityData);
      }

      await batch.commit();
    } catch (e) {
      print('Error adding multiple activities: $e');
      rethrow;
    }
  }

  // Update an existing activity
  Future<void> updateActivity(
    String id,
    TimeOfDay startTime,
    TimeOfDay endTime,
    String task,
    String description,
    DateTime date,
  ) async {
    try {
      final activityData = {
        'startTime': {'hour': startTime.hour, 'minute': startTime.minute},
        'endTime': {'hour': endTime.hour, 'minute': endTime.minute},
        'task': task,
        'description': description,
        'date': Timestamp.fromDate(date),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final activityCollection = await _getActivityCollection();

      await activityCollection.doc(id).update(activityData);
    } catch (e) {
      print('Error updating activity: $e');
      rethrow;
    }
  }

  // Delete an activity
  Future<void> deleteActivity(String id) async {
    try {
      final activityCollection = await _getActivityCollection();

      await activityCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting activity: $e');
      rethrow;
    }
  }

  // ======================== ACTIVITY POST CRUD ========================

  // CREATE
  Future<void> createActivityPost(
    String staffId,
    String staffName,
    String title,
    String description,
    File? image,
  ) async {
    try {
      final currentUser = auth.currentUser;

      if (currentUser == null || currentUser.email == null) {
        debugPrint('No authenticated user');
        return;
      }

      final activityPostId = await _getNextId('activitypost', 'AP');

      QuerySnapshot snapshot;
      try {
        snapshot = await caretakerfirestore
            .collection('caretaker')
            .where("authId", isEqualTo: currentUser.uid)
            .limit(1)
            .get();
      } catch (e) {
        debugPrint('Failed to fetch caretaker data: ${e.toString()}');
        return;
      }

      if (snapshot.docs.isEmpty) {
        debugPrint('No caretaker found for current user');
        return;
      }

      final caretakerId = snapshot.docs.first.id;
      String? localImagePath;

      // Save image to local storage if provided
      if (image != null) {
        try {
          final directory = await getApplicationDocumentsDirectory();
          final imagePath = '${directory.path}/images/activity_posts';
          await Directory(imagePath).create(recursive: true);
          final newImagePath = '$imagePath/$activityPostId.jpg';
          final File savedImage = await image.copy(newImagePath);
          localImagePath = savedImage.path;
        } catch (e) {
          debugPrint('Failed to save image to local storage: ${e.toString()}');
        }
      }

      final activityPost = ActivityPost(
        id: activityPostId,
        caretakerId: caretakerId,
        staffId: staffId,
        staffName: staffName,
        title: title,
        description: description,
        dateTime: Timestamp.now(),
        imageUrl: localImagePath, // Store the local file path
      );

      try {
        await caretakerfirestore
            .collection('caretaker')
            .doc(caretakerId)
            .collection('activitypost')
            .doc(activityPostId)
            .set(activityPost.toMap());
      } catch (e) {
        debugPrint('Failed to create activity post: ${e.toString()}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // READ - Get all activity posts by selected caretaker
  Future<List<ActivityPost>> getActivityPostsByCaretaker() async {
    try {
      final currentUser = auth.currentUser;

      if (currentUser == null || currentUser.email == null) {
        debugPrint('No authenticated user');
        return [];
      }

      // Get caretaker document
      QuerySnapshot snapshotCaretaker;
      try {
        snapshotCaretaker = await caretakerfirestore
            .collection('caretaker')
            .where("authId", isEqualTo: currentUser.uid)
            .limit(1)
            .get();
      } catch (e) {
        debugPrint('Failed to fetch caretaker data: ${e.toString()}');
        return [];
      }

      if (snapshotCaretaker.docs.isEmpty) {
        debugPrint('No caretaker found for current user');
        return [];
      }

      final caretakerId = snapshotCaretaker.docs.first.id;

      // Get activity posts
      QuerySnapshot querySnapshot;
      try {
        querySnapshot = await caretakerfirestore
            .collection('caretaker')
            .doc(caretakerId)
            .collection('activitypost')
            .where('caretakerId', isEqualTo: caretakerId)
            .orderBy('dateTime', descending: true)
            .get();
      } catch (e) {
        debugPrint(e.toString());
        debugPrint('Failed to fetch activity posts: ${e.toString()}');
        return [];
      }

      // Convert documents to ActivityPost objects
      try {
        return querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return ActivityPost.fromMap(doc.id, {...data, 'id': doc.id});
        }).toList();
      } catch (e) {
        debugPrint('Failed to parse activity posts: ${e.toString()}');
        return [];
      }
    } catch (e) {
      rethrow;
    }
  }

  // UPDATE
  Future<void> updateActivityPost(
    String postId,
    String title,
    String description,
    File? newImage,
    String? existingImageUrl,
  ) async {
    try {
      String? localImagePath = existingImageUrl;
      final currentUser = auth.currentUser;

      if (currentUser == null || currentUser.email == null) {
        debugPrint('No authenticated user');
        return;
      }

      // Get caretaker document
      QuerySnapshot snapshotCaretaker;
      try {
        snapshotCaretaker = await caretakerfirestore
            .collection('caretaker')
            .where("authId", isEqualTo: currentUser.uid)
            .limit(1)
            .get();
      } catch (e) {
        debugPrint('Failed to fetch caretaker data: ${e.toString()}');
        return;
      }

      if (snapshotCaretaker.docs.isEmpty) {
        debugPrint('No caretaker found for current user');
      }

      final caretakerId = snapshotCaretaker.docs.first.id;

      // Save new image to local storage if provided
      if (newImage != null) {
        try {
          final directory = await getApplicationDocumentsDirectory();
          final imagePath = '${directory.path}/images/activity_posts';
          await Directory(imagePath).create(recursive: true);
          final newImagePath = '$imagePath/$postId.jpg';
          final File savedImage = await newImage.copy(newImagePath);
          localImagePath = savedImage.path;

          // Optionally delete the old local image if it exists
          if (existingImageUrl?.isNotEmpty ?? false) {
            final File oldImageFile = File(existingImageUrl!);
            if (await oldImageFile.exists()) {
              await oldImageFile.delete();
            }
          }
        } catch (e) {
          debugPrint(
            'Failed to save new image to local storage: ${e.toString()}',
          );
        }
      }

      try {
        await caretakerfirestore
            .collection('caretaker')
            .doc(caretakerId)
            .collection('activitypost')
            .doc(postId)
            .update({
          'title': title,
          'description': description,
          'imageUrl': localImagePath,
        });
      } catch (e) {
        debugPrint('Failed to update activity post: ${e.toString()}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // DELETE
  Future<void> deleteActivityPost(String postId, String? imageUrl) async {
    try {
      final currentUser = auth.currentUser;

      if (currentUser == null || currentUser.email == null) {
        debugPrint('No authenticated user');
        return;
      }

      // Get caretaker document
      QuerySnapshot snapshotCaretaker;
      try {
        snapshotCaretaker = await caretakerfirestore
            .collection('caretaker')
            .where("authId", isEqualTo: currentUser.uid)
            .limit(1)
            .get();
      } catch (e) {
        debugPrint('Failed to fetch caretaker data: ${e.toString()}');
        return;
      }

      if (snapshotCaretaker.docs.isEmpty) {
        debugPrint('No caretaker found for current user');
      }

      final caretakerId = snapshotCaretaker.docs.first.id;

      // Delete local image if path exists
      if (imageUrl?.isNotEmpty ?? false) {
        try {
          final imageFile = File(imageUrl!);
          if (await imageFile.exists()) {
            await imageFile.delete();
          }
        } catch (e) {
          debugPrint('Failed to delete local image: ${e.toString()}');
          // Optionally decide if this error should prevent post deletion
        }
      }

      try {
        await caretakerfirestore
            .collection('caretaker')
            .doc(caretakerId)
            .collection('activitypost')
            .doc(postId)
            .delete();
      } catch (e) {
        debugPrint('Failed to delete activity post: ${e.toString()}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ======================== NUTRITION TIMETABLE CRUD ========================

  // Get collection reference with user-specific data
  Future<CollectionReference> _getNutritionCollection() async {
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final caretakerId = await _getCaretakerIdOnly();

    return caretakerfirestore
        .collection('caretaker')
        .doc(caretakerId)
        .collection('nutritiontimetable');
  }

  // Get nutrition items for a specific date
  Future<List<NutritionItem>> getNutritionItems(DateTime date) async {
    try {
      // Format date to compare (without time)
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final nutritionCollection = await _getNutritionCollection();

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

  // Add a new nutrition item
  Future<void> addNutritionItem(
    TimeOfDay startTime,
    TimeOfDay endTime,
    String mealName,
    String mealDescription,
    DateTime date,
  ) async {
    try {
      // Generate custom ID
      final nutritionTimetableId = await _getNextId('nutritiontimetable', 'NT');

      // Create nutrition data
      final nutritionData = {
        'startTime': {'hour': startTime.hour, 'minute': startTime.minute},
        'endTime': {'hour': endTime.hour, 'minute': endTime.minute},
        'mealName': mealName,
        'mealDescription': mealDescription,
        'date': Timestamp.fromDate(date),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final nutritionCollection = await _getNutritionCollection();

      await nutritionCollection.doc(nutritionTimetableId).set(nutritionData);
    } catch (e) {
      print('Error adding nutrition item: $e');
      rethrow;
    }
  }

  // Add multiple nutrition items at once
  Future<void> addMultipleNutritionItems(
    List<Map<String, dynamic>> nutritionData,
    DateTime date,
  ) async {
    try {
      final batch = caretakerfirestore.batch();
      final nutritionCollection = await _getNutritionCollection();

      for (var data in nutritionData) {
        // Generate custom ID for each nutrition item
        final nutritionTimetableId = await _getNextId(
          'nutritiontimetable',
          'NT',
        );

        final itemData = {
          'startTime': {
            'hour': data['startTime'].hour,
            'minute': data['startTime'].minute,
          },
          'endTime': {
            'hour': data['endTime'].hour,
            'minute': data['endTime'].minute,
          },
          'mealName': data['mealName'],
          'mealDescription': data['mealDescription'],
          'date': Timestamp.fromDate(date),
          'createdAt': FieldValue.serverTimestamp(),
        };

        batch.set(nutritionCollection.doc(nutritionTimetableId), itemData);
      }

      await batch.commit();
    } catch (e) {
      print('Error adding multiple nutrition items: $e');
      rethrow;
    }
  }

  // Update an existing nutrition item
  Future<void> updateNutritionItem(
    String id,
    TimeOfDay startTime,
    TimeOfDay endTime,
    String mealName,
    String mealDescription,
    DateTime date,
  ) async {
    try {
      final nutritionData = {
        'startTime': {'hour': startTime.hour, 'minute': startTime.minute},
        'endTime': {'hour': endTime.hour, 'minute': endTime.minute},
        'mealName': mealName,
        'mealDescription': mealDescription,
        'date': Timestamp.fromDate(date),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final nutritionCollection = await _getNutritionCollection();

      await nutritionCollection.doc(id).update(nutritionData);
    } catch (e) {
      print('Error updating nutrition item: $e');
      rethrow;
    }
  }

  // Delete a nutrition item
  Future<void> deleteNutritionItem(String id) async {
    try {
      final nutritionCollection = await _getNutritionCollection();

      await nutritionCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting nutrition item: $e');
      rethrow;
    }
  }

  // ======================== PAYMENT CRUD ========================

  // Get collection reference with user-specific data
  Future<CollectionReference> _getCaretakerPaymentCollection() async {
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final caretakerId = await _getCaretakerIdOnly();

    return caretakerfirestore
        .collection('caretaker')
        .doc(caretakerId)
        .collection('payments');
  }

  Future<CollectionReference> _getParentPaymentCollection() async {
    final parentId = await _getParentIdFromCaretaker();

    return caretakerfirestore
        .collection('parents')
        .doc(parentId)
        .collection('payments');
  }

  // Get all payment items
  // Modify your getAllPayments() method to include overdue check
  Future<List<Payment>> getAllPayments() async {
    try {
      print('Starting getAllPayments()');
      final paymentCollection = await _getCaretakerPaymentCollection();
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      print('Today: $todayStart');

      final snapshot = await paymentCollection.orderBy('dueDate').get();
      print('Fetched ${snapshot.docs.length} payments from Firestore');

      final payments = snapshot.docs.map((doc) {
        print(
          'Payment ${doc.id}: status=${doc['status']}, due=${doc['dueDate']?.toDate()}',
        );
        return Payment.fromFirestore(doc);
      }).toList();

      final overduePayments = payments.where((payment) {
        final isOverdue =
            payment.status == 'Pending' && payment.dueDate.isBefore(todayStart);
        if (isOverdue) print('MARKING OVERDUE: ${payment.id}');
        return isOverdue;
      }).toList();

      if (overduePayments.isNotEmpty) {
        print('Found ${overduePayments.length} overdue payments to update');
        final batch = caretakerfirestore.batch();
        final parentPaymentCollection = await _getParentPaymentCollection();

        for (var payment in overduePayments) {
          final updateData = {
            'status': 'Overdue',
            'updatedAt': FieldValue.serverTimestamp(),
          };
          print('Updating payment ${payment.id} in ${paymentCollection.path}');
          batch.update(paymentCollection.doc(payment.id), updateData);
          print(
            'Updating payment ${payment.id} in ${parentPaymentCollection.path}',
          );
          batch.update(parentPaymentCollection.doc(payment.id), updateData);
        }

        try {
          await batch.commit();
          print('Batch commit successful');
        } catch (e) {
          print('Batch commit failed: $e');
          rethrow;
        }

        // Update local copies
        overduePayments.forEach((p) => p.status = 'Overdue');
      } else {
        print('No overdue payments found');
      }

      return payments;
    } catch (e) {
      print('Error in getAllPayments: $e');
      rethrow;
    }
  }

  // Get payments by status
  Future<List<Payment>> getPaymentsByStatus(String status) async {
    try {
      final paymentCollection = await _getCaretakerPaymentCollection();

      final snapshot = await paymentCollection
          .where('status', isEqualTo: status)
          .orderBy('dueDate', descending: false)
          .get();

      final payments =
          snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();

      return payments;
    } catch (e) {
      print('Error getting payments by status: $e');
      rethrow;
    }
  }

  // Get overdue payments
  Future<List<Payment>> getOverduePayments() async {
    try {
      final paymentCollection = await _getCaretakerPaymentCollection();
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final snapshot = await paymentCollection
          .where('status', whereIn: ['Pending', 'Overdue'])
          .where('dueDate', isLessThan: Timestamp.fromDate(todayStart))
          .orderBy('dueDate', descending: false)
          .get();

      final payments =
          snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();

      return payments;
    } catch (e) {
      print('Error getting overdue payments: $e');
      rethrow;
    }
  }

  // Get payment by ID
  Future<Payment?> getPaymentById(String paymentId) async {
    try {
      final paymentCollection = await _getCaretakerPaymentCollection();

      final doc = await paymentCollection.doc(paymentId).get();

      if (doc.exists) {
        return Payment.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting payment by ID: $e');
      rethrow;
    }
  }

  // Add multiple payments at once
  Future<void> addMultiplePayments(
    List<Map<String, dynamic>> paymentsData,
  ) async {
    try {
      final batch = caretakerfirestore.batch();

      for (var data in paymentsData) {
        // Generate custom ID for each payment
        final paymentId = await _getNextId('payments', 'PAY');
        final parentId = data['parentId'] as String;
        final caretakerId = await _getCaretakerIdOnly();
        // Fetch caretaker name if not provided
        final caretakerName =
            data['caretakerName'] ?? await _getCaretakerName();

        final itemData = {
          'id': paymentId,
          'caretakerId': caretakerId,
          'caretakerName': caretakerName,
          'parentId': parentId,
          'parentName': data['parentName'],
          'childId': data['childId'],
          'childName': data['childName'],
          'amount': data['amount'],
          'status': data['status'],
          'dueDate': Timestamp.fromDate(data['dueDate']),
          'createdAt': FieldValue.serverTimestamp(),
        };

        final caretakerPaymentCollection =
            await _getCaretakerPaymentCollection();

        batch.set(caretakerPaymentCollection.doc(paymentId), itemData);
        batch.set(
            caretakerfirestore
                .collection('parents')
                .doc(parentId)
                .collection('payments')
                .doc(paymentId),
            itemData);
      }

      await batch.commit();
    } catch (e) {
      print('Error adding multiple payments: $e');
      rethrow;
    }
  }

  // Update an existing payment
  Future<void> updatePayment(
    String id,
    String parentId,
    String parentName,
    String childId,
    String childName,
    double amount,
    String status,
    DateTime dueDate,
  ) async {
    try {
      final paymentData = {
        'parentId': parentId,
        'parentName': parentName,
        'childId': childId,
        'childName': childName,
        'amount': amount,
        'status': status,
        'dueDate': Timestamp.fromDate(dueDate),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final caretakerPaymentCollection = await _getCaretakerPaymentCollection();

      // Update both collections in a batch
      final batch = caretakerfirestore.batch();
      batch.update(caretakerPaymentCollection.doc(id), paymentData);
      batch.update(
          caretakerfirestore
              .collection('parents')
              .doc(parentId)
              .collection('payments')
              .doc(id),
          paymentData);
      await batch.commit();
    } catch (e) {
      print('Error updating payment: $e');
      rethrow;
    }
  }

  // Update only payment status
  Future<void> updatePaymentStatus(String id, String newStatus) async {
    try {
      final updateData = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final caretakerPaymentCollection = await _getCaretakerPaymentCollection();
      final parentPaymentCollection = await _getParentPaymentCollection();

      // Update both collections in a batch
      final batch = caretakerfirestore.batch();
      batch.update(caretakerPaymentCollection.doc(id), updateData);
      batch.update(parentPaymentCollection.doc(id), updateData);
      await batch.commit();
    } catch (e) {
      print('Error updating payment status: $e');
      rethrow;
    }
  }

  // Delete a payment
  Future<void> deletePayment(String id) async {
    try {
      final caretakerPaymentCollection = await _getCaretakerPaymentCollection();

      // First get the payment document to find the parentId
      final paymentDoc = await caretakerPaymentCollection.doc(id).get();
      if (!paymentDoc.exists) {
        throw Exception('Payment document not found');
      }

      final parentId = paymentDoc['parentId'] as String;
      final parentPaymentRef = caretakerfirestore
          .collection('parents')
          .doc(parentId)
          .collection('payments')
          .doc(id);

      // Verify parent payment exists
      final parentPaymentDoc = await parentPaymentRef.get();
      if (!parentPaymentDoc.exists) {
        print(
            'Warning: Parent payment document not found, proceeding with caretaker deletion only');
      }

      print('Deleting payment $id from:');
      print('- Caretaker collection: ${caretakerPaymentCollection.path}');
      print('- Parent collection: parents/$parentId/payments');

      final batch = caretakerfirestore.batch();
      batch.delete(caretakerPaymentCollection.doc(id));
      batch.delete(parentPaymentRef);

      await batch.commit();
      print('Deletion completed successfully');
    } on FirebaseException catch (e) {
      print('Firestore error deleting payment: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error deleting payment: $e');
      rethrow;
    }
  }

  // Delete multiple payments
  // Delete multiple payments from both collections
  Future<void> deleteMultiplePayments(
    List<Map<String, dynamic>> paymentDataList,
  ) async {
    try {
      final batch = caretakerfirestore.batch();

      for (var paymentData in paymentDataList) {
        final id = paymentData['id'];

        final caretakerPaymentCollection =
            await _getCaretakerPaymentCollection();
        final parentPaymentCollection = await _getParentPaymentCollection();

        batch.delete(caretakerPaymentCollection.doc(id));
        batch.delete(parentPaymentCollection.doc(id));
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting multiple payments: $e');
      rethrow;
    }
  }

  // Get payments for a specific date range
  Future<List<Payment>> getPaymentsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final paymentCollection = await _getCaretakerPaymentCollection();

      final snapshot = await paymentCollection
          .where(
            'dueDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where(
            'dueDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          )
          .orderBy('dueDate', descending: false)
          .get();

      final payments =
          snapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();

      return payments;
    } catch (e) {
      print('Error getting payments by date range: $e');
      rethrow;
    }
  }

  // Get payment statistics
  Future<Map<String, dynamic>> getPaymentStatistics() async {
    try {
      final payments = await getAllPayments();

      double totalAmount = 0;
      double paidAmount = 0;
      double pendingAmount = 0;
      double overdueAmount = 0;

      int totalCount = payments.length;
      int paidCount = 0;
      int pendingCount = 0;
      int overdueCount = 0;

      for (var payment in payments) {
        totalAmount += payment.amount;

        switch (payment.status) {
          case 'Paid':
            paidAmount += payment.amount;
            paidCount++;
            break;
          case 'Pending':
            pendingAmount += payment.amount;
            pendingCount++;
            break;
          case 'Overdue':
            overdueAmount += payment.amount;
            overdueCount++;
            break;
        }
      }

      return {
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'pendingAmount': pendingAmount,
        'overdueAmount': overdueAmount,
        'totalCount': totalCount,
        'paidCount': paidCount,
        'pendingCount': pendingCount,
        'overdueCount': overdueCount,
      };
    } catch (e) {
      print('Error getting payment statistics: $e');
      rethrow;
    }
  }

  // Search payments by parent name or child name
  Future<List<Payment>> searchPayments(String searchQuery) async {
    try {
      final payments = await getAllPayments();

      final filteredPayments = payments.where((payment) {
        final query = searchQuery.toLowerCase();
        return payment.parentName.toLowerCase().contains(query) ||
            payment.childName.toLowerCase().contains(query) ||
            payment.id.toLowerCase().contains(query);
      }).toList();

      return filteredPayments;
    } catch (e) {
      print('Error searching payments: $e');
      rethrow;
    }
  }

  // ======================== CHILD AND PARENTS CRUD ========================

  // Get all children with their parent information
  Future<List<Map<String, dynamic>>> getChildrenWithParents() async {
    try {
      final caretakerId = await _getCaretakerIdOnly();

      // Get all children
      final childrenSnapshot = await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('child')
          .get();

      List<Map<String, dynamic>> result = [];

      for (var childDoc in childrenSnapshot.docs) {
        final child = Child.fromFirestore(childDoc);

        // Get parent information
        final parentDoc = await caretakerfirestore
            .collection('caretaker')
            .doc(caretakerId)
            .collection('parent')
            .doc(child.parentId)
            .get();
        final parent =
            parentDoc.exists ? Parent.fromFirestore(parentDoc) : null;

        result.add({'child': child, 'parent': parent});
      }

      return result;
    } catch (e) {
      throw Exception('Failed to fetch children with parents: $e');
    }
  }

  // Get a single child by ID
  Future<Child> getChild(String childId) async {
    try {
      final caretakerId = await _getCaretakerIdOnly();

      final doc = await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('child')
          .doc(childId)
          .get();

      if (!doc.exists) {
        throw Exception('Child not found');
      }

      return Child.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get child: $e');
    }
  }

  // Update a child
  Future<void> updateChild(Child child) async {
    try {
      await caretakerfirestore
          .collection('caretaker')
          .doc(child.parentId)
          .collection('child')
          .doc(child.id)
          .update(child.toMap());
    } catch (e) {
      throw Exception('Failed to update child: $e');
    }
  }

  // Delete a child
  Future<void> deleteChild(String childId, String parentId) async {
    try {
      await caretakerfirestore
          .collection('caretaker')
          .doc(parentId)
          .collection('child')
          .doc(childId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete child: $e');
    }
  }

  // Get a parent by ID
  Future<Parent> getParent(String parentId) async {
    try {
      final caretakerId = await _getCaretakerIdOnly();

      final doc = await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('parent')
          .doc(parentId)
          .get();

      if (!doc.exists) {
        throw Exception('Parent not found');
      }

      return Parent.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get parent: $e');
    }
  }

  // Update a parent
  Future<void> updateParent(Parent parent) async {
    try {
      final caretakerId = await _getCaretakerIdOnly();

      await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('parent')
          .doc(parent.id)
          .update(parent.toMap());
    } catch (e) {
      throw Exception('Failed to update parent: $e');
    }
  }

  // ======================== FEEDBACK AND REVIEW FUNCTION ========================

  // Get all reviews for the current caretaker with parent info
  Future<List<Map<String, dynamic>>> getCaretakerReviewsWithParents() async {
    try {
      final caretakerId = await _getCaretakerIdOnly();
      final querySnapshot = await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('reviews')
          .get();

      List<Map<String, dynamic>> reviewsWithParents = [];

      for (var doc in querySnapshot.docs) {
        final review = Review.fromMap(doc.data());
        final parentId = await _getParentIdFromCaretaker();
        final parent = await getParent(parentId);
        reviewsWithParents.add({
          'review': review,
          'parent': parent,
        });
      }

      return reviewsWithParents;
    } catch (e) {
      print('Error getting caretaker reviews: $e');
      return [];
    }
  }

  // Function to get feedback for a specific review
  Future<Review?> getReviewFeedback(String reviewId) async {
    try {
      final caretakerId = await _getCaretakerIdOnly();
      final doc = await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('reviews')
          .doc(reviewId)
          .get();

      if (doc.exists) {
        return Review.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting feedback: $e');
      return null;
    }
  }

  // Function to send feedback for a review
  Future<bool> sendFeedback({
    required String reviewId,
    required String feedbackMessage,
  }) async {
    try {
      final caretakerId = await _getCaretakerIdOnly();
      final feedbackId = await _getNextId('feedback', 'FD');

      await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('reviews')
          .doc(reviewId)
          .update({
        'feedbackId': feedbackId,
        'feedbackMessage': feedbackMessage,
        'feedbackDate': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error sending feedback: $e');
      return false;
    }
  }

  // ======================= NOTIFICATION AND INBOX ===============================

  static StreamSubscription? _notificationsSubscription;

  Future<void> insertMessage(String title, String message) async {
    try {
      final caretakerId = await _getCaretakerIdOnly();

      await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
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
      String title, String message, String caretakerId) async {
    try {
      // 1. Write to Firestore (as before)
      await FirebaseFirestore.instance
          .collection('caretaker')
          .doc(caretakerId)
          .collection('notifications')
          .add({
        'title': title,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUnreadMessages() async {
    final caretakerId = await _getCaretakerIdOnly();
    final querySnapshot = await caretakerfirestore
        .collection('caretaker')
        .doc(caretakerId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    return querySnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();
  }

  Future<void> readMessage(String messageId) async {
    try {
      final caretakerId = await _getCaretakerIdOnly();

      await caretakerfirestore
          .collection('caretaker')
          .doc(caretakerId)
          .collection('notifications')
          .doc(messageId)
          .update({'read': true});
    } catch (e) {
      throw Exception('Failed to read message: ${e.toString()}');
    }
  }

  Stream<List<Map<String, dynamic>>> getMessageInboxStream() async* {
    final caretakerId = await _getCaretakerIdOnly();

    yield* caretakerfirestore
        .collection('caretaker')
        .doc(caretakerId)
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

    _notificationsSubscription = caretakerfirestore
        .collection('caretaker')
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
