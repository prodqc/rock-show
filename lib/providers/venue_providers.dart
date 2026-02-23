import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/venue_model.dart';
import '../repositories/venue_repository.dart';
import '../repositories/impl/firestore_venue_repository.dart';
import 'location_providers.dart';

final venueRepositoryProvider = Provider<VenueRepository>((ref) {
  return FirestoreVenueRepository();
});

final nearbyVenuesProvider =
    FutureProvider.autoDispose<List<VenueModel>>((ref) async {
  final location = ref.watch(effectiveLocationProvider);
  if (location == null) return [];
  final repo = ref.read(venueRepositoryProvider);
  return repo.getNearbyVenues(location, 15.0); // 15 km default radius
});

final venueDetailProvider =
    FutureProvider.autoDispose.family<VenueModel?, String>((ref, venueId) {
  return ref.read(venueRepositoryProvider).getVenue(venueId);
});

final venueSearchProvider =
    FutureProvider.autoDispose.family<List<VenueModel>, String>((ref, query) {
  if (query.length < 2) return [];
  return ref.read(venueRepositoryProvider).searchVenues(query);
});