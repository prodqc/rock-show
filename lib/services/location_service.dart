import 'dart:io' show Platform;

import 'package:geolocator/geolocator.dart';
import '../models/app_lat_lng.dart';

class LocationService {
  Future<bool> _isGranted(LocationPermission p) async {
    return p == LocationPermission.always ||
        p == LocationPermission.whileInUse;
  }

  Future<bool> checkPermission() async {
    final permission = await Geolocator.checkPermission();
    return _isGranted(permission);
  }

  Future<bool> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return _isGranted(permission);
  }

  /// Ensures:
  /// - Location services enabled
  /// - Permission granted (requests if needed)
  /// Returns false if user denied or is deniedForever.
  Future<bool> ensureLocationReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    final current = await Geolocator.checkPermission();

    if (current == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      return _isGranted(requested);
    }

    if (current == LocationPermission.deniedForever) {
      // Optionally, you can prompt UI and then:
      // await Geolocator.openAppSettings();
      return false;
    }

    return _isGranted(current);
  }

  LocationSettings _highAccuracySettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        timeLimit: const Duration(seconds: 15),
      );
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        timeLimit: const Duration(seconds: 15),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
      timeLimit: Duration(seconds: 15),
    );
    }

  Future<AppLatLng?> getCurrentLocation() async {
    try {
      final ready = await ensureLocationReady();
      if (!ready) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: _highAccuracySettings(),
      );

      return AppLatLng(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // Optional: log error
      return null;
    }
  }

  Stream<AppLatLng> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 100, // meters
      ),
    ).map((p) => AppLatLng(latitude: p.latitude, longitude: p.longitude));
  }
}