import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/show_model.dart';
import '../repositories/impl/firestore_show_repository.dart';
import '../repositories/show_repository.dart';
import '../services/geohash_service.dart';
import '../utils/haversine.dart';
import 'location_providers.dart';

final showRepositoryProvider = Provider<ShowRepository>((ref) {
  return FirestoreShowRepository();
});

final nearbyShowsProvider =
    FutureProvider.autoDispose<List<ShowModel>>((ref) async {
  final location = ref.watch(effectiveLocationProvider);
  if (location == null) return [];

  final geohash = GeohashService();
  final ranges =
      geohash.getQueryRanges(location.latitude, location.longitude, 15.0);
  final now = DateTime.now();

  final db = FirebaseFirestore.instance;
  final futures = ranges.map((range) => db
      .collection('shows')
      .where('venueLocation.geohash', isGreaterThanOrEqualTo: range.start)
      .where('venueLocation.geohash', isLessThanOrEqualTo: range.end)
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
      .orderBy('date')
      .limit(30)
      .get());

  final snapshots = await Future.wait(futures);
  final shows = snapshots
      .expand((s) => s.docs)
      .map((d) => ShowModel.fromFirestore(d))
      .toList();

  // Deduplicate + distance filter
  final seen = <String>{};
  final filtered = shows.where((s) {
    if (seen.contains(s.showId)) return false;
    seen.add(s.showId);
    final statusAllowed = s.status == 'confirmed' ||
        s.status == 'community_reported' ||
        s.status == 'active';
    final inRadius = haversineKm(location.latitude, location.longitude,
            s.venueLocation.lat, s.venueLocation.lng) <=
        15.0;
    return statusAllowed && !s.isArchived && inRadius;
  }).toList();

  filtered.sort((a, b) => a.date.compareTo(b.date));
  return filtered;
});

final showDetailProvider =
    FutureProvider.autoDispose.family<ShowModel?, String>((ref, showId) async {
  return ref.read(showRepositoryProvider).getShow(showId);
});
