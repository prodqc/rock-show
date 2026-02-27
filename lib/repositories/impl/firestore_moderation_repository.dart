import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/contact_submission_model.dart';
import '../../models/venue_claim_model.dart';
import '../../models/venue_model.dart';
import '../moderation_repository.dart';

class FirestoreModerationRepository implements ModerationRepository {
  final FirebaseFirestore _db;

  FirestoreModerationRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference get _contactSubmissions =>
      _db.collection('contact_submissions');
  CollectionReference get _venueClaims => _db.collection('venue_claims');
  CollectionReference get _venues => _db.collection('venues');
  CollectionReference get _users => _db.collection('users');

  @override
  Future<String> submitContact(ContactSubmissionModel submission) async {
    final ref = _contactSubmissions.doc();
    final data = submission.toFirestore();
    data['submittedAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
    return ref.id;
  }

  @override
  Future<String> submitVenueClaim({
    required VenueClaimModel claim,
    required ContactSubmissionModel contactSubmission,
  }) async {
    final claimRef = _venueClaims.doc();
    final contactRef = _contactSubmissions.doc();
    final batch = _db.batch();

    final claimData = claim.toFirestore();
    claimData['submittedAt'] = FieldValue.serverTimestamp();
    claimData['contactSubmissionId'] = contactRef.id;

    final contactData = contactSubmission.toFirestore();
    contactData['submittedAt'] = FieldValue.serverTimestamp();
    contactData['claimId'] = claimRef.id;

    batch.set(claimRef, claimData);
    batch.set(contactRef, contactData);
    await batch.commit();
    return claimRef.id;
  }

  @override
  Stream<List<VenueModel>> watchPendingVenues({int limit = 100}) {
    return _venues
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => VenueModel.fromFirestore(d)).toList());
  }

  @override
  Stream<List<VenueClaimModel>> watchPendingVenueClaims({int limit = 100}) {
    return _venueClaims
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => VenueClaimModel.fromFirestore(d)).toList());
  }

  @override
  Future<void> approveVenue({
    required String venueId,
    required String adminUid,
  }) async {
    await _venues.doc(venueId).update({
      'status': 'published',
      'updatedAt': FieldValue.serverTimestamp(),
      'moderatedBy': adminUid,
      'moderatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> rejectVenue({
    required String venueId,
    required String adminUid,
    String? reason,
  }) async {
    await _venues.doc(venueId).update({
      'status': 'rejected',
      'updatedAt': FieldValue.serverTimestamp(),
      'moderatedBy': adminUid,
      'moderatedAt': FieldValue.serverTimestamp(),
      if (reason != null && reason.trim().isNotEmpty)
        'moderationReason': reason,
    });
  }

  @override
  Future<void> approveVenueClaim({
    required String claimId,
    required String adminUid,
  }) async {
    await _db.runTransaction((tx) async {
      final claimRef = _venueClaims.doc(claimId);
      final claimSnap = await tx.get(claimRef);
      if (!claimSnap.exists) {
        throw StateError('Claim not found');
      }
      final claim = VenueClaimModel.fromFirestore(claimSnap);

      final venueRef = _venues.doc(claim.venueId);
      final userRef = _users.doc(claim.userId);
      final venueSnap = await tx.get(venueRef);
      final userSnap = await tx.get(userRef);

      if (!venueSnap.exists || !userSnap.exists) {
        throw StateError('Linked venue or user missing');
      }
      final userData = userSnap.data() as Map<String, dynamic>;
      final currentRole = (userData['role'] ?? 'user').toString();
      final nextRole = currentRole == 'admin' ? 'admin' : 'venue_owner';

      tx.update(claimRef, {
        'status': 'approved',
        'reviewedBy': adminUid,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      tx.update(userRef, {
        'role': nextRole,
        'isVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.update(venueRef, {
        'claimedBy': claim.userId,
        'claimedAt': FieldValue.serverTimestamp(),
        'isVerified': true,
        'status': 'claimed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> rejectVenueClaim({
    required String claimId,
    required String adminUid,
    String? reason,
  }) async {
    await _venueClaims.doc(claimId).update({
      'status': 'rejected',
      'reviewedBy': adminUid,
      'reviewedAt': FieldValue.serverTimestamp(),
      if (reason != null && reason.trim().isNotEmpty) 'reviewReason': reason,
    });
  }
}
