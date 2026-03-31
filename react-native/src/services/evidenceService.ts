import { AxiosInstance } from 'axios';
import { Logger } from '../core/logger';
import { EvidenceCreate, EvidenceResponse } from '../models/evidence';

export class EvidenceService {
  private http: AxiosInstance;
  private logger: Logger;

  constructor(http: AxiosInstance, logger: Logger) {
    this.http = http;
    this.logger = logger;
  }

  async addEvidence(
    reportId: string,
    evidence: EvidenceCreate,
  ): Promise<EvidenceResponse> {
    this.logger.debug('Adding evidence to report', { reportId });
    // The API accepts type, url, mime_type as query params
    const response = await this.http.post<EvidenceResponse>(
      `/reports/${reportId}/evidence`,
      null,
      {
        params: {
          type: evidence.type,
          url: evidence.url,
          mimeType: evidence.mimeType,
        },
      },
    );
    return response.data;
  }
}
