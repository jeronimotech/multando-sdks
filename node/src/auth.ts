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
}
