import 'package:cloud_firestore/cloud_firestore.dart';

class VenueClaimModel {
  final String id;
  final String userId;
  final String venueId;
  final String claimantName;
  final String claimantEmail;
  final String claimantRole;
  final String message;
  final String supportingInfo;
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewReason;

  const VenueClaimModel({
    required this.id,
    required this.userId,
    required this.venueId,
    required this.claimantName,
    required this.claimantEmail,
    required this.claimantRole,
    required this.message,
    this.supportingInfo = '',
    this.status = 'pending',
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewReason,
  });

  factory VenueClaimModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VenueClaimModel(
      id: doc.id,
      userId: (data['userId'] ?? data['user_id'] ?? '').toString(),
      venueId: (data['venueId'] ?? data['venue_id'] ?? '').toString(),
      claimantName:
          (data['claimantName'] ?? data['claimant_name'] ?? '').toString(),
      claimantEmail:
          (data['claimantEmail'] ?? data['claimant_email'] ?? '').toString(),
      claimantRole:
          (data['claimantRole'] ?? data['claimant_role'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
      supportingInfo:
          (data['supportingInfo'] ?? data['supporting_info'] ?? '').toString(),
      status: (data['status'] ?? 'pending').toString(),
      submittedAt: (data['submittedAt'] as Timestamp? ??
                  data['submitted_at'] as Timestamp?)
              ?.toDate() ??
          DateTime.now(),
      reviewedAt: (data['reviewedAt'] as Timestamp? ??
              data['reviewed_at'] as Timestamp?)
          ?.toDate(),
      reviewedBy: (data['reviewedBy'] ?? data['reviewed_by'])?.toString(),
      reviewReason: (data['reviewReason'] ?? data['review_reason'])?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'venueId': venueId,
        'claimantName': claimantName,
        'claimantEmail': claimantEmail,
        'claimantRole': claimantRole,
        'message': message,
        'supportingInfo': supportingInfo,
        'status': status,
        'submittedAt': Timestamp.fromDate(submittedAt),
        'reviewedAt':
            reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
        'reviewedBy': reviewedBy,
        'reviewReason': reviewReason,
      };
}
