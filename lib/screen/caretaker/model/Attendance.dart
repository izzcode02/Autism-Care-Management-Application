import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceRecord {
  final String id;
  final String childId;
  final String childName;
  final String parentId;
  final String parentName;
  final String clockIn;
  final String clockOut;
  final String date;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AttendanceRecord({
    required this.id,
    required this.childId,
    required this.childName,
    required this.parentId,
    required this.parentName,
    required this.clockIn,
    required this.clockOut,
    required this.date,
    required this.createdAt,
    this.updatedAt,
  });

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceRecord(
      id: doc.id,
      childId: data['childId'] ?? '',
      childName: data['childName'] ?? '',
      parentId: data['parentId'] ?? '',
      parentName: data['parentName'] ?? '',
      clockIn: data['clockIn'] ?? '',
      clockOut: data['clockOut'] ?? '',
      date: data['date'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'childName': childName,
      'parentId': parentId,
      'parentName': parentName,
      'clockIn': clockIn,
      'clockOut': clockOut,
      'date': date,
      'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  // Helper method to check if attendance is complete (both clock-in and clock-out)
  bool get isComplete => clockIn.isNotEmpty && clockOut.isNotEmpty;

  // Helper method to check if attendance is pending (only clocked in)
  bool get isPending => clockIn.isNotEmpty && clockOut.isEmpty;

  // Helper method to calculate duration between clock-in and clock-out
  Duration? get duration {
    if (!isComplete) return null;

    try {
      final inTime = TimeOfDay(
        hour: int.parse(clockIn.split(':')[0]),
        minute: int.parse(clockIn.split(':')[1]),
      );
      final outTime = TimeOfDay(
        hour: int.parse(clockOut.split(':')[0]),
        minute: int.parse(clockOut.split(':')[1]),
      );

      final inDateTime = DateTime(2000, 1, 1, inTime.hour, inTime.minute);
      final outDateTime = DateTime(2000, 1, 1, outTime.hour, outTime.minute);

      return outDateTime.difference(inDateTime);
    } catch (e) {
      return null;
    }
  }

  // Formatted duration string (e.g., "4 hours 30 minutes")
  String? get formattedDuration {
    final dur = duration;
    if (dur == null) return null;

    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '$hours hours $minutes minutes';
    } else if (hours > 0) {
      return '$hours hours';
    } else {
      return '$minutes minutes';
    }
  }

  // Copy with method for immutability
  AttendanceRecord copyWith({
    String? id,
    String? childId,
    String? childName,
    String? parentId,
    String? parentName,
    String? clockIn,
    String? clockOut,
    String? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      clockIn: clockIn ?? this.clockIn,
      clockOut: clockOut ?? this.clockOut,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AttendanceRecord{id: $id, childId: $childId, childName: $childName, '
        'parentId: $parentId, parentName: $parentName, clockIn: $clockIn, '
        'clockOut: $clockOut, date: $date, createdAt: $createdAt, '
        'updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          childId == other.childId &&
          date == other.date;

  @override
  int get hashCode => id.hashCode ^ childId.hashCode ^ date.hashCode;
}
