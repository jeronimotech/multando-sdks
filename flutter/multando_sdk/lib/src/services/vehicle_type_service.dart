import '../core/http_client.dart';
import '../models/vehicle_type.dart';

/// Service for retrieving vehicle type reference data.
/// Results are cached in memory after the first fetch.
class VehicleTypeService {
  VehicleTypeService({required MultandoHttpClient httpClient})
      : _http = httpClient;

  final MultandoHttpClient _http;
  List<VehicleTypeResponse>? _cache;

  /// List all available vehicle types.
  Future<List<VehicleTypeResponse>> list({bool forceRefresh = false}) async {
    if (_cache != null && !forceRefresh) return _cache!;

    final response = await _http.get<dynamic>('/vehicle-types');
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
        .map(VehicleTypeResponse.fromJson)
        .toList();
    return _cache!;
  }

  /// Invalidate the in-memory cache.
  void clearCache() {
    _cache = null;
  }
}
