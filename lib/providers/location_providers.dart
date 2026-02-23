import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_lat_lng.dart';
import '../services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final locationPermissionProvider = FutureProvider<bool>((ref) async {
  return ref.read(locationServiceProvider).checkPermission();
});

final currentLocationProvider = FutureProvider<AppLatLng?>((ref) async {
  final service = ref.read(locationServiceProvider);
  final hasPermission = await service.checkPermission();
  if (!hasPermission) {
    final granted = await service.requestPermission();
    if (!granted) return null;
  }
  return service.getCurrentLocation();
});

/// Fallback location (set by user via city search). Persisted in memory for session.
final fallbackLocationProvider = StateProvider<AppLatLng?>((ref) => null);

/// Effective location: GPS if available, else fallback.
final effectiveLocationProvider = Provider<AppLatLng?>((ref) {
  final gps = ref.watch(currentLocationProvider).value;
  final fallback = ref.watch(fallbackLocationProvider);
  return gps ?? fallback;
});