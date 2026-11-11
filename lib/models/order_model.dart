// lib/models/order_model.dart

import '../utils/constants.dart';

class CommentModel {
  final String id;
  final String authorName;
  final String text;
  final DateTime timestamp;
  final UserRole authorRole;

  CommentModel({
    required this.id,
    required this.authorName,
    required this.text,
    required this.timestamp,
    required this.authorRole,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      authorName: json['authorName'] ?? '',
      text: json['text'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      authorRole: json['authorRole'] == 'technician'
          ? UserRole.technician
          : UserRole.dentist,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'authorRole':
          authorRole == UserRole.technician ? 'technician' : 'dentist',
    };
  }
}

class OrderModel {
  final String id;
  final String dentistId;
  final String dentistName;
  final String? labId;
  final String? labName;
  final String caseDescription;
  final List<String> fileUrls;
  final List<String> fileNames;
  OrderStatus status;
  final DateTime createdAt;
  DateTime? updatedAt;
  DateTime? estimatedDeliveryDate;
  bool isUrgent;
  final List<CommentModel> comments;
  String? revisionNote;

  OrderModel({
    required this.id,
    required this.dentistId,
    required this.dentistName,
    this.labId,
    this.labName,
    required this.caseDescription,
    this.fileUrls = const [],
    this.fileNames = const [],
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.updatedAt,
    this.estimatedDeliveryDate,
    this.isUrgent = false,
    this.comments = const [],
    this.revisionNote,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      dentistId: json['dentistId'] ?? '',
      dentistName: json['dentistName'] ?? '',
      labId: json['labId'],
      labName: json['labName'],
      caseDescription: json['caseDescription'] ?? '',
      fileUrls: List<String>.from(json['fileUrls'] ?? const []),
      fileNames: List<String>.from(json['fileNames'] ?? const []),
      status: OrderStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
      estimatedDeliveryDate: json['estimatedDeliveryDate'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['estimatedDeliveryDate']),
      isUrgent: json['isUrgent'] ?? false,
      comments: (json['comments'] as List<dynamic>? ?? const [])
          .map((item) => CommentModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      revisionNote: json['revisionNote'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dentistId': dentistId,
      'dentistName': dentistName,
      'labId': labId,
      'labName': labName,
      'caseDescription': caseDescription,
      'fileUrls': fileUrls,
      'fileNames': fileNames,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'estimatedDeliveryDate': estimatedDeliveryDate?.millisecondsSinceEpoch,
      'isUrgent': isUrgent,
      'comments': comments.map((comment) => comment.toJson()).toList(),
      'revisionNote': revisionNote,
    };
  }

  bool get canBeCancelled =>
      status == OrderStatus.pending || status == OrderStatus.accepted;

  bool get canBeModified =>
      status == OrderStatus.pending || status == OrderStatus.awaitingRevision;
}
