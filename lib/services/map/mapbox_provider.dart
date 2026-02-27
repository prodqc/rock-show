import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../../models/app_lat_lng.dart';
import 'map_provider.dart';
import 'marker_image_generator.dart';

class MapboxProvider implements MapProvider {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _dotAnnotationManager;
  PointAnnotationManager? _pillAnnotationManager;

  // Blend range for transition from dot -> labeled marker.
  static const double _transitionStartZoom = 12.5;
  static const double _transitionEndZoom = 14.0;

  // Stored references for re-adding markers on zoom change.
  List<MapMarker> _currentMarkers = [];
  OnMarkerTap? _currentOnMarkerTap;
  ValueChanged<double>? _onZoomChanged;
  double _lastZoom = 13.0;

  // Pre-generated images.
  Uint8List? _dotImage;
  final Map<String, Uint8List> _pillImages = {};

  // Guard against concurrent refreshes.
  bool _isRefreshing = false;
  bool _pendingRefresh = false;
  bool _isApplyingBlend = false;
  double? _queuedBlendZoom;

  /// Zoom to a specific level (keeps current center).
  @override
  Future<void> setZoom(double zoom) async {
    final camera = await _mapboxMap?.getCameraState();
    if (camera == null) return;
    await _mapboxMap?.flyTo(
      CameraOptions(center: camera.center, zoom: zoom),
      MapAnimationOptions(duration: 300),
    );
  }

  @override
  Widget buildMap({
    required AppLatLng initialCenter,
    required double initialZoom,
    required List<MapMarker> markers,
    required OnMarkerTap onMarkerTap,
    required bool isDarkMode,
    ValueChanged<double>? onZoomChanged,
    Key? key,
  }) {
    _currentMarkers = markers;
    _currentOnMarkerTap = onMarkerTap;
    _onZoomChanged = onZoomChanged;

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
      onCameraChangeListener: _onCameraChanged,
      onMapCreated: (MapboxMap map) async {
        _mapboxMap = map;
        map.compass.updateSettings(CompassSettings(enabled: false));
        map.gestures.updateSettings(GesturesSettings(
          pinchToZoomEnabled: true,
          doubleTapToZoomInEnabled: true,
          doubleTouchToZoomOutEnabled: true,
          scrollEnabled: true,
          rotateEnabled: true,
        ));
        // Show the user's current location as a pulsing puck.
        map.location.updateSettings(LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          puckBearingEnabled: true,
          puckBearing: PuckBearing.HEADING,
        ));

        await _prepareMarkerImages(markers);
        _lastZoom = initialZoom;
        await _buildMarkerLayers(map, markers, onMarkerTap);
        await _applyMarkerBlend(initialZoom);
      },
    );
  }

  @override
  Future<void> updateMarkers(List<MapMarker> markers) async {
    _currentMarkers = markers;
    await _prepareMarkerImages(markers);
    await _refreshMarkers();
  }

  void _onCameraChanged(CameraChangedEventData data) {
    final zoom = data.cameraState.zoom;
    _lastZoom = zoom;
    _onZoomChanged?.call(zoom);
    _applyMarkerBlend(zoom);
  }

  Future<void> _prepareMarkerImages(List<MapMarker> markers) async {
    _dotImage ??= await MarkerImageGenerator.generateDotMarker();

    for (final marker in markers) {
      if (!_pillImages.containsKey(marker.title)) {
        _pillImages[marker.title] =
            await MarkerImageGenerator.generatePillMarker(title: marker.title);
      }
    }
  }

  Future<void> _refreshMarkers() async {
    if (_isRefreshing || _mapboxMap == null) {
      _pendingRefresh = true;
      return;
    }
    _isRefreshing = true;
    _pendingRefresh = false;

    try {
      await _clearManagers();
      await _buildMarkerLayers(
        _mapboxMap!,
        _currentMarkers,
        _currentOnMarkerTap!,
      );
      await _applyMarkerBlend(_lastZoom);
    } finally {
      _isRefreshing = false;
      if (_pendingRefresh) {
        _pendingRefresh = false;
        await _refreshMarkers();
      }
    }
  }

  Future<void> _buildMarkerLayers(
    MapboxMap map,
    List<MapMarker> markers,
    OnMarkerTap onMarkerTap,
  ) async {
    _dotAnnotationManager =
        await map.annotations.createPointAnnotationManager();
    _pillAnnotationManager =
        await map.annotations.createPointAnnotationManager();

    await Future.wait([
      _dotAnnotationManager!.setIconAllowOverlap(true),
      _dotAnnotationManager!.setIconIgnorePlacement(true),
      _pillAnnotationManager!.setIconAllowOverlap(true),
      _pillAnnotationManager!.setIconIgnorePlacement(true),
    ]);

    if (markers.isEmpty) {
      return;
    }

    final dotOptions = <PointAnnotationOptions>[];
    final pillOptions = <PointAnnotationOptions>[];

    for (final marker in markers) {
      dotOptions.add(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              marker.position.longitude,
              marker.position.latitude,
            ),
          ),
          image: _dotImage!,
          iconAnchor: IconAnchor.CENTER,
        ),
      );
      pillOptions.add(
        PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(
              marker.position.longitude,
              marker.position.latitude,
            ),
          ),
          image: _pillImages[marker.title] ?? _dotImage!,
          iconAnchor: IconAnchor.BOTTOM,
        ),
      );
    }

    await Future.wait([
      _dotAnnotationManager!.createMulti(dotOptions),
      _pillAnnotationManager!.createMulti(pillOptions),
    ]);

    _dotAnnotationManager!.tapEvents(
      onTap: (annotation) {
        _handleAnnotationTap(annotation, markers, onMarkerTap);
      },
    );
    _pillAnnotationManager!.tapEvents(
      onTap: (annotation) {
        _handleAnnotationTap(annotation, markers, onMarkerTap);
      },
    );
  }

  void _handleAnnotationTap(
    PointAnnotation annotation,
    List<MapMarker> markers,
    OnMarkerTap onMarkerTap,
  ) {
    final coords = annotation.geometry.coordinates;
    for (final marker in markers) {
      if ((marker.position.latitude - coords.lat).abs() < 0.0001 &&
          (marker.position.longitude - coords.lng).abs() < 0.0001) {
        onMarkerTap(marker);
        return;
      }
    }
  }

  Future<void> _applyMarkerBlend(double zoom) async {
    if (_dotAnnotationManager == null || _pillAnnotationManager == null) {
      return;
    }

    if (_isApplyingBlend) {
      _queuedBlendZoom = zoom;
      return;
    }
    _isApplyingBlend = true;

    var nextZoom = zoom;
    try {
      while (true) {
        final tNum = ((nextZoom - _transitionStartZoom) /
                (_transitionEndZoom - _transitionStartZoom))
            .clamp(0.0, 1.0);
        final t = (tNum as num).toDouble();

        // Dots: fade out and shrink.
        final dotOpacity = 1.0 - t;
        final dotSize = 1.0 - (0.3 * t);

        // Pills: grow from tiny → full size (dramatic scale-in),
        // so the bubble appears to emerge rather than just fade in.
        final pillOpacity = t;
        // Ease-out curve: slow down as pills reach full size.
        final tEased = 1.0 - (1.0 - t) * (1.0 - t);
        final pillSize = 0.12 + (0.88 * tEased);

        await Future.wait([
          _dotAnnotationManager!.setIconOpacity(dotOpacity),
          _pillAnnotationManager!.setIconOpacity(pillOpacity),
          _dotAnnotationManager!.setIconSize(dotSize),
          _pillAnnotationManager!.setIconSize(pillSize),
        ]);

        if (_queuedBlendZoom == null) break;
        nextZoom = _queuedBlendZoom!;
        _queuedBlendZoom = null;
      }
    } finally {
      _isApplyingBlend = false;
    }
  }

  Future<void> _clearManagers() async {
    if (_mapboxMap == null) return;
    if (_dotAnnotationManager != null) {
      await _mapboxMap!.annotations
          .removeAnnotationManager(_dotAnnotationManager!);
      _dotAnnotationManager = null;
    }
    if (_pillAnnotationManager != null) {
      await _mapboxMap!.annotations
          .removeAnnotationManager(_pillAnnotationManager!);
      _pillAnnotationManager = null;
    }
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
