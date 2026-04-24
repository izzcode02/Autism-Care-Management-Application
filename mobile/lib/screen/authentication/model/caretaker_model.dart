import 'package:autism_care_management_application/utils/base_model.dart'; // Assuming this is your base class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart'; // Import for LatLng and Timestamp

class Caretaker extends FirestoreModel {
  final String id;
  final String authId;
  final String name;
  final String email;
  final String phone;
  final String address;
  // Changed from String to LatLng
  final LatLng location;
  // Changed from DateTime to Timestamp
  final Timestamp createdAt;

  Caretaker({
    required this.id,
    required this.authId,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.location, // Now requires LatLng
    required this.createdAt, // Now requires Timestamp
  });

  Caretaker copyWith({
    String? id,
    String? authId,
    String? name,
    String? email,
    String? phone,
    String? address,
    LatLng? location, // Updated type for copyWith
    Timestamp? createdAt, // Updated type for copyWith
  }) {
    return Caretaker(
      id: id ?? this.id,
      authId: authId ?? this.authId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      location: location ?? this.location, // Copy LatLng
      createdAt: createdAt ?? this.createdAt, // Copy Timestamp
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    'authId': authId,
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    // Firestore natively understands LatLng, no manual conversion needed here!
    'location': location,
    // Firestore natively understands Timestamp
    'createdAt': createdAt,
  };

  // This toJson method is typically for serializing to standard JSON (like for APIs)
  // For Firestore, toMap() is what's used.
  // I've updated it to represent LatLng and Timestamp in a JSON-friendly way.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authId': authId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'location': { // Represent LatLng as an object in JSON
         'latitude': location.latitude,
         'longitude': location.longitude,
      },
      'createdAt': createdAt.toDate().toIso8601String(), // Convert Timestamp back to ISO string for JSON
    };
  }

  // Factory method to create a Caretaker from a Firestore DocumentSnapshot
  factory Caretaker.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?; // Use nullable map for safety
    if (data == null) {
       // Handle the case where the document doesn't exist or is empty
       // You might throw an error or return a default/null value depending on your BaseModel
       throw StateError('Document data is null for ID ${doc.id}');
    }
    return Caretaker.fromMap(doc.id, data);
  }

  // Factory method to create a Caretaker from a map (useful for testing or other sources)
  factory Caretaker.fromMap(String id, Map<String, dynamic> map) {
    // Safely retrieve LatLng and Timestamp from the map
    final LatLng retrievedLocation = map['location'] is LatLng
        ? map['location'] as LatLng
        : LatLng(0, 0); // Provide a default or handle error if location is missing/wrong type

    final Timestamp retrievedTimestamp = map['createdAt'] is Timestamp
        ? map['createdAt'] as Timestamp
        : Timestamp.now(); // Provide a default or handle error if createdAt is missing/wrong type

    return Caretaker(
      id: id,
      authId: map['authId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      location: retrievedLocation,
      createdAt: retrievedTimestamp,
    );
  }
}
