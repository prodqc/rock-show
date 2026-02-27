import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/venue_model.dart';
import '../../models/app_lat_lng.dart';
import '../../services/geohash_service.dart';
import '../../utils/haversine.dart';
import '../venue_repository.dart';

class FirestoreVenueRepository implements VenueRepository {
  final FirebaseFirestore _db;
  final GeohashService _geohash;
  static const _visibleStatuses = {'published', 'claimed', 'active'};
  static const _visibleStatusList = ['published', 'claimed', 'active'];

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
    AppLatLng center,
    double radiusKm, {
    String? viewerUid,
  }) async {
    final ranges = _geohash.getQueryRanges(
      center.latitude,
      center.longitude,
      radiusKm,
    );

    List<QuerySnapshot> snapshots;
    try {
      snapshots = await _fetchNearbySnapshots(
        ranges,
        includePending: viewerUid != null,
      );
    } on FirebaseException catch (e) {
      // Missing composite indexes should not blank out the map/home feed.
      if (e.code != 'failed-precondition') rethrow;
      snapshots = await _fetchNearbySnapshotsUnindexed(ranges);
    }

    final venues = snapshots
        .expand((s) => s.docs)
        .map(_safeVenueFromDoc)
        .whereType<VenueModel>()
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
      final isVisible = _visibleStatuses.contains(v.status);
      final isOwnPending = viewerUid != null &&
          v.status == 'pending' &&
          v.createdBy == viewerUid;
      return (isVisible || isOwnPending) && dist <= radiusKm;
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
    QuerySnapshot snap;
    try {
      snap = await _venues
          .where('status', whereIn: _visibleStatusList)
          .where('nameLower', isGreaterThanOrEqualTo: lower)
          .where('nameLower', isLessThanOrEqualTo: '$lower\uf8ff')
          .limit(limit)
          .get();
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition') rethrow;
      snap = await _venues
          .where('nameLower', isGreaterThanOrEqualTo: lower)
          .where('nameLower', isLessThanOrEqualTo: '$lower\uf8ff')
          .limit(limit)
          .get();
    }

    return snap.docs
        .map(_safeVenueFromDoc)
        .whereType<VenueModel>()
        .where((v) => _visibleStatuses.contains(v.status))
        .toList();
  }

  @override
  Future<String> createVenue(VenueModel venue) async {
    final docRef = _venues.doc();
    final data = venue.toFirestore();
    data['nameNormalized'] = _normalizeVenueName(venue.name);
    data['address']['normalized'] = _normalizeAddress(venue.address.formatted);
    data['location']['geohash'] = _geohash.encode(
      venue.location.lat,
      venue.location.lng,
    );
    data['status'] = venue.status.isEmpty ? 'pending' : venue.status;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.set(data);
    return docRef.id;
  }

  @override
  Future<void> updateVenue(String venueId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _venues.doc(venueId).update(updates);
  }

  @override
  Future<List<VenueModel>> checkDuplicates(String name, AppLatLng location,
      {String? address}) async {
    final ranges = _geohash.getQueryRanges(
      location.latitude,
      location.longitude,
      0.2,
    );
    final snapshots = await Future.wait(
      ranges.map(
        (range) => _venues
            .where('location.geohash', isGreaterThanOrEqualTo: range.start)
            .where('location.geohash', isLessThanOrEqualTo: range.end)
            .limit(50)
            .get(),
      ),
    );
    final seen = <String>{};
    final nearby = snapshots
        .expand((s) => s.docs)
        .map((d) => VenueModel.fromFirestore(d))
        .where((v) => seen.add(v.venueId))
        .toList();
    final normalized = _normalizeVenueName(name);
    final normalizedInputAddress = _normalizeAddress(address ?? '');
    return nearby.where((v) {
      final nameA = _normalizeVenueName(v.name);
      final distanceMeters = haversineKm(
            location.latitude,
            location.longitude,
            v.location.lat,
            v.location.lng,
          ) *
          1000;
      final similarity = _similarity(nameA, normalized);

      final normalizedAddress = _normalizeAddress(v.address.formatted);
      final sameAddress = normalizedInputAddress.isNotEmpty &&
          normalizedAddress == normalizedInputAddress;

      if (sameAddress) return true;
      if (similarity >= 0.7) return distanceMeters <= 100;
      return similarity >= 0.5 && distanceMeters <= 200;
    }).toList();
  }

  String _normalizeVenueName(String input) {
    final stripped = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\b(the|bar|club|lounge)\b'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return stripped;
  }

  String _normalizeAddress(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'\bst\b'), 'street')
        .replaceAll(RegExp(r'\bave\b'), 'avenue')
        .replaceAll(RegExp(r'\brd\b'), 'road')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _similarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    final distance = _levenshtein(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen == 0) return 1.0;
    return 1 - (distance / maxLen);
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

  Future<List<QuerySnapshot>> _fetchNearbySnapshots(
    List<GeohashRange> ranges, {
    required bool includePending,
  }) async {
    final visibleQueries = ranges.map(
      (range) => _venues
          .where('status', whereIn: _visibleStatusList)
          .where('location.geohash', isGreaterThanOrEqualTo: range.start)
          .where('location.geohash', isLessThanOrEqualTo: range.end)
          .limit(60)
          .get(),
    );

    if (!includePending) {
      return Future.wait(visibleQueries);
    }

    final pendingQueries = ranges.map(
      (range) => _venues
          .where('status', isEqualTo: 'pending')
          .where('location.geohash', isGreaterThanOrEqualTo: range.start)
          .where('location.geohash', isLessThanOrEqualTo: range.end)
          .limit(30)
          .get(),
    );

    return Future.wait([...visibleQueries, ...pendingQueries]);
  }

  Future<List<QuerySnapshot>> _fetchNearbySnapshotsUnindexed(
    List<GeohashRange> ranges,
  ) {
    final queries = ranges.map(
      (range) => _venues
          .where('location.geohash', isGreaterThanOrEqualTo: range.start)
          .where('location.geohash', isLessThanOrEqualTo: range.end)
          .limit(80)
          .get(),
    );
    return Future.wait(queries);
  }

  VenueModel? _safeVenueFromDoc(DocumentSnapshot doc) {
    try {
      return VenueModel.fromFirestore(doc);
    } catch (_) {
      return null;
    }
  }
}
