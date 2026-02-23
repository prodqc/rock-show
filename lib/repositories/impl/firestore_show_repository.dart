import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/show_model.dart';
import '../show_repository.dart';

class FirestoreShowRepository implements ShowRepository {
  final FirebaseFirestore _db;
  FirestoreShowRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference get _shows => _db.collection('shows');

  @override
  Stream<List<ShowModel>> watchNearbyShows({
    required List<String> geohashes,
    required DateTime from,
    int limit = 20,
  }) {
    if (geohashes.isEmpty) return Stream.value([]);
    return _shows
        .where('status', isEqualTo: 'active')
        .where('venueLocation.geohash', whereIn: geohashes)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .orderBy('date')
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ShowModel.fromFirestore(d)).toList());
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
        .where('status', isEqualTo: 'active')
        .orderBy('date')
        .limit(limit)
        .get();
    return snap.docs.map((d) => ShowModel.fromFirestore(d)).toList();
  }

  @override
  Future<String> createShow(ShowModel show) async {
    final ref = await _shows.add(show.toFirestore());
    return ref.id;
  }

  @override
  Future<void> updateShow(String showId, Map<String, dynamic> data) =>
      _shows.doc(showId).update(data);

  @override
  Future<void> deleteShow(String showId) =>
      _shows.doc(showId).update({'status': 'deleted'});
}