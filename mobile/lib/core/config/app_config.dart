/// Build-time configuration, supplied via --dart-define (no secrets in code).
class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api',
  );

  /// Flavor: dev | prod. Drives logging verbosity etc.
  static const String flavor = String.fromEnvironment('APP_FLAVOR', defaultValue: 'dev');

  /// Static uploads are served from the API origin with the /api suffix stripped
  /// (mirrors Angular `toFileUrl()` in admin.service.ts).
  static String get uploadsBaseUrl =>
      apiBaseUrl.endsWith('/api') ? apiBaseUrl.substring(0, apiBaseUrl.length - 4) : apiBaseUrl;

  /// Mirrors Angular toFileUrl(): percent-encodes each path segment separately
  /// (Bengali upload paths), preserving slashes.
  static String fileUrl(String rawPath) {
    final path = rawPath.startsWith('/') ? rawPath : '/$rawPath';
    final encoded = path
        .split('/')
        .map((seg) => seg.isEmpty ? seg : Uri.encodeComponent(seg))
        .join('/');
    return '$uploadsBaseUrl$encoded';
  }
  /// Street basemap tiles (default: OpenStreetMap). Supply via --dart-define
  /// in production to respect the tile provider's usage policy.
  static const String mapTileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// Satellite basemap tiles (default: Esri World Imagery).
  static const String satelliteTileUrl = String.fromEnvironment(
    'SATELLITE_TILE_URL',
    defaultValue:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  );

  /// Society extent as `minLng,minLat,maxLng,maxLat` (plot-map initial camera
  /// and client-side inside-society validation). Empty when not configured.
  static const String societyBboxRaw =
      String.fromEnvironment('SOCIETY_BBOX', defaultValue: '');
}
