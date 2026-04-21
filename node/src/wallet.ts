/**
 * Wallet service for the Multando API.
 */

import { HttpClient } from './http.js';
import type { Activity, PaginatedResponse, WalletBalance } from './models.js';

export class WalletService {
  constructor(private readonly http: HttpClient) {}

  async balance(): Promise<WalletBalance> {
    return this.http.get<WalletBalance>('/wallet/info');
  }

  async activities(page?: number): Promise<PaginatedResponse<Activity>> {
    const params: Record<string, string> = {};
    if (page !== undefined) params.page = String(page);
    return this.http.get<PaginatedResponse<Activity>>('/wallet/activities', params);
  }
}
