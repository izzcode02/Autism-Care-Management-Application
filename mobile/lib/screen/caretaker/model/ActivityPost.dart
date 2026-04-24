import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ActivityPost {
  final String id;
  final String caretakerId;
  final String staffId;
  final String staffName;
  final String title;
  final String description;
  final File? image;
  final String? imageUrl; // For storing the download URL from Firebase Storage
  final Timestamp dateTime;
  final Timestamp createdAt;

  ActivityPost({
    required this.id,
    required this.caretakerId,
    required this.staffId,
    required this.staffName,
    required this.title,
    required this.description,
    this.image,
    this.imageUrl,
    required this.dateTime,
    Timestamp? createdAt,
  }) : createdAt = createdAt ?? Timestamp.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caretakerId': caretakerId,
      'staffId': staffId,
      'staffName': staffName,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'dateTime': dateTime.millisecondsSinceEpoch, // Convert to milliseconds
      'createdAt': createdAt.millisecondsSinceEpoch, // Convert to milliseconds
    };
  }

  // Convert to Firestore Map (excluding File since it can't be directly stored)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'caretakerId': caretakerId,
      'staffId': staffId,
      'staffName': staffName,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'dateTime': dateTime,
      'createdAt': createdAt,
    };
  }

  // Create from Firestore Document
  factory ActivityPost.fromMap(String docId, Map<String, dynamic> map) {
    return ActivityPost(
      id: docId,
      caretakerId: map['caretakerId'] as String,
      staffId: map['staffId'] as String,
      staffName: map['staffName'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      imageUrl: map['imageUrl'] as String?,
      dateTime: map['dateTime'] as Timestamp,
      createdAt: map['createdAt'] as Timestamp,
    );
  }

  // Create a copy with modified fields
  ActivityPost copyWith({
    String? id,
    String? caretakerId,
    String? staffId,
    String? staffName,
    String? title,
    String? description,
    File? image,
    String? imageUrl,
    Timestamp? dateTime,
    Timestamp? createdAt,
  }) {
    return ActivityPost(
      id: id ?? this.id,
      caretakerId: caretakerId ?? this.caretakerId,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      imageUrl: imageUrl ?? this.imageUrl,
      dateTime: dateTime ?? this.dateTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Formatted date for display
  String get formattedDate {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime.toDate());
  }

  // Formatted creation date for display
  String get formattedCreatedAt {
    return DateFormat('MMM dd, yyyy').format(createdAt.toDate());
  }

  // Validation method
  bool get isValid {
    return title.isNotEmpty &&
        description.isNotEmpty &&
        caretakerId.isNotEmpty &&
        staffId.isNotEmpty &&
        staffName.isNotEmpty;
  }

  // Check if post has an image (either local or uploaded)
  bool get hasImage {
    return image != null || imageUrl != null;
  }
}
