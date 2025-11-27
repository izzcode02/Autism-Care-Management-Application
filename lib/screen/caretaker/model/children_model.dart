import 'package:autism_care_management_application/utils/base_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Child extends FirestoreModel {
  @override
  final String id;
  final String parentId;
  final String caretakerId;
  final String name;
  final String myKid;
  final num age;
  final String address;
  final DateTime birthDate;
  final String race;
  final String religion;
  final String citizenship;
  final String custodyStatus;
  final String? otherCustody; // Only required if custodyStatus is "Lain-lain"
  final bool hasAttendedCenter;
  final String autismType;
  final String? autismCentreName; // New field
  final DateTime createdAt;

  Child({
    required this.id,
    required this.parentId,
    required this.caretakerId,
    required this.name,
    required this.myKid,
    required this.age,
    required this.address,
    required this.birthDate,
    required this.race,
    required this.religion,
    required this.citizenship,
    required this.custodyStatus,
    this.otherCustody,
    required this.hasAttendedCenter,
    required this.autismType,
    this.autismCentreName, // New field
    required this.createdAt,
  });

  Child copyWith({
    String? id,
    String? parentId,
    String? caretakerId,
    String? name,
    String? myKid,
    num? age,
    String? address,
    DateTime? birthDate,
    String? race,
    String? religion,
    String? citizenship,
    String? custodyStatus,
    String? otherCustody,
    bool? hasAttendedCenter,
    String? autismType,
    String? autismCentreName, // New field in copyWith
    DateTime? createdAt,
  }) {
    return Child(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      caretakerId: caretakerId ?? this.caretakerId,
      name: name ?? this.name,
      myKid: myKid ?? this.myKid,
      age: age ?? this.age,
      address: address ?? this.address,
      birthDate: birthDate ?? this.birthDate,
      race: race ?? this.race,
      religion: religion ?? this.religion,
      citizenship: citizenship ?? this.citizenship,
      custodyStatus: custodyStatus ?? this.custodyStatus,
      otherCustody: otherCustody ?? this.otherCustody,
      hasAttendedCenter: hasAttendedCenter ?? this.hasAttendedCenter,
      autismType: autismType ?? this.autismType,
      autismCentreName: autismCentreName ?? this.autismCentreName, // New field
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'parentId': parentId,
        'caretakerId': caretakerId,
        'name': name,
        'myKidNumber': myKid,
        'age': age,
        'address': address,
        'birthDate': birthDate.toIso8601String(),
        'race': race,
        'religion': religion,
        'citizenship': citizenship,
        'custodyStatus': custodyStatus,
        if (otherCustody != null) 'otherCustody': otherCustody,
        'hasAttendedCenter': hasAttendedCenter,
        'autismType': autismType,
        if (autismCentreName != null)
          'autismCentreName': autismCentreName, // New field
        'createdAt': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'caretakerId': caretakerId,
      'name': name,
      'myKidNumber': myKid,
      'age': age,
      'address': address,
      'birthDate': birthDate.toIso8601String(),
      'race': race,
      'religion': religion,
      'citizenship': citizenship,
      'custodyStatus': custodyStatus,
      if (otherCustody != null) 'otherCustody': otherCustody,
      'hasAttendedCenter': hasAttendedCenter,
      'autismType': autismType,
      if (autismCentreName != null)
        'autismCentreName': autismCentreName, // New field
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Child.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Child.fromMap(doc.id, data);
  }

  factory Child.fromMap(String id, Map<String, dynamic> map) => Child(
        id: id,
        parentId: map['parentId'] ?? '',
        caretakerId: map['caretakerId'] ?? '',
        name: map['name'] ?? '',
        myKid:
            map['myKid'] ?? map['myKidNumber'] ?? '', // Handle both field names
        age: map['age'] ?? 0, // Default to 0 instead of empty string
        address: map['address'] ?? '',
        birthDate: DateTime.parse(map['birthDate']),
        race: map['race'] ?? '',
        religion: map['religion'] ?? '',
        citizenship: map['citizenship'] ?? '',
        custodyStatus: map['custodyStatus'] ?? '',
        otherCustody: map['otherCustody'],
        hasAttendedCenter: map['hasAttendedCenter'] ?? false,
        autismType: map['autismType'] ?? '',
        autismCentreName: map['autismCentreName'], // New field
        createdAt: DateTime.parse(map['createdAt']),
      );

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] as String? ?? '',
      parentId: json['parentId'] as String? ?? '',
      caretakerId: json['caretakerId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      // Handle different field names (myKid vs myKidNumber)
      myKid: json['myKid'] as String? ?? json['myKidNumber'] as String? ?? '',
      age: json['age'] as num? ?? 0,
      address: json['address'] as String? ?? '',
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : DateTime.now(),
      race: json['race'] as String? ?? '',
      religion: json['religion'] as String? ?? '',
      citizenship: json['citizenship'] as String? ?? '',
      custodyStatus: json['custodyStatus'] as String? ?? '',
      otherCustody: json['otherCustody'] as String?,
      hasAttendedCenter: json['hasAttendedCenter'] as bool? ?? false,
      autismType: json['autismType'] as String? ?? '',
      autismCentreName: json['autismCentreName'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
