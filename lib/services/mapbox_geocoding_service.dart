import 'dart:convert';
import 'dart:io';

import '../config/env_config.dart';

class GeocodingResult {
  final double latitude;
  final double longitude;
  final String formattedAddress;

  const GeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
  });
}

class MapboxGeocodingService {
  final HttpClient _client;

  MapboxGeocodingService({HttpClient? client})
      : _client = client ?? HttpClient();

  Future<GeocodingResult?> geocodeAddress(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return null;

    final uri = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/'
      '${Uri.encodeComponent(trimmed)}.json'
      '?access_token=${Uri.encodeQueryComponent(EnvConfig.mapboxAccessToken)}'
      '&limit=1'
      '&country=US',
    );

    final request = await _client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final body = await response.transform(utf8.decoder).join();
    final jsonMap = jsonDecode(body) as Map<String, dynamic>;
    final features = jsonMap['features'] as List<dynamic>? ?? const [];
    if (features.isEmpty) return null;

    final first = features.first as Map<String, dynamic>;
    final center = first['center'] as List<dynamic>? ?? const [];
    if (center.length < 2) return null;

    final lng = (center[0] as num?)?.toDouble();
    final lat = (center[1] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    return GeocodingResult(
      latitude: lat,
      longitude: lng,
      formattedAddress: (first['place_name'] ?? trimmed).toString(),
    );
  }
}
