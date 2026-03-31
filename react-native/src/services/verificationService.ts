import { AxiosInstance } from 'axios';
import { Logger } from '../core/logger';
import {
  RejectRequest,
  VerificationResult,
  VerificationQueue,
} from '../models/verification';

export class VerificationService {
  private http: AxiosInstance;
  private logger: Logger;

  constructor(http: AxiosInstance, logger: Logger) {
    this.http = http;
    this.logger = logger;
  }

  async verify(reportId: string): Promise<VerificationResult> {
    this.logger.info('Verifying report', { reportId });
    const response = await this.http.post<VerificationResult>(
      `/verification/${reportId}/verify`,
    );
    return response.data;
  }

  async reject(
    reportId: string,
    request: RejectRequest,
  ): Promise<VerificationResult> {
    this.logger.info('Rejecting report', { reportId });
    const response = await this.http.post<VerificationResult>(
      `/verification/${reportId}/reject`,
      request,
    );
    return response.data;
  }

  async getQueue(): Promise<VerificationQueue> {
    const response = await this.http.get<VerificationQueue>(
      '/verification/queue',
    );
    return response.data;
  }
}
