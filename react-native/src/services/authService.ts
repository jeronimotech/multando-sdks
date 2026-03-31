import { AxiosInstance } from 'axios';
import { AuthManager } from '../core/authManager';
import {
  RegisterRequest,
  LoginRequest,
  TokenResponse,
  WalletLinkRequest,
} from '../models/auth';
import { UserProfile } from '../models/user';
import { Logger } from '../core/logger';

export class AuthService {
  private http: AxiosInstance;
  private authManager: AuthManager;
  private logger: Logger;

  constructor(
    http: AxiosInstance,
    authManager: AuthManager,
    logger: Logger,
  ) {
    this.http = http;
    this.authManager = authManager;
    this.logger = logger;
  }

  async register(request: RegisterRequest): Promise<UserProfile> {
    this.logger.info('Registering new user');
    const response = await this.http.post<TokenResponse>(
      '/auth/register',
      request,
    );
    await this.authManager.setTokens(response.data);

    const profile = await this.getMe();
    return profile;
  }

  async login(request: LoginRequest): Promise<UserProfile> {
    this.logger.info('Logging in user');
    const response = await this.http.post<TokenResponse>(
      '/auth/login',
      request,
    );
    await this.authManager.setTokens(response.data);

    const profile = await this.getMe();
    return profile;
  }

  async refresh(): Promise<TokenResponse> {
    const refreshToken = this.authManager.getRefreshTokenValue();
    if (!refreshToken) {
      throw new Error('No refresh token available');
    }
    const response = await this.http.post<TokenResponse>('/auth/refresh', {
      refreshToken,
    });
    await this.authManager.setTokens(response.data);
    return response.data;
  }

  async getMe(): Promise<UserProfile> {
    const response = await this.http.get<UserProfile>('/auth/me');
    await this.authManager.setUser(response.data);
    return response.data;
  }

  async linkWallet(request: WalletLinkRequest): Promise<UserProfile> {
    this.logger.info('Linking wallet');
    const response = await this.http.post<UserProfile>(
      '/auth/link-wallet',
      request,
    );
    await this.authManager.setUser(response.data);
    return response.data;
  }

  async logout(): Promise<void> {
    this.logger.info('Logging out user');
    await this.authManager.clearTokens();
  }

  get isAuthenticated(): boolean {
    return this.authManager.isAuthenticated;
  }

  get currentUser(): UserProfile | null {
    return this.authManager.currentUser;
  }

  onAuthStateChange(listener: (state: { isAuthenticated: boolean; isLoading: boolean; user: UserProfile | null }) => void): () => void {
    return this.authManager.onAuthStateChange(listener);
  }
}
