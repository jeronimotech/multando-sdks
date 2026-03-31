import '../core/http_client.dart';
import '../models/report.dart';
import '../models/verification.dart';

/// Service for the community-verification workflow.
class VerificationService {
  VerificationService({required MultandoHttpClient httpClient})
      : _http = httpClient;

  final MultandoHttpClient _http;

  /// Mark a report as verified.
  Future<ReportDetail> verify(String reportId) async {
    final response = await _http.post<Map<String, dynamic>>(
      '/verification/$reportId/verify',
    );
    return ReportDetail.fromJson(response.data!);
  }

  /// Reject a report with a reason.
  Future<ReportDetail> reject(String reportId, RejectRequest request) async {
    final response = await _http.post<Map<String, dynamic>>(
      '/verification/$reportId/reject',
      data: request.toJson(),
    );
    return ReportDetail.fromJson(response.data!);
  }

  /// Retrieve the queue of reports awaiting verification.
  Future<List<ReportSummary>> getQueue({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _http.get<Map<String, dynamic>>(
      '/verification/queue',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );
    final items = response.data!['items'] as List? ?? [];
    return items
        .cast<Map<String, dynamic>>()
        .map(ReportSummary.fromJson)
        .toList();
  }
}
