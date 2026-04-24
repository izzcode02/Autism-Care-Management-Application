import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityItem {
  String id;
  TimeOfDay startTime;
  TimeOfDay endTime;
  String task;
  String description;

  ActivityItem({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.task,
    required this.description,
  });

  // Factory constructor to create ActivityItem from Firestore data
  factory ActivityItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convert Firebase Timestamp to DateTime, then to TimeOfDay
    final startTimeMap = data['startTime'] as Map<String, dynamic>;
    final endTimeMap = data['endTime'] as Map<String, dynamic>;
    
    return ActivityItem(
      id: doc.id,
      startTime: TimeOfDay(hour: startTimeMap['hour'], minute: startTimeMap['minute']),
      endTime: TimeOfDay(hour: endTimeMap['hour'], minute: endTimeMap['minute']),
      task: data['task'] ?? '',
      description: data['description'] ?? '',
    );
  }

  // Convert ActivityItem to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'startTime': {
        'hour': startTime.hour,
        'minute': startTime.minute,
      },
      'endTime': {
        'hour': endTime.hour,
        'minute': endTime.minute,
      },
      'task': task,
      'description': description,
      'date': Timestamp.fromDate(DateTime.now()),
    };
  }
}