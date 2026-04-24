import 'package:autism_care_management_application/utils/base_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NutritionTimetable extends FirestoreModel {
  final String id; // Format: C001N001, C001N002, etc. (caretakerId + N + number)
  final String caretakerId; // Now using caretakerId instead of companyId (C001)
  final String mealName;
  final String description;
  final DateTime date;
  final TimeOfDay time;
  final List<String> childIds; // List of child IDs participating
  final DateTime createdAt;

  NutritionTimetable({
    required this.id,
    required this.caretakerId,
    required this.mealName,
    required this.description,
    required this.date,
    required this.time,
    required this.childIds,
    required this.createdAt,
  });

  NutritionTimetable copyWith({
    String? id,
    String? caretakerId,
    String? mealName,
    String? description,
    DateTime? date,
    TimeOfDay? time,
    List<String>? childIds,
    DateTime? createdAt,
  }) {
    return NutritionTimetable(
      id: id ?? this.id,
      caretakerId: caretakerId ?? this.caretakerId,
      mealName: mealName ?? this.mealName,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      childIds: childIds ?? this.childIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caretakerId': caretakerId,
      'mealName': mealName,
      'description': description,
      'date': date.toIso8601String(),
      'time': {'hour': time.hour, 'minute': time.minute},
      'childIds': childIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'caretakerId': caretakerId,
      'mealName': mealName,
      'description': description,
      'date': date.toIso8601String(),
      'time': '${time.hour}:${time.minute}',
      'childIds': childIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NutritionTimetable.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NutritionTimetable.fromMap(doc.id, data);
  }

  factory NutritionTimetable.fromMap(String id, Map<String, dynamic> map) {
    final timeParts = (map['time'] as String).split(':');

    return NutritionTimetable(
      id: id,
      caretakerId: map['caretakerId'] ?? '',
      mealName: map['mealName'] ?? '',
      description: map['description'] ?? '',
      date: DateTime.parse(map['date']),
      time: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      childIds: List<String>.from(map['childIds'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
