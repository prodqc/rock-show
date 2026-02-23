class AppConstants {
  static const String appName = 'RockShow';
  static const int nearbyRadiusMeters = 25000; // 25 km
  static const int geohashPrecision = 5;
  static const int maxLineupActs = 20;
  static const int maxPhotos = 10;
  static const int paginationLimit = 20;
  static const double defaultLat = 40.7128;
  static const double defaultLng = -74.0060;
  static const List<String> genres = [
    'Rock', 'Punk', 'Metal', 'Indie', 'Alternative',
    'Hardcore', 'Emo', 'Ska', 'Garage', 'Psychedelic',
    'Grunge', 'Post-Punk', 'Shoegaze', 'Noise', 'Stoner',
    'Doom', 'Thrash', 'Pop-Punk', 'Math Rock', 'Post-Rock',
  ];
}