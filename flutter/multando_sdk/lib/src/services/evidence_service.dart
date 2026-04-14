import '../core/http_client.dart';
import '../models/evidence.dart';

/// Service for attaching evidence to reports.
class EvidenceService {
  EvidenceService({required MultandoHttpClient httpClient})
      : _http = httpClient;

  final MultandoHttpClient _http;

  /// Get a presigned URL for private evidence access.
  Future<String> getPresignedUrl(int evidenceId) async {
    final response = await _http.get<Map<String, dynamic>>(
      '/reports/evidence/$evidenceId/url',
    );
    return response.data!['url'] as String;
  }

  /// Add evidence to an existing report.
  ///
  /// The API accepts `type`, `url`, and `mime_type` as query parameters.
  Future<EvidenceResponse> addEvidence(
    String reportId,
    EvidenceCreate evidence,
  ) async {
    final response = await _http.post<Map<String, dynamic>>(
      '/reports/$reportId/evidence',
      queryParameters: {
        'type': evidence.type.value,
        'url': evidence.url,
        'mime_type': evidence.mimeType,
      },
    );
    return EvidenceResponse.fromJson(response.data!);
  }
}
