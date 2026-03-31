import AsyncStorage from '@react-native-async-storage/async-storage';
import axios, { AxiosInstance } from 'axios';
import { TokenResponse } from '../models/auth';
import { UserProfile } from '../models/user';
import { Logger } from './logger';

const STORAGE_KEYS = {
  ACCESS_TOKEN: '@multando/access_token',
  REFRESH_TOKEN: '@multando/refresh_token',
  TOKEN_EXPIRY: '@multando/token_expiry',
  USER_PROFILE: '@multando/user_profile',
} as const;

export type AuthState = {
  isAuthenticated: boolean;
  isLoading: boolean;
  user: UserProfile | null;
};

type AuthStateListener = (state: AuthState) => void;

export class AuthManager {
  private accessToken: string | null = null;
  private refreshToken: string | null = null;
  private tokenExpiry: number | null = null;
  private user: UserProfile | null = null;
  private listeners: Set<AuthStateListener> = new Set();
  private initialized = false;
  private baseUrl: string;
  private apiKey: string;
  private logger: Logger;

  constructor(baseUrl: string, apiKey: string, logger: Logger) {
    this.baseUrl = baseUrl;
    this.apiKey = apiKey;
    this.logger = logger;
  }

  async initialize(): Promise<void> {
    if (this.initialized) return;

    try {
      const [accessToken, refreshToken, expiryStr, userStr] =
        await Promise.all([
          AsyncStorage.getItem(STORAGE_KEYS.ACCESS_TOKEN),
          AsyncStorage.getItem(STORAGE_KEYS.REFRESH_TOKEN),
          AsyncStorage.getItem(STORAGE_KEYS.TOKEN_EXPIRY),
          AsyncStorage.getItem(STORAGE_KEYS.USER_PROFILE),
        ]);

      this.accessToken = accessToken;
      this.refreshToken = refreshToken;
      this.tokenExpiry = expiryStr ? parseInt(expiryStr, 10) : null;
      this.user = userStr ? JSON.parse(userStr) : null;

      if (this.accessToken && this.isTokenExpired()) {
        try {
          await this.refreshAccessToken();
        } catch {
          this.logger.warn('Failed to refresh token on init, clearing tokens');
          await this.clearTokens();
        }
      }

      this.initialized = true;
      this.notifyListeners();
    } catch (error) {
      this.logger.error('Failed to initialize auth manager', error);
      this.initialized = true;
      this.notifyListeners();
    }
  }

  async getAccessToken(): Promise<string | null> {
    if (this.accessToken && this.isTokenExpired()) {
      try {
        await this.refreshAccessToken();
      } catch {
        return null;
      }
    }
    return this.accessToken;
  }

  getRefreshTokenValue(): string | null {
    return this.refreshToken;
  }

  isTokenExpired(): boolean {
    if (!this.tokenExpiry) return true;
    return Date.now() >= this.tokenExpiry - 60000; // 1 minute buffer
  }

  get isAuthenticated(): boolean {
    return this.accessToken !== null && !this.isTokenExpired();
  }

  get currentUser(): UserProfile | null {
    return this.user;
  }

  async setTokens(response: TokenResponse): Promise<void> {
    this.accessToken = response.accessToken;
    this.refreshToken = response.refreshToken;
    this.tokenExpiry = Date.now() + response.expiresIn * 1000;

    await Promise.all([
      AsyncStorage.setItem(STORAGE_KEYS.ACCESS_TOKEN, this.accessToken),
      AsyncStorage.setItem(STORAGE_KEYS.REFRESH_TOKEN, this.refreshToken),
      AsyncStorage.setItem(
        STORAGE_KEYS.TOKEN_EXPIRY,
        this.tokenExpiry.toString(),
      ),
    ]);

    this.notifyListeners();
  }

  async setUser(user: UserProfile): Promise<void> {
    this.user = user;
    await AsyncStorage.setItem(
      STORAGE_KEYS.USER_PROFILE,
      JSON.stringify(user),
    );
    this.notifyListeners();
  }

  async refreshAccessToken(): Promise<void> {
    if (!this.refreshToken) {
      throw new Error('No refresh token available');
    }

    this.logger.debug('Refreshing access token');

    const client = axios.create({
      baseURL: `${this.baseUrl}/api/v1`,
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': this.apiKey,
      },
    });

    const response = await client.post<{
      access_token: string;
      refresh_token: string;
      token_type: string;
      expires_in: number;
    }>('/auth/refresh', {
      refresh_token: this.refreshToken,
    });

    const tokenResponse: TokenResponse = {
      accessToken: response.data.access_token,
      refreshToken: response.data.refresh_token,
      tokenType: response.data.token_type,
      expiresIn: response.data.expires_in,
    };

    await this.setTokens(tokenResponse);
    this.logger.info('Access token refreshed successfully');
  }

  async clearTokens(): Promise<void> {
    this.accessToken = null;
    this.refreshToken = null;
    this.tokenExpiry = null;
    this.user = null;

    await Promise.all([
      AsyncStorage.removeItem(STORAGE_KEYS.ACCESS_TOKEN),
      AsyncStorage.removeItem(STORAGE_KEYS.REFRESH_TOKEN),
      AsyncStorage.removeItem(STORAGE_KEYS.TOKEN_EXPIRY),
      AsyncStorage.removeItem(STORAGE_KEYS.USER_PROFILE),
    ]);

    this.notifyListeners();
  }

  onAuthStateChange(listener: AuthStateListener): () => void {
    this.listeners.add(listener);
    // Immediately emit current state
    listener(this.getState());
    return () => {
      this.listeners.delete(listener);
    };
  }

  getState(): AuthState {
    return {
      isAuthenticated: this.isAuthenticated,
      isLoading: !this.initialized,
      user: this.user,
    };
  }

  private notifyListeners(): void {
    const state = this.getState();
    this.listeners.forEach((listener) => listener(state));
  }

  /** Expose a raw axios instance for the auth service (bypasses main interceptors). */
  createRawClient(): AxiosInstance {
    return axios.create({
      baseURL: `${this.baseUrl}/api/v1`,
      headers: {
        'Content-Type': 'application/json',
        'X-API-Key': this.apiKey,
      },
    });
  }
}
