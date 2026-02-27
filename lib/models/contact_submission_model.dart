import 'package:cloud_firestore/cloud_firestore.dart';

class ContactSubmissionModel {
  final String id;
  final String? userId;
  final String? venueId;
  final String subject;
  final String message;
  final String email;
  final String status; // 'unread' | 'read' | 'responded'
  final DateTime submittedAt;

  const ContactSubmissionModel({
    required this.id,
    this.userId,
    this.venueId,
    required this.subject,
    required this.message,
    required this.email,
    this.status = 'unread',
    required this.submittedAt,
  });

  factory ContactSubmissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContactSubmissionModel(
      id: doc.id,
      userId: (data['userId'] ?? data['user_id'])?.toString(),
      venueId: (data['venueId'] ?? data['venue_id'])?.toString(),
      subject: (data['subject'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      status: (data['status'] ?? 'unread').toString(),
      submittedAt: (data['submittedAt'] as Timestamp? ??
                  data['submitted_at'] as Timestamp?)
              ?.toDate() ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'venueId': venueId,
        'subject': subject,
        'message': message,
        'email': email,
        'status': status,
        'submittedAt': Timestamp.fromDate(submittedAt),
      };
}
