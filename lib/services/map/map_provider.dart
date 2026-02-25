import '../../models/app_lat_lng.dart';
import 'package:flutter/widgets.dart';

/// Marker data for the map.
class MapMarker {
  final String id;
  final AppLatLng position;
  final String title;
  final String snippet;
  final MapMarkerType type;

  const MapMarker({
    required this.id,
    required this.position,
    required this.title,
    this.snippet = '',
    this.type = MapMarkerType.venue,
  });
}

enum MapMarkerType { venue, show }

/// Callback when a marker is tapped.
typedef OnMarkerTap = void Function(MapMarker marker);

/// Abstract map provider. Screens depend on this, not on Mapbox directly.
abstract class MapProvider {
  /// Build the map widget.
  Widget buildMap({
    required AppLatLng initialCenter,
    required double initialZoom,
    required List<MapMarker> markers,
    required OnMarkerTap onMarkerTap,
    required bool isDarkMode,
    Key? key,
  });

  /// Programmatically move camera.
  Future<void> moveCamera(AppLatLng target, double zoom);

  /// Recenter on user location.
  Future<void> recenterToUser(AppLatLng userLocation);

  /// Set zoom level (keeps current center).
  Future<void> setZoom(double zoom);
}