/// App-owned coordinate type. Decouples from Mapbox / Google / any SDK.
class AppLatLng {
  final double latitude;
  final double longitude;

  const AppLatLng({required this.latitude, required this.longitude});

  factory AppLatLng.fromMap(Map<String, dynamic> map) {
    return AppLatLng(
      latitude: (map['lat'] as num).toDouble(),
      longitude: (map['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {'lat': latitude, 'lng': longitude};

  @override
  String toString() => 'AppLatLng($latitude, $longitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLatLng &&
          other.latitude == latitude &&
          other.longitude == longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}