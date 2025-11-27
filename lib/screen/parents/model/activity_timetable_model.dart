import 'package:autism_care_management_application/utils/base_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ActivityTimetable extends FirestoreModel {
  final String id;
  final String caretakerId;
  final String activityName;
  final String description;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<String> childIds;
  final DateTime createdAt;

  ActivityTimetable({
    required this.id,
    required this.caretakerId,
    required this.activityName,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.childIds,
    required this.createdAt,
  });

  ActivityTimetable copyWith({
    String? id,
    String? caretakerId,
    String? activityName,
    String? description,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<String>? childIds,
    DateTime? createdAt,
  }) {
    return ActivityTimetable(
      id: id ?? this.id,
      caretakerId: caretakerId ?? this.caretakerId,
      activityName: activityName ?? this.activityName,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      childIds: childIds ?? this.childIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caretakerId': caretakerId,
      'activityName': activityName,
      'description': description,
      'date': date.toIso8601String(),
      'startTime': {'hour': startTime.hour, 'minute': startTime.minute},
      'endTime': {'hour': endTime.hour, 'minute': endTime.minute},
      'childIds': childIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'caretakerId': caretakerId,
      'activityName': activityName,
      'description': description,
      'date': date.toIso8601String(),
      'startTime': '${startTime.hour}:${startTime.minute}',
      'endTime': '${endTime.hour}:${endTime.minute}',
      'childIds': childIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ActivityTimetable.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityTimetable.fromMap(doc.id, data);
  }

  factory ActivityTimetable.fromMap(String id, Map<String, dynamic> map) {
    final startTimeParts = (map['startTime'] as String).split(':');
    final endTimeParts = (map['endTime'] as String).split(':');

    return ActivityTimetable(
      id: id,
      caretakerId: map['caretakerId'] ?? '',
      activityName: map['activityName'] ?? '',
      description: map['description'] ?? '',
      date: DateTime.parse(map['date']),
      startTime: TimeOfDay(
        hour: int.parse(startTimeParts[0]),
        minute: int.parse(startTimeParts[1]),
      ),
      endTime: TimeOfDay(
        hour: int.parse(endTimeParts[0]),
        minute: int.parse(endTimeParts[1]),
      ),
      childIds: List<String>.from(map['childIds'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
