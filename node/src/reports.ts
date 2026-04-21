/**
 * Reports service for the Multando API.
 */

import { HttpClient } from './http.js';
import type { CreateReportRequest, PaginatedResponse, Report } from './models.js';

export interface ReportListOptions {
  page?: number;
  pageSize?: number;
  status?: string;
}

export class ReportsService {
  constructor(private readonly http: HttpClient) {}

  async create(data: CreateReportRequest): Promise<Report> {
    return this.http.post<Report>('/reports', data);
  }

  async list(options?: ReportListOptions): Promise<PaginatedResponse<Report>> {
    const params: Record<string, string> = {};
    if (options?.page !== undefined) params.page = String(options.page);
    if (options?.pageSize !== undefined) params.page_size = String(options.pageSize);
    if (options?.status) params.status = options.status;
    return this.http.get<PaginatedResponse<Report>>('/reports', params);
  }

  async get(reportId: string): Promise<Report> {
    return this.http.get<Report>(`/reports/${reportId}`);
  }

  async getByPlate(plate: string): Promise<Report[]> {
    return this.http.get<Report[]>(`/reports/by-plate/${encodeURIComponent(plate)}`);
  }

  async delete(reportId: string): Promise<void> {
    await this.http.delete<unknown>(`/reports/${reportId}`);
  }
}
