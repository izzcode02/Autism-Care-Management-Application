import 'package:cloud_firestore/cloud_firestore.dart';

class Users {
  final String uid;
  final String name;
  final String email;

  Users({
    required this.uid,
    required this.name,
    required this.email,
  });

  factory Users.fromJson(Map<String, dynamic> json, String id) {
    return Users(
      uid: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  factory Users.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Users(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
    );
  }

   Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
    };
  }

 Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
    };
  }
}