import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String reviewId;
  final String parentType; // 'venue' or 'show'
  final String parentId;
  final String authorUid;
  final String authorDisplayName;
  final String authorAvatarUrl;
  final int rating;
  final String text;
  final int reportCount;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReviewModel({
    required this.reviewId,
    required this.parentType,
    required this.parentId,
    required this.authorUid,
    required this.authorDisplayName,
    this.authorAvatarUrl = '',
    required this.rating,
    this.text = '',
    this.reportCount = 0,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      reviewId: doc.id,
      parentType: data['parentType'] ?? 'venue',
      parentId: data['parentId'] ?? '',
      authorUid: data['authorUid'] ?? '',
      authorDisplayName: data['authorDisplayName'] ?? '',
      authorAvatarUrl: data['authorAvatarUrl'] ?? '',
      rating: data['rating'] ?? 0,
      text: data['text'] ?? '',
      reportCount: data['reportCount'] ?? 0,
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'parentType': parentType,
        'parentId': parentId,
        'authorUid': authorUid,
        'authorDisplayName': authorDisplayName,
        'authorAvatarUrl': authorAvatarUrl,
        'rating': rating,
        'text': text,
        'reportCount': reportCount,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}