import 'package:autism_care_management_application/screen/caretaker/model/children_model.dart';
import 'package:autism_care_management_application/screen/caretaker/model/parents_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Approval {
  final String? applyId;
  final String? applyStatus;
  final Child? childInfo;
  final Parent? parentInfo;
  final Timestamp? requestDate;

  Approval({
    this.applyId,
    this.applyStatus,
    this.childInfo,
    this.parentInfo,
    this.requestDate,
  });

  factory Approval.fromJson(Map<String, dynamic>? json) {
    // Handle null JSON input
    if (json == null) {
      return Approval();
    }

    // Safe parsing with null checks and type conversion
    try {
      return Approval(
        applyId: _parseString(json['applyId']),
        applyStatus: _parseString(json['applyStatus']),
        childInfo: _parseChild(json['childInfo']),
        parentInfo: _parseParent(
          json['parentsInfo'],
        ), // Note: matches your data's 'parentsInfo' key
        requestDate:
            json['requestDate'] is Timestamp
                ? json['requestDate'] as Timestamp?
                : null,
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing Approval: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Problematic JSON: $json');
      return Approval(); // Return empty object or handle differently
    }
  }

  // Helper methods for safe parsing
  static String? _parseString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static Child? _parseChild(dynamic childData) {
    if (childData == null || childData is! Map<String, dynamic>) return null;
    try {
      return Child.fromJson(childData);
    } catch (e) {
      debugPrint('Error parsing Child: $e');
      return null;
    }
  }

  static Parent? _parseParent(dynamic parentData) {
    if (parentData == null || parentData is! Map<String, dynamic>) return null;
    try {
      return Parent.fromJson(parentData);
    } catch (e) {
      debugPrint('Error parsing Parent: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'applyId': applyId,
      'applyStatus': applyStatus,
      'childInfo': childInfo?.toJson(),
      'parentsInfo':
          parentInfo?.toJson(), // Consistent with your data structure
      'requestDate': requestDate,
    };
  }
}
