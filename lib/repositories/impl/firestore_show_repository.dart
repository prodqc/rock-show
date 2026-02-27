import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/show_model.dart';
import '../show_repository.dart';

class FirestoreShowRepository implements ShowRepository {
  final FirebaseFirestore _db;
  FirestoreShowRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference get _shows => _db.collection('shows');
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _venues => _db.collection('venues');

  @override
  Stream<List<ShowModel>> watchNearbyShows({
    required List<String> geohashes,
    required DateTime from,
    int limit = 20,
  }) {
    if (geohashes.isEmpty) return Stream.value([]);
    return _shows
        .where('venueLocation.geohash', whereIn: geohashes)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .orderBy('date')
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ShowModel.fromFirestore(d))
            .where((show) =>
                !show.isArchived &&
                (show.status == 'confirmed' ||
                    show.status == 'community_reported' ||
                    show.status == 'active'))
            .toList());
  }

  @override
  Future<ShowModel?> getShow(String showId) async {
    final doc = await _shows.doc(showId).get();
    if (!doc.exists) return null;
    return ShowModel.fromFirestore(doc);
  }

  @override
  Future<List<ShowModel>> getShowsForVenue(String venueId,
      {int limit = 20}) async {
    final snap = await _shows
        .where('venueId', isEqualTo: venueId)
        .orderBy('date')
        .limit(limit)
        .get();
    return snap.docs
        .map((d) => ShowModel.fromFirestore(d))
        .where((show) =>
            !show.isArchived &&
            (show.status == 'confirmed' ||
                show.status == 'community_reported' ||
                show.status == 'active'))
        .toList();
  }

  @override
  Future<String> createShow(ShowModel show) async {
    final ref = await _shows.add(show.toFirestore());
    return ref.id;
  }

  @override
  Future<String> createShowSubmission({
    required ShowModel show,
    required String submitterUid,
  }) async {
    final userSnap = await _users.doc(submitterUid).get();
    final venueSnap = await _venues.doc(show.venueId).get();
    if (!userSnap.exists) {
      throw StateError('User profile not found');
    }
    if (!venueSnap.exists) {
      throw StateError('Venue not found');
    }

    final user = userSnap.data() as Map<String, dynamic>;
    final venue = venueSnap.data() as Map<String, dynamic>;
    final role = (user['role'] ?? 'user').toString();
    final venueOwnerId = (venue['claimedBy'] ?? '').toString();
    final isVerifiedOwner =
        role == 'venue_owner' && venueOwnerId == submitterUid;

    final trustLevel = isVerifiedOwner ? 'verified_owner' : 'community';
    final status = isVerifiedOwner ? 'confirmed' : 'community_reported';

    final data = show.toFirestore();
    data['status'] = status;
    data['trustLevel'] = trustLevel;
    data['submittedBy'] = submitterUid;
    data['createdBy'] = submitterUid;
    data['isArchived'] = false;
    data['updatedAt'] = FieldValue.serverTimestamp();
    data['createdAt'] = FieldValue.serverTimestamp();

    final ref = await _shows.add(data);
    return ref.id;
  }

  @override
  Future<void> updateShow(String showId, Map<String, dynamic> data) =>
      _shows.doc(showId).update(data);

  @override
  Future<void> deleteShow(String showId) => _shows
      .doc(showId)
      .update({'status': 'deleted', 'updatedAt': FieldValue.serverTimestamp()});
}
