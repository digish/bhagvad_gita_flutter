/// Pure parsing helpers for widget / notification deep links.
/// Kept separate from [DeepLinkService] to avoid circular imports with the router.
class DeepLinkParser {
  static const String uriScheme = 'bhagvadgeeta';
  static const String shlokaHost = 'shloka';

  /// Builds a launch URI like `bhagvadgeeta://shloka/7.13`.
  static Uri uriForShloka(String shlokaId) {
    return Uri(scheme: uriScheme, host: shlokaHost, path: '/$shlokaId');
  }

  /// Extracts `7.13` from widget URIs or raw notification payloads.
  static String? extractShlokaId({Uri? uri, String? payload}) {
    if (payload != null && payload.trim().isNotEmpty) {
      final raw = payload.trim();
      if (_isShlokaId(raw)) return raw;
      final asUri = Uri.tryParse(raw);
      if (asUri != null) {
        final fromUri = _idFromUri(asUri);
        if (fromUri != null) return fromUri;
      }
    }
    if (uri != null) return _idFromUri(uri);
    return null;
  }

  static String? _idFromUri(Uri uri) {
    // bhagvadgeeta://shloka/7.13
    if (uri.host == shlokaHost || uri.host.isEmpty) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty && _isShlokaId(segments.first)) {
        return segments.first;
      }
    }
    final idParam = uri.queryParameters['id'] ?? uri.queryParameters['shloka'];
    if (idParam != null && _isShlokaId(idParam)) return idParam;
    return null;
  }

  static bool _isShlokaId(String value) {
    return RegExp(r'^\d+\.\d+$').hasMatch(value.trim());
  }

  static bool isCustomScheme(Uri uri) {
    final full = uri.toString();
    return uri.scheme == uriScheme || full.startsWith('$uriScheme:');
  }
}
