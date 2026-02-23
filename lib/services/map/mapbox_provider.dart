import 'package:flutter/widgets.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../models/app_lat_lng.dart';
import 'map_provider.dart';

class MapboxProvider implements MapProvider {
  MapboxMap? _mapboxMap;

  @override
  Widget buildMap({
    required AppLatLng initialCenter,
    required double initialZoom,
    required List<MapMarker> markers,
    required OnMarkerTap onMarkerTap,
    required bool isDarkMode,
    Key? key,
  }) {
    return MapWidget(
      key: key,
      styleUri: isDarkMode ? MapboxStyles.DARK : MapboxStyles.LIGHT,
      cameraOptions: CameraOptions(
        center: Point(
          coordinates: Position(
            initialCenter.longitude,
            initialCenter.latitude,
          ),
        ),
        zoom: initialZoom,
      ),
      onMapCreated: (MapboxMap map) async {
        _mapboxMap = map;
        // Disable telemetry (optional)
        map.compass.updateSettings(CompassSettings(enabled: false));
        // Add venue markers
        await _addMarkers(map, markers, onMarkerTap);
      },
    );
  }

  Future<void> _addMarkers(
    MapboxMap map,
    List<MapMarker> markers,
    OnMarkerTap onMarkerTap,
  ) async {
    if (markers.isEmpty) return;

    final manager = await map.annotations.createPointAnnotationManager();

    for (final marker in markers) {
      await manager.create(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              marker.position.longitude,
              marker.position.latitude,
            ),
          ),
          textField: marker.title,
          textSize: 12.0,
          textOffset: [0.0, 1.5],
          iconSize: 1.3,
        ),
      );
    }

    manager.addOnPointAnnotationClickListener(
      _AnnotationTapListener(markers, onMarkerTap),
    );
  }

  @override
  Future<void> moveCamera(AppLatLng target, double zoom) async {
    await _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(target.longitude, target.latitude),
        ),
        zoom: zoom,
      ),
      MapAnimationOptions(duration: 500),
    );
  }

  @override
  Future<void> recenterToUser(AppLatLng userLocation) async {
    await moveCamera(userLocation, 14.0);
  }
}

class _AnnotationTapListener extends OnPointAnnotationClickListener {
  final List<MapMarker> _markers;
  final OnMarkerTap _onTap;

  _AnnotationTapListener(this._markers, this._onTap);

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    final coords = annotation.geometry.coordinates;
    for (final m in _markers) {
      if ((m.position.latitude - coords.lat).abs() < 0.0001 &&
          (m.position.longitude - coords.lng).abs() < 0.0001) {
        _onTap(m);
        break;
      }
    }
  }
}