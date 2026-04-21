/**
 * Main client for the Multando API.
 */

import { HttpClient } from './http.js';
import { AuthService } from './auth.js';
import { ReportsService } from './reports.js';
import { InfractionsService } from './infractions.js';
import { WalletService } from './wallet.js';
import type { TokenResponse } from './models.js';

export interface MultandoClientOptions {
  /** Base URL of the Multando API. Defaults to https://api.multando.com/api/v1 */
  baseUrl?: string;
  /** API key for server-to-server authentication. */
  apiKey?: string;
}

const DEFAULT_BASE_URL = 'https://api.multando.com/api/v1';

export class MultandoClient {
  private readonly http: HttpClient;

  readonly auth: AuthService;
  readonly reports: ReportsService;
  readonly infractions: InfractionsService;
  readonly wallet: WalletService;

  constructor(options: MultandoClientOptions = {}) {
    this.http = new HttpClient(options.baseUrl ?? DEFAULT_BASE_URL, options.apiKey);
    this.auth = new AuthService(this.http);
    this.reports = new ReportsService(this.http);
    this.infractions = new InfractionsService(this.http);
    this.wallet = new WalletService(this.http);
  }

  /**
   * Convenience method: logs in and stores the access token for
   * subsequent authenticated requests.
   */
  async login(email: string, password: string): Promise<TokenResponse> {
    const tokens = await this.auth.login(email, password);
    this.http.setAccessToken(tokens.access_token);
    return tokens;
  }

  /**
   * Set the access token directly (e.g. from a stored refresh flow).
   */
  setAccessToken(token: string): void {
    this.http.setAccessToken(token);
  }
}
