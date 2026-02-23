import 'package:flutter/widgets.dart';
import '../../models/app_lat_lng.dart';
import '../../config/env_config.dart';
import 'map_provider.dart';

// NOTE: Full Mapbox implementation requires mapbox_maps_flutter package setup.
// This is the integration point. Screens never import mapbox_maps_flutter directly.

class MapboxProvider implements MapProvider {
  // MapboxMap controller reference would be stored here after map init.

  @override
  Widget buildMap({
    required AppLatLng initialCenter,
    required double initialZoom,
    required List<MapMarker> markers,
    required OnMarkerTap onMarkerTap,
    required bool isDarkMode,
    Key? key,
  }) {
    // TODO: Replace with actual MapWidget from mapbox_maps_flutter
    // Example integration:
    //
    // return MapWidget(
    //   key: key,
    //   styleUri: isDarkMode
    //       ? EnvConfig.mapboxStyleDark
    //       : EnvConfig.mapboxStyleLight,
    //   cameraOptions: CameraOptions(
    //     center: Point(coordinates: Position(
    //       initialCenter.longitude,
    //       initialCenter.latitude,
    //     )),
    //     zoom: initialZoom,
    //   ),
    //   onMapCreated: (controller) { ... },
    // );

    return Center(
      key: key,
      child: const Text('Map placeholder — wire Mapbox here'),
    );
  }

  @override
  Future<void> moveCamera(AppLatLng target, double zoom) async {
    // Use stored controller to flyTo
  }

  @override
  Future<void> recenterToUser(AppLatLng userLocation) async {
    await moveCamera(userLocation, 14.0);
  }
}