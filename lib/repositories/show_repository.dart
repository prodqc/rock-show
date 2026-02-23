import '../models/show_model.dart';

abstract class ShowRepository {
  Stream<List<ShowModel>> watchNearbyShows({
    required List<String> geohashes,
    required DateTime from,
    int limit = 20,
  });

  Future<ShowModel?> getShow(String showId);

  Future<List<ShowModel>> getShowsForVenue(String venueId, {int limit = 20});

  Future<String> createShow(ShowModel show);

  Future<void> updateShow(String showId, Map<String, dynamic> data);

  Future<void> deleteShow(String showId);
}