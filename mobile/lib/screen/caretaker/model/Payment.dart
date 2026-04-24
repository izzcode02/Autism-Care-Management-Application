import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String caretakerId;
  final String caretakerName;
  final String parentId; 
  final String parentName;
  final String childId; 
  final String childName;
  final double amount;
  String status; // "Pending", "Paid", "Overdue", "Cancelled"
  final DateTime dueDate;
  final DateTime? paymentDate; // Added payment date for tracking
  final String? receiptUrl; // Added for payment proof
  final String? notes; // Added for admin notes

  Payment({
    required this.id,
    required this.caretakerId,
    required this.caretakerName,
    required this.parentId,
    required this.parentName,
    required this.childId,
    required this.childName,
    required this.amount,
    required this.status,
    required this.dueDate,
    this.paymentDate,
    this.receiptUrl,
    this.notes,
  });

  Payment copyWith({
    String? id,
    String? caretakerId,
    String? caretakerName,
    String? parentId,
    String? parentName,
    String? childId,
    String? childName,
    double? amount,
    String? status,
    DateTime? dueDate,
    DateTime? paymentDate,
    String? receiptUrl,
    String? notes,
  }) {
    return Payment(
      id: id ?? this.id,
      caretakerId: caretakerId ?? this.caretakerId,
      caretakerName: caretakerName ?? this.caretakerName,
      parentId: parentId ?? this.parentId,
      parentName: parentName ?? this.parentName,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      paymentDate: paymentDate ?? this.paymentDate,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      notes: notes ?? this.notes,
    );
  }

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Payment(
      id: doc.id,
      caretakerId: data['caretakerId'] ?? '',
      caretakerName: data['caretakerName'] ?? '',
      parentId: data['parentId'] ?? '',
      parentName: data['parentName'] ?? '',
      childId: data['childId'] ?? '',
      childName: data['childName'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Pending',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      paymentDate: data['paymentDate'] != null 
          ? (data['paymentDate'] as Timestamp).toDate() 
          : null,
      receiptUrl: data['receiptUrl'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'caretakerId': caretakerId,
      'caretakerName': caretakerName,
      'parentId': parentId,
      'parentName': parentName,
      'childId': childId,
      'childName': childName,
      'amount': amount,
      'status': status,
      'dueDate': Timestamp.fromDate(dueDate),
      if (paymentDate != null) 'paymentDate': Timestamp.fromDate(paymentDate!),
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
      if (notes != null) 'notes': notes,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caretakerId': caretakerId,
      'caretakerName': caretakerName,
      'parentId': parentId,
      'parentName': parentName,
      'childId': childId,
      'childName': childName,
      'amount': amount,
      'status': status,
      'dueDate': dueDate.toIso8601String(),
      'paymentDate': paymentDate?.toIso8601String(),
      'receiptUrl': receiptUrl,
      'notes': notes,
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      caretakerId: json['caretakerId'],
      caretakerName: json['caretakerName'],
      parentId: json['parentId'],
      parentName: json['parentName'],
      childId: json['childId'],
      childName: json['childName'],
      amount: json['amount'].toDouble(),
      status: json['status'],
      dueDate: DateTime.parse(json['dueDate']),
      paymentDate: json['paymentDate'] != null 
          ? DateTime.parse(json['paymentDate']) 
          : null,
      receiptUrl: json['receiptUrl'],
      notes: json['notes'],
    );
  }

  @override
  String toString() {
    return 'Payment(id: $id, caretakerId: $caretakerId, caretakerName: $caretakerName, '
        'parentId: $parentId, parentName: $parentName, '
        'childId: $childId, childName: $childName, amount: $amount, '
        'status: $status, dueDate: $dueDate, paymentDate: $paymentDate, '
        'receiptUrl: $receiptUrl, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Payment &&
        other.id == id &&
        other.caretakerId == caretakerId &&
        other.caretakerName == caretakerName &&
        other.parentId == parentId &&
        other.parentName == parentName &&
        other.childId == childId &&
        other.childName == childName &&
        other.amount == amount &&
        other.status == status &&
        other.dueDate == dueDate &&
        other.paymentDate == paymentDate &&
        other.receiptUrl == receiptUrl &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        caretakerId.hashCode ^
        caretakerName.hashCode ^
        parentId.hashCode ^
        parentName.hashCode ^
        childId.hashCode ^
        childName.hashCode ^
        amount.hashCode ^
        status.hashCode ^
        dueDate.hashCode ^
        paymentDate.hashCode ^
        receiptUrl.hashCode ^
        notes.hashCode;
  }
}