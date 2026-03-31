import { AxiosInstance } from 'axios';
import { OfflineQueue } from '../core/offlineQueue';
import { Logger } from '../core/logger';
import {
  ReportCreate,
  ReportDetail,
  ReportList,
} from '../models/report';

export interface ReportListParams {
  page?: number;
  pageSize?: number;
  status?: string;
}

export class ReportService {
  private http: AxiosInstance;
  private offlineQueue: OfflineQueue;
  private logger: Logger;

  constructor(
    http: AxiosInstance,
    offlineQueue: OfflineQueue,
    logger: Logger,
  ) {
    this.http = http;
    this.offlineQueue = offlineQueue;
    this.logger = logger;
  }

  async create(report: ReportCreate): Promise<ReportDetail | string> {
    try {
      const response = await this.http.post<ReportDetail>('/reports', report);
      return response.data;
    } catch (error) {
      if (this.isNetworkError(error) && this.offlineQueue.count >= 0) {
        this.logger.info('Network unavailable, queuing report creation');
        const queueId = await this.offlineQueue.enqueue({
          method: 'post',
          url: '/reports',
          data: report,
        });
        return queueId;
      }
      throw error;
    }
  }

  async list(params?: ReportListParams): Promise<ReportList> {
    const response = await this.http.get<ReportList>('/reports', {
      params,
    });
    return response.data;
  }

  async getById(id: string): Promise<ReportDetail> {
    const response = await this.http.get<ReportDetail>(`/reports/${id}`);
    return response.data;
  }

  async getByPlate(plate: string): Promise<ReportList> {
    const response = await this.http.get<ReportList>(
      `/reports/by-plate/${encodeURIComponent(plate)}`,
    );
    return response.data;
  }

  async delete(id: string): Promise<void> {
    await this.http.delete(`/reports/${id}`);
  }

  private isNetworkError(error: unknown): boolean {
    if (error && typeof error === 'object' && 'code' in error) {
      return (error as { code: string }).code === 'ERR_NETWORK';
    }
    return false;
  }
}
