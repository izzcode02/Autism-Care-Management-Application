class Users {
  String uid;
  String name;
  String email;
  String? roles;

  Users({
    required this.uid,
    required this.name,
    required this.email,
    this.roles,
  });

  // Convert Firestore JSON to UserModel
  factory Users.fromJson(Map<String, dynamic> json) {
    return Users(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      roles: json['roles'],
    );
  }

  // Convert UserModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {"uid": uid, "name": name, "email": email, "roles": roles};
  }

  bool get isParent => roles == 'Parent';
  bool get isCaretaker => roles == 'Caretaker';
}
