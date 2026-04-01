import '../core/http_client.dart';
import '../models/infraction.dart';

/// Service for retrieving the catalogue of infraction types.
/// Results are cached in memory after the first fetch.
class InfractionService {
  InfractionService({required MultandoHttpClient httpClient})
      : _http = httpClient;

  final MultandoHttpClient _http;
  List<InfractionResponse>? _cache;

  /// List all available infraction types.
  ///
  /// Returns a cached result if available. Pass [forceRefresh] to bypass
  /// the cache.
  Future<List<InfractionResponse>> list({bool forceRefresh = false}) async {
    if (_cache != null && !forceRefresh) return _cache!;

    final response = await _http.get<dynamic>('/infractions');
    final data = response.data;

    List items;
    if (data is Map<String, dynamic>) {
      items = data['items'] as List? ?? [];
    } else if (data is List) {
      items = data;
    } else {
      items = [];
    }

    _cache = items
        .cast<Map<String, dynamic>>()
        .map(InfractionResponse.fromJson)
        .toList();
    return _cache!;
  }

  /// Invalidate the in-memory cache.
  void clearCache() {
    _cache = null;
  }
}
