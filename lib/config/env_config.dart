/// Access tokens and config via --dart-define.
/// Build with:
///   flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.xxx
///   flutter run --dart-define=MAPBOX_STYLE_LIGHT=mapbox://styles/...
///   flutter run --dart-define=MAPBOX_STYLE_DARK=mapbox://styles/...
class EnvConfig {
  static const mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: '',
  );

  static const mapboxStyleLight = String.fromEnvironment(
    'MAPBOX_STYLE_LIGHT',
    defaultValue: 'mapbox://styles/mapbox/light-v11',
  );

  static const mapboxStyleDark = String.fromEnvironment(
    'MAPBOX_STYLE_DARK',
    defaultValue: 'mapbox://styles/mapbox/dark-v11',
  );
}