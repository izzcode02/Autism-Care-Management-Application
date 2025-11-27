import 'package:autism_care_management_application/screen/parents/model/children_model.dart';
import 'package:autism_care_management_application/screen/parents/model/parents_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Apply {
  final String applyId;
  final String applyStatus;
  final Child childInfo;
  final Parent parentInfo;
  final Timestamp requestDate;

  Apply({
    required this.applyId,
    required this.applyStatus,
    required this.childInfo,
    required this.parentInfo,
    required this.requestDate,
  });

  factory Apply.fromJson(Map<String, dynamic> json) {
    return Apply(
      applyId: json['applyId'] as String,
      applyStatus: json['applyStatus'] as String,
      childInfo: Child.fromJson(json['childInfo'] as Map<String, dynamic>),
      parentInfo: Parent.fromJson(json['parentsInfo'] as Map<String, dynamic>),
      requestDate: json['requestDate'] as Timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'applyId': applyId,
      'applyStatus': applyStatus,
      'childInfo': childInfo.toJson(),
      'parentsInfo': parentInfo.toJson(),
      'requestDate': requestDate,
    };
  }
}
