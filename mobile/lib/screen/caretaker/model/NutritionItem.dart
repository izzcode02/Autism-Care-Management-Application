import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NutritionItem {
  String id;
  TimeOfDay startTime;
  TimeOfDay endTime;
  String mealName;
  String mealDescription;

  NutritionItem({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.mealName,
    required this.mealDescription,
  });

  // Factory constructor to create ActivityItem from Firestore data
  factory NutritionItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convert Firebase Timestamp to DateTime, then to TimeOfDay
    final startTimeMap = data['startTime'] as Map<String, dynamic>;
    final endTimeMap = data['endTime'] as Map<String, dynamic>;
    
    return NutritionItem(
      id: doc.id,
      startTime: TimeOfDay(hour: startTimeMap['hour'], minute: startTimeMap['minute']),
      endTime: TimeOfDay(hour: endTimeMap['hour'], minute: endTimeMap['minute']),
      mealName: data['mealName'] ?? '',
      mealDescription: data['mealDescription'] ?? '',
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
      'mealName': mealName,
      'mealDescription': mealDescription,
      'date': Timestamp.fromDate(DateTime.now()),
    };
  }
}