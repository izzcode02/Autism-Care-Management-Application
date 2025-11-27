import 'package:autism_care_management_application/utils/base_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Parent extends FirestoreModel {
  final String id;
  final String authId;
  final String name;
  final String email;
  final String? phone;
  final String? occupation;
  final String? employerAddress;
  final double? monthlyIncome;
  final String? maritalStatus;
  final DateTime createdAt;

  Parent({
    required this.id,
    required this.authId,
    required this.name,
    required this.email,
    this.phone,
    this.occupation,
    this.employerAddress,
    this.monthlyIncome,
    this.maritalStatus,
    required this.createdAt,
  });

  Parent copyWith({
    String? id,
    String? authId,
    String? name,
    String? email,
    String? phone,
    String? occupation,
    String? employerAddress,
    double? monthlyIncome,
    String? maritalStatus,
    DateTime? createdAt,
  }) {
    return Parent(
      id: id ?? this.id,
      authId: authId ?? this.authId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      occupation: occupation ?? this.occupation,
      employerAddress: employerAddress ?? this.employerAddress,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'authId': authId,
      'name': name,
      'email': email,
      'phone': phone,
      'occupation': occupation,
      'employerAddress': employerAddress,
      'monthlyIncome': monthlyIncome,
      'maritalStatus': maritalStatus,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authId': authId,
      'name': name,
      'email': email,
      'phone': phone,
      'occupation': occupation,
      'employerAddress': employerAddress,
      'monthlyIncome': monthlyIncome,
      'maritalStatus': maritalStatus,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Parent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Parent.fromMap(doc.id, data);
  }

  factory Parent.fromMap(String id, Map<String, dynamic> map) {
    return Parent(
      id: id,
      authId: map['authId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      occupation: map['occupation'],
      employerAddress: map['employerAddress'],
      monthlyIncome: map['monthlyIncome']?.toDouble(),
      maritalStatus: map['maritalStatus'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  factory Parent.fromJson(Map<String, dynamic> json) {
    return Parent(
      id: json['id'] as String,
      authId: json['authId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      occupation: json['occupation'] as String?,
      employerAddress: json['employerAddress'] as String?,
      monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble(),
      maritalStatus: json['maritalStatus'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
