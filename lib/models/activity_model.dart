import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityModel {
  final String activityId;
  final String actorUid;
  final String actorDisplayName;
  final String actorAvatarUrl;
  final String type; // 'review_posted', 'show_created', 'venue_created', 'followed_user'
  final String targetType;
  final String targetId;
  final String targetName;
  final String snippet;
  final String recipientUid;
  final DateTime createdAt;

  const ActivityModel({
    required this.activityId,
    required this.actorUid,
    required this.actorDisplayName,
    this.actorAvatarUrl = '',
    required this.type,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    this.snippet = '',
    required this.recipientUid,
    required this.createdAt,
  });

  factory ActivityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityModel(
      activityId: doc.id,
      actorUid: data['actorUid'] ?? '',
      actorDisplayName: data['actorDisplayName'] ?? '',
      actorAvatarUrl: data['actorAvatarUrl'] ?? '',
      type: data['type'] ?? '',
      targetType: data['targetType'] ?? '',
      targetId: data['targetId'] ?? '',
      targetName: data['targetName'] ?? '',
      snippet: data['snippet'] ?? '',
      recipientUid: data['recipientUid'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}