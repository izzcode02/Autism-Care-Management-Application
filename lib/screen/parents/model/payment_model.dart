import 'package:autism_care_management_application/utils/base_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Payment extends FirestoreModel {
  final String id; // Format: pay + timestamp + companyId (e.g., pay_1634567890_C001)
  final String caretakerId; // Now using caretakerId instead of companyId (C001)
  final String parentId; // P001
  final double amount;
  final String description;
  final DateTime paymentDate;
  final String status; // pending, completed, failed
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.caretakerId,
    required this.parentId,
    required this.amount,
    required this.description,
    required this.paymentDate,
    required this.status,
    required this.createdAt,
  });

  Payment copyWith({
    String? id,
    String? caretakerId,
    String? parentId,
    double? amount,
    String? description,
    DateTime? paymentDate,
    String? status,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      caretakerId: caretakerId ?? this.caretakerId,
      parentId: parentId ?? this.parentId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      paymentDate: paymentDate ?? this.paymentDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caretakerId': caretakerId,
      'parentId': parentId,
      'amount': amount,
      'description': description,
      'paymentDate': paymentDate.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'caretakerId': caretakerId,
      'parentId': parentId,
      'amount': amount,
      'description': description,
      'paymentDate': paymentDate.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Payment.fromMap(doc.id, data);
  }

  factory Payment.fromMap(String id, Map<String, dynamic> map) {
    return Payment(
      id: id,
      caretakerId: map['caretakerId'] ?? '',
      parentId: map['parentId'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] ?? '',
      paymentDate: DateTime.parse(map['paymentDate']),
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
