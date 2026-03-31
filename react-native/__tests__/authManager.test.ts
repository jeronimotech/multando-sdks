import AsyncStorage from '@react-native-async-storage/async-storage';
import { AuthManager } from '../src/core/authManager';
import { Logger } from '../src/core/logger';
import { LogLevel } from '../src/models/enums';
import type { TokenResponse } from '../src/models/auth';

jest.mock('@react-native-async-storage/async-storage', () => ({
  getItem: jest.fn(() => Promise.resolve(null)),
  setItem: jest.fn(() => Promise.resolve()),
  removeItem: jest.fn(() => Promise.resolve()),
}));

jest.mock('axios', () => {
  return {
    create: jest.fn(() => ({
      post: jest.fn(),
      interceptors: {
        request: { use: jest.fn() },
        response: { use: jest.fn() },
      },
    })),
  };
});

const sampleTokens: TokenResponse = {
  accessToken: 'access-token-123',
  refreshToken: 'refresh-token-456',
  tokenType: 'Bearer',
  expiresIn: 3600,
};

describe('AuthManager', () => {
  let manager: AuthManager;
  let logger: Logger;

  beforeEach(() => {
    jest.clearAllMocks();
    logger = new Logger(LogLevel.None);
    manager = new AuthManager(
      'https://api.test.multando.io',
      'test-api-key',
      logger,
    );
  });

  describe('initial state', () => {
    it('is not authenticated initially', () => {
      expect(manager.isAuthenticated).toBe(false);
    });

    it('has null currentUser initially', () => {
      expect(manager.currentUser).toBeNull();
    });

    it('returns null for refresh token initially', () => {
      expect(manager.getRefreshTokenValue()).toBeNull();
    });
  });

  describe('initialize', () => {
    it('loads tokens from AsyncStorage', async () => {
      await manager.initialize();

      expect(AsyncStorage.getItem).toHaveBeenCalledWith('@multando/access_token');
      expect(AsyncStorage.getItem).toHaveBeenCalledWith('@multando/refresh_token');
      expect(AsyncStorage.getItem).toHaveBeenCalledWith('@multando/token_expiry');
      expect(AsyncStorage.getItem).toHaveBeenCalledWith('@multando/user_profile');
    });

    it('is idempotent', async () => {
      await manager.initialize();
      await manager.initialize();

      // getItem should only have been called once per key (4 keys total)
      expect(AsyncStorage.getItem).toHaveBeenCalledTimes(4);
    });
  });

  describe('setTokens', () => {
    it('stores tokens in AsyncStorage', async () => {
      await manager.setTokens(sampleTokens);

      expect(AsyncStorage.setItem).toHaveBeenCalledWith(
        '@multando/access_token',
        'access-token-123',
      );
      expect(AsyncStorage.setItem).toHaveBeenCalledWith(
        '@multando/refresh_token',
        'refresh-token-456',
      );
      expect(AsyncStorage.setItem).toHaveBeenCalledWith(
        '@multando/token_expiry',
        expect.any(String),
      );
    });

    it('marks manager as authenticated', async () => {
      await manager.setTokens(sampleTokens);
      expect(manager.isAuthenticated).toBe(true);
    });
  });

  describe('clearTokens', () => {
    it('removes tokens from AsyncStorage', async () => {
      await manager.setTokens(sampleTokens);
      await manager.clearTokens();

      expect(AsyncStorage.removeItem).toHaveBeenCalledWith('@multando/access_token');
      expect(AsyncStorage.removeItem).toHaveBeenCalledWith('@multando/refresh_token');
      expect(AsyncStorage.removeItem).toHaveBeenCalledWith('@multando/token_expiry');
      expect(AsyncStorage.removeItem).toHaveBeenCalledWith('@multando/user_profile');
    });

    it('marks manager as not authenticated', async () => {
      await manager.setTokens(sampleTokens);
      expect(manager.isAuthenticated).toBe(true);

      await manager.clearTokens();
      expect(manager.isAuthenticated).toBe(false);
    });

    it('sets currentUser to null', async () => {
      await manager.clearTokens();
      expect(manager.currentUser).toBeNull();
    });
  });

  describe('isTokenExpired', () => {
    it('returns true when no token expiry is set', () => {
      expect(manager.isTokenExpired()).toBe(true);
    });

    it('returns false when token was just set with long expiry', async () => {
      await manager.setTokens(sampleTokens);
      expect(manager.isTokenExpired()).toBe(false);
    });

    it('returns true when token has very short expiry (within buffer)', async () => {
      const shortLivedTokens: TokenResponse = {
        ...sampleTokens,
        expiresIn: 30, // 30 seconds, within the 60s buffer
      };
      await manager.setTokens(shortLivedTokens);
      expect(manager.isTokenExpired()).toBe(true);
    });
  });

  describe('onAuthStateChange', () => {
    it('immediately emits current state to new listener', () => {
      const states: any[] = [];
      manager.onAuthStateChange((state) => states.push(state));

      expect(states).toHaveLength(1);
      expect(states[0].isAuthenticated).toBe(false);
    });

    it('emits when tokens are set', async () => {
      const states: any[] = [];
      manager.onAuthStateChange((state) => states.push(state));

      await manager.setTokens(sampleTokens);

      expect(states.length).toBeGreaterThanOrEqual(2);
      expect(states[states.length - 1].isAuthenticated).toBe(true);
    });

    it('returns an unsubscribe function', async () => {
      const states: any[] = [];
      const unsub = manager.onAuthStateChange((state) => states.push(state));

      unsub();
      await manager.setTokens(sampleTokens);

      // Only the initial emit should be recorded.
      expect(states).toHaveLength(1);
    });
  });

  describe('getState', () => {
    it('returns expected initial state', () => {
      const state = manager.getState();
      expect(state.isAuthenticated).toBe(false);
      expect(state.user).toBeNull();
    });
  });
});
