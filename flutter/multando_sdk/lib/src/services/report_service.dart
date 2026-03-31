import '../core/http_client.dart';
import '../core/offline_queue.dart';
import '../models/error.dart';
import '../models/report.dart';

/// Service for creating, listing, and managing infraction reports.
class ReportService {
  ReportService({
    required MultandoHttpClient httpClient,
    OfflineQueue? offlineQueue,
  })  : _http = httpClient,
        _offlineQueue = offlineQueue;

  final MultandoHttpClient _http;
  final OfflineQueue? _offlineQueue;

  /// Create a new infraction report.
  ///
  /// If the device is offline and the offline queue is enabled, the report
  /// is queued locally and `null` is returned instead of a [ReportDetail].
  Future<ReportDetail?> create(ReportCreate report) async {
    try {
      final response = await _http.post<Map<String, dynamic>>(
        '/reports',
        data: report.toJson(),
      );
      return ReportDetail.fromJson(response.data!);
    } on MultandoNetworkError {
      if (_offlineQueue != null) {
        await _offlineQueue!.enqueue(report);
        return null;
      }
      rethrow;
    }
  }

  /// List reports with pagination.
  Future<ReportList> list({
    int page = 1,
    int pageSize = 20,
    Map<String, dynamic>? filters,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      ...?filters,
    };
    final response = await _http.get<Map<String, dynamic>>(
      '/reports',
      queryParameters: params,
    );
    return ReportList.fromJson(response.data!);
  }

  /// Get a single report by ID.
  Future<ReportDetail> getById(String id) async {
    final response = await _http.get<Map<String, dynamic>>('/reports/$id');
    return ReportDetail.fromJson(response.data!);
  }

  /// Get all reports for a given license plate.
  Future<List<ReportSummary>> getByPlate(String plate) async {
    final response = await _http.get<List<dynamic>>('/reports/by-plate/$plate');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(ReportSummary.fromJson)
        .toList();
  }

  /// Delete a report by ID.
  Future<void> delete(String id) async {
    await _http.delete<void>('/reports/$id');
  }
}
