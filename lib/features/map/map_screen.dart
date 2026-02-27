import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_constants.dart';
import '../../models/app_lat_lng.dart';
import '../../providers/location_providers.dart';
import '../../providers/venue_providers.dart';
import '../../services/map/map_provider.dart';
import '../../services/map/mapbox_provider.dart';
import '../../services/map/marker_image_generator.dart';
import 'widgets/venue_preview_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final MapboxProvider _mapProvider;
  MapMarker? _selectedMarker;
  double _currentZoom = 13;

  @override
  void initState() {
    super.initState();
    _mapProvider = MapboxProvider();
  }

  @override
  void dispose() {
    MarkerImageGenerator.clearCache();
    super.dispose();
  }

  void _zoomIn() {
    _currentZoom = (_currentZoom + 1).clamp(1, 20);
    _mapProvider.setZoom(_currentZoom);
  }

  void _zoomOut() {
    _currentZoom = (_currentZoom - 1).clamp(1, 20);
    _mapProvider.setZoom(_currentZoom);
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(effectiveLocationProvider);
    final venuesAsync = ref.watch(nearbyVenuesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final center = location ??
        const AppLatLng(
          latitude: AppConstants.defaultLat,
          longitude: AppConstants.defaultLng,
        );

    final markers = venuesAsync.when(
      data: (venues) => venues
          .map((v) => MapMarker(
                id: v.venueId,
                position: v.appLatLng,
                title: v.name,
                snippet: v.address.formatted,
              ))
          .toList(),
      loading: () => <MapMarker>[],
      error: (_, __) => <MapMarker>[],
    );

    // Update markers when venue data loads after map creation.
    ref.listen(nearbyVenuesProvider, (prev, next) {
      next.whenData((venues) {
        final updated = venues
            .map((v) => MapMarker(
                  id: v.venueId,
                  position: v.appLatLng,
                  title: v.name,
                  snippet: v.address.formatted,
                ))
            .toList();
        _mapProvider.updateMarkers(updated);
      });
    });

    return Scaffold(
      body: Stack(
        children: [
          _mapProvider.buildMap(
            initialCenter: center,
            initialZoom: _currentZoom,
            markers: markers,
            onMarkerTap: (marker) {
              setState(() => _selectedMarker = marker);
            },
            isDarkMode: isDark,
            onZoomChanged: (zoom) {
              _currentZoom = zoom;
            },
          ),

          // Zoom controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          // Recenter FAB
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            bottom: _selectedMarker != null ? 220 : 24,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              onPressed: () {
                if (location != null) {
                  _mapProvider.recenterToUser(location);
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),

          // Bottom sheet preview
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              reverseDuration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(animation);
                return SlideTransition(
                  position: slide,
                  child: child,
                );
              },
              child: _selectedMarker == null
                  ? const SizedBox.shrink(key: ValueKey('no-selection'))
                  : VenuePreviewSheet(
                      key: ValueKey('selected-${_selectedMarker!.id}'),
                      venueId: _selectedMarker!.id,
                      venueName: _selectedMarker!.title,
                      venueAddress: _selectedMarker!.snippet,
                      onClose: () => setState(() => _selectedMarker = null),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
