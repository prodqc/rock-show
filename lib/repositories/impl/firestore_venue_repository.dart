import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/venue_model.dart';
import '../../models/app_lat_lng.dart';
import '../../services/geohash_service.dart';
import '../../utils/haversine.dart';
import '../venue_repository.dart';

class FirestoreVenueRepository implements VenueRepository {
  final FirebaseFirestore _db;
  final GeohashService _geohash;

  FirestoreVenueRepository({
    FirebaseFirestore? db,
    GeohashService? geohash,
  })  : _db = db ?? FirebaseFirestore.instance,
        _geohash = geohash ?? GeohashService();

  CollectionReference get _venues => _db.collection('venues');

  @override
  Future<VenueModel?> getVenue(String venueId) async {
    final doc = await _venues.doc(venueId).get();
    if (!doc.exists) return null;
    return VenueModel.fromFirestore(doc);
  }

  @override
  Future<List<VenueModel>> getNearbyVenues(
      AppLatLng center, double radiusKm) async {
    final ranges = _geohash.getQueryRanges(
      center.latitude,
      center.longitude,
      radiusKm,
    );

    final futures = ranges.map((range) => _venues
        .where('status', isEqualTo: 'active')
        .where('location.geohash', isGreaterThanOrEqualTo: range.start)
        .where('location.geohash', isLessThanOrEqualTo: range.end)
        .limit(50)
        .get());

    final snapshots = await Future.wait(futures);
    final venues = snapshots
        .expand((s) => s.docs)
        .map((d) => VenueModel.fromFirestore(d))
        .toList();

    // Post-filter by exact distance + deduplicate
    final seen = <String>{};
    return venues.where((v) {
      if (seen.contains(v.venueId)) return false;
      seen.add(v.venueId);
      final dist = haversineKm(
        center.latitude,
        center.longitude,
        v.location.lat,
        v.location.lng,
      );
      return dist <= radiusKm;
    }).toList()
      ..sort((a, b) {
        final da = haversineKm(
            center.latitude, center.longitude, a.location.lat, a.location.lng);
        final db = haversineKm(
            center.latitude, center.longitude, b.location.lat, b.location.lng);
        return da.compareTo(db);
      });
  }

  @override
  Future<List<VenueModel>> searchVenues(String query, {int limit = 20}) async {
    final lower = query.toLowerCase();
    final snap = await _venues
        .where('status', isEqualTo: 'active')
        .where('nameLower', isGreaterThanOrEqualTo: lower)
        .where('nameLower', isLessThanOrEqualTo: '$lower\uf8ff')
        .limit(limit)
        .get();
    return snap.docs.map((d) => VenueModel.fromFirestore(d)).toList();
  }

  @override
  Future<String> createVenue(VenueModel venue) async {
    final docRef = _venues.doc();
    final data = venue.toFirestore();
    data['location']['geohash'] = _geohash.encode(
      venue.location.lat,
      venue.location.lng,
    );
    await docRef.set(data);
    return docRef.id;
  }

  @override
  Future<void> updateVenue(
      String venueId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _venues.doc(venueId).update(updates);
  }

  @override
  Future<List<VenueModel>> checkDuplicates(
      String name, AppLatLng location) async {
    // Search within 200m for venues with similar names
    final nearby = await getNearbyVenues(location, 0.2);
    final lower = name.toLowerCase();
    return nearby.where((v) {
      final distance = _levenshtein(v.nameLower, lower);
      return distance <= 3;
    }).toList();
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;
    final v0 = List<int>.generate(t.length + 1, (i) => i);
    final v1 = List<int>.filled(t.length + 1, 0);
    for (var i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (var j = 0; j < t.length; j++) {
        final cost = s[i] == t[j] ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost]
            .reduce((a, b) => a < b ? a : b);
      }
      v0.setAll(0, v1);
    }
    return v1[t.length];
  }
}