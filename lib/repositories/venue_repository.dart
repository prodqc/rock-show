import '../models/venue_model.dart';
import '../models/app_lat_lng.dart';

abstract class VenueRepository {
  Future<VenueModel?> getVenue(String venueId);
  Future<List<VenueModel>> getNearbyVenues(AppLatLng center, double radiusKm);
  Future<List<VenueModel>> searchVenues(String query, {int limit = 20});
  Future<String> createVenue(VenueModel venue);
  Future<void> updateVenue(String venueId, Map<String, dynamic> updates);
  Future<List<VenueModel>> checkDuplicates(String name, AppLatLng location);
}