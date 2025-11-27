import 'package:cloud_firestore/cloud_firestore.dart';

class StaffMember {
  final String id;
  final String caretakerId;
  final String name;
  final Timestamp dob;
  final String email;
  final Timestamp? createdAt; 

  StaffMember({
    required this.id,
    required this.caretakerId,
    required this.name,
    required this.dob,
    required this.email,
    this.createdAt,
  });

  // Copy with modification
  StaffMember copyWith({
    String? id,
    String? caretakerId,
    String? name,
    Timestamp? dob, // Changed to Timestamp?
    String? email,
    Timestamp? createdAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      caretakerId: caretakerId ?? this.caretakerId,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      email: email ?? this.email,
      createdAt: createdAt,
    );
  }

  // Convert to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'caretakerId': caretakerId,
      'name': name,
      'dob': dob, // No conversion needed as it's already Timestamp
      'email': email,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  // Create from Firestore Document
  factory StaffMember.fromMap(String id, Map<String, dynamic> map) {
    return StaffMember(
      id: id,
      caretakerId: map['caretakerId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      dob: map['dob'] as Timestamp? ?? Timestamp.now(), // Default to now if null
      email: map['email'] as String? ?? '',
      createdAt: map['createdAt'] as Timestamp?,
    );
  }

  // Convert to JSON (for APIs)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caretakerId': caretakerId,
      'name': name,
      'dob': dob.toDate().toIso8601String(), // Convert Timestamp to ISO string for JSON
      'email': email,
      'createdAt': createdAt?.toDate().toIso8601String(), // Convert Timestamp to ISO string for JSON
    };
  }

  // Create from JSON (for APIs)
  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] as String? ?? '',
      caretakerId: json['caretakerId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      dob: Timestamp.fromDate(DateTime.parse(json['dob'] as String? ?? DateTime.now().toIso8601String())), // Parse string to DateTime, then to Timestamp
      email: json['email'] as String? ?? '',
      createdAt: json['createdAt'] != null ? Timestamp.fromDate(DateTime.parse(json['createdAt'] as String)) : null, // Parse string to DateTime, then to Timestamp
    );
  }

  // Helper to calculate age
  int get age {
    final now = Timestamp.now().toDate(); // Convert current Timestamp to DateTime for comparison
    final birthDate = dob.toDate(); // Convert dob Timestamp to DateTime
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Formatted date string
  String get formattedDob {
    final birthDate = dob.toDate(); // Convert dob Timestamp to DateTime for formatting
    return '${birthDate.day}/${birthDate.month}/${birthDate.year}';
  }

  // Validation
  bool get isValid {
    final now = Timestamp.now().toDate(); // Convert current Timestamp to DateTime for comparison
    final birthDate = dob.toDate(); // Convert dob Timestamp to DateTime
    return name.isNotEmpty &&
        email.isNotEmpty &&
        email.contains('@') &&
        birthDate.isBefore(now);
  }
}