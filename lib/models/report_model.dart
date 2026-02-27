import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String reporterUserId;
  final String entityType; // 'venue' | 'show'
  final String entityId;
  final String reasonCategory;
  final String reason;
  final String status; // 'open' | 'resolved' | 'dismissed'
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  const ReportModel({
    required this.id,
    required this.reporterUserId,
    required this.entityType,
    required this.entityId,
    required this.reasonCategory,
    required this.reason,
    this.status = 'open',
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      reporterUserId:
          (data['reporterUserId'] ?? data['reporter_user_id'] ?? '').toString(),
      entityType:
          (data['entityType'] ?? data['entity_type'] ?? 'venue').toString(),
      entityId: (data['entityId'] ?? data['entity_id'] ?? '').toString(),
      reasonCategory:
          (data['reasonCategory'] ?? data['reason_category'] ?? 'other')
              .toString(),
      reason: (data['reason'] ?? '').toString(),
      status: (data['status'] ?? 'open').toString(),
      createdAt:
          (data['createdAt'] as Timestamp? ?? data['created_at'] as Timestamp?)
                  ?.toDate() ??
              DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp? ??
              data['resolved_at'] as Timestamp?)
          ?.toDate(),
      resolvedBy: (data['resolvedBy'] ?? data['resolved_by'])?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'reporterUserId': reporterUserId,
        'entityType': entityType,
        'entityId': entityId,
        'reasonCategory': reasonCategory,
        'reason': reason,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
        'resolvedAt':
            resolvedAt == null ? null : Timestamp.fromDate(resolvedAt!),
        'resolvedBy': resolvedBy,
      };
}
