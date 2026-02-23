import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/location_providers.dart';
import '../../providers/venue_providers.dart';
import '../../services/map/map_provider.dart';
import '../../services/map/mapbox_provider.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_radius.dart';
import '../../models/app_lat_lng.dart';
import 'widgets/venue_preview_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final MapProvider _mapProvider;
  MapMarker? _selectedMarker;

  @override
  void initState() {
    super.initState();
    _mapProvider = MapboxProvider();
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(effectiveLocationProvider);
    final venuesAsync = ref.watch(nearbyVenuesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final center = location ?? const AppLatLng(latitude: 30.2672, longitude: -97.7431); // Austin fallback

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

    return Scaffold(
      body: Stack(
        children: [
          _mapProvider.buildMap(
            initialCenter: center,
            initialZoom: 13,
            markers: markers,
            onMarkerTap: (marker) {
              setState(() => _selectedMarker = marker);
            },
            isDarkMode: isDark,
          ),

          // Recenter FAB
          Positioned(
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
          if (_selectedMarker != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VenuePreviewSheet(
                venueId: _selectedMarker!.id,
                venueName: _selectedMarker!.title,
                venueAddress: _selectedMarker!.snippet,
                onClose: () => setState(() => _selectedMarker = null),
              ),
            ),
        ],
      ),
    );
  }
}