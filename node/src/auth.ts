/**
 * Auth service for the Multando API.
 */

import { HttpClient } from './http.js';
import type {
  RegisterRequest,
  SocialLoginOptions,
  TokenResponse,
  User,
} from './models.js';

export class AuthService {
  constructor(private readonly http: HttpClient) {}

  async register(data: RegisterRequest): Promise<TokenResponse> {
    return this.http.post<TokenResponse>('/auth/register', data);
  }

  async login(email: string, password: string): Promise<TokenResponse> {
    return this.http.post<TokenResponse>('/auth/login', { email, password });
  }

  async socialLogin(options: SocialLoginOptions): Promise<TokenResponse> {
    const { provider, ...body } = options;
    return this.http.post<TokenResponse>(`/auth/oauth/${provider}`, body);
  }

  async refresh(refreshToken: string): Promise<TokenResponse> {
    return this.http.post<TokenResponse>('/auth/refresh', { refresh_token: refreshToken });
  }

  async me(): Promise<User> {
    return this.http.get<User>('/auth/me');
  }

  async logout(): Promise<void> {
    await this.http.post<unknown>('/auth/logout');
  }

  /** Exchange an OAuth authorization code for tokens. */
  async exchangeOAuthCode(code: string, redirectUri: string): Promise<TokenResponse> {
    return this.http.post<TokenResponse>('/oauth/token', {
      grant_type: 'authorization_code',
      code,
      client_id: (this.http as any).apiKey ?? '',
      redirect_uri: redirectUri,
    });
  }

  /**
   * Build the OAuth authorization URL for the Multando consent screen.
   * Open this in a browser; the user authorizes and gets redirected
   * back to `redirectUri` with a `code` query parameter.
   */
  buildAuthorizeUrl(options: {
    redirectUri: string;
    scope?: string;
    state?: string;
  }): string {
    const { redirectUri, scope = 'reports:create,reports:read,infractions:read,balance:read', state } = options;
    const baseUrl = (this.http as any).baseUrl as string ?? '';
    // Derive web frontend URL from API URL
    let webUrl: string;
    if (baseUrl.includes('multando.com')) {
      webUrl = 'https://www.multando.com';
    } else {
      webUrl = baseUrl.replace(/:\d+/, ':3000').replace(/\/api\/v1$/, '');
    }
    const params = new URLSearchParams({
      client_id: (this.http as any).apiKey ?? '',
      redirect_uri: redirectUri,
      scope,
      response_type: 'code',
      api_base: baseUrl,
    });
    if (state) params.set('state', state);
    return `${webUrl}/oauth/authorize?${params}`;
  }
}
