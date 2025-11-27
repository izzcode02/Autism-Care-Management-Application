// caretaker_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:autism_care_management_application/utils/base_model.dart';

class Caretaker extends FirestoreModel {
  @override
  final String id;
  final String authId;
  final String name;
  final String email;
  final String phone;
  final String address;
  final LatLng location;
  final Timestamp createdAt;
  final String specialization;
  final String description;
  final double rating;
  final int experience;
  final List<String> services;

  Caretaker({
    required this.id,
    required this.authId,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.location,
    required this.createdAt,
    this.specialization = '',
    this.description = '',
    this.rating = 0.0,
    this.experience = 0,
    this.services = const [],
  });

  Caretaker copyWith({
    String? id,
    String? authId,
    String? name,
    String? email,
    String? phone,
    String? address,
    LatLng? location,
    Timestamp? createdAt,
    String? specialization,
    String? description,
    double? rating,
    int? experience,
    List<String>? services,
  }) {
    return Caretaker(
      id: id ?? this.id,
      authId: authId ?? this.authId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      specialization: specialization ?? this.specialization,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      experience: experience ?? this.experience,
      services: services ?? this.services,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'authId': authId,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'location': GeoPoint(location.latitude, location.longitude),
        'createdAt': createdAt,
        'specialization': specialization,
        'description': description,
        'rating': rating,
        'experience': experience,
        'services': services,
      };

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authId': authId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'createdAt': createdAt.toDate().toIso8601String(),
      'specialization': specialization,
      'description': description,
      'rating': rating,
      'experience': experience,
      'services': services,
    };
  }

  factory Caretaker.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('Document data is null for ID ${doc.id}');
    }
    return Caretaker.fromMap(doc.id, data);
  }

  factory Caretaker.fromMap(String id, Map<String, dynamic> map) {
    LatLng retrievedLocation;
    final dynamic locationData = map['location'];

    if (locationData is GeoPoint) {
      retrievedLocation = LatLng(locationData.latitude, locationData.longitude);
    } else if (locationData is Map<String, dynamic> &&
        locationData.containsKey('latitude') &&
        locationData.containsKey('longitude')) {
      retrievedLocation = LatLng(
        (locationData['latitude'] as num).toDouble(),
        (locationData['longitude'] as num).toDouble(),
      );
    } else {
      retrievedLocation = LatLng(0, 0); // Default
      print('Warning: Invalid location format in Firestore document $id');
    }

    final Timestamp retrievedTimestamp = map['createdAt'] is Timestamp
        ? map['createdAt'] as Timestamp
        : Timestamp.now();

    // Handle services list
    List<String> services = [];
    if (map['services'] != null) {
      services = List<String>.from(map['services']);
    }

    return Caretaker(
      id: id,
      authId: map['authId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      location: retrievedLocation,
      createdAt: retrievedTimestamp,
      specialization: map['specialization'] ?? '',
      description: map['description'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      experience: (map['experience'] ?? 0) as int,
      services: services,
    );
  }

  @override
  String toString() {
    return 'Caretaker(id: $id, name: $name, specialization: $specialization)';
  }
}
