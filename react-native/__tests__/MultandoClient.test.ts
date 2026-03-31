import { MultandoClient } from '../src/core/MultandoClient';
import type { MultandoConfig } from '../src/core/config';
import { LogLevel, Locale } from '../src/models/enums';

// Mock AsyncStorage
jest.mock('@react-native-async-storage/async-storage', () => ({
  getItem: jest.fn(() => Promise.resolve(null)),
  setItem: jest.fn(() => Promise.resolve()),
  removeItem: jest.fn(() => Promise.resolve()),
  multiGet: jest.fn(() => Promise.resolve([])),
  multiSet: jest.fn(() => Promise.resolve()),
}));

// Mock NetInfo
jest.mock('@react-native-community/netinfo', () => ({
  addEventListener: jest.fn(() => jest.fn()),
  fetch: jest.fn(() =>
    Promise.resolve({ isConnected: true, isInternetReachable: true }),
  ),
}));

// Mock axios
jest.mock('axios', () => {
  const mockInstance = {
    get: jest.fn(() => Promise.resolve({ data: {} })),
    post: jest.fn(() => Promise.resolve({ data: {} })),
    put: jest.fn(() => Promise.resolve({ data: {} })),
    delete: jest.fn(() => Promise.resolve({ data: {} })),
    interceptors: {
      request: { use: jest.fn() },
      response: { use: jest.fn() },
    },
  };
  return {
    create: jest.fn(() => mockInstance),
    default: { create: jest.fn(() => mockInstance) },
  };
});

const TEST_CONFIG: MultandoConfig = {
  baseUrl: 'https://api.test.multando.io',
  apiKey: 'test-api-key',
  locale: Locale.En,
  logLevel: LogLevel.None,
};

describe('MultandoClient', () => {
  let client: MultandoClient;

  beforeEach(() => {
    client = new MultandoClient(TEST_CONFIG);
  });

  afterEach(() => {
    client.dispose();
  });

  describe('construction', () => {
    it('creates a client without throwing', () => {
      expect(client).toBeDefined();
    });

    it('starts as not initialized', () => {
      expect(client.isInitialized).toBe(false);
    });

    it('starts as not authenticated', () => {
      expect(client.isAuthenticated).toBe(false);
    });

    it('has null currentUser initially', () => {
      expect(client.currentUser).toBeNull();
    });

    it('has zero offline queue count', () => {
      expect(client.offlineQueueCount).toBe(0);
    });
  });

  describe('initialize', () => {
    it('sets isInitialized to true', async () => {
      await client.initialize();
      expect(client.isInitialized).toBe(true);
    });

    it('is idempotent', async () => {
      await client.initialize();
      await client.initialize();
      expect(client.isInitialized).toBe(true);
    });

    it('emits initialized event', async () => {
      const events: string[] = [];
      client.onEvent((event) => events.push(event));
      await client.initialize();
      expect(events).toContain('initialized');
    });
  });

  describe('service accessors', () => {
    it('exposes auth service', () => {
      expect(client.auth).toBeDefined();
    });

    it('exposes reports service', () => {
      expect(client.reports).toBeDefined();
    });

    it('exposes evidence service', () => {
      expect(client.evidence).toBeDefined();
    });

    it('exposes infractions service', () => {
      expect(client.infractions).toBeDefined();
    });

    it('exposes vehicleTypes service', () => {
      expect(client.vehicleTypes).toBeDefined();
    });

    it('exposes verification service', () => {
      expect(client.verification).toBeDefined();
    });

    it('exposes blockchain service', () => {
      expect(client.blockchain).toBeDefined();
    });
  });

  describe('onEvent', () => {
    it('returns an unsubscribe function', () => {
      const unsub = client.onEvent(() => {});
      expect(typeof unsub).toBe('function');
      unsub();
    });

    it('does not call listener after unsubscribe', async () => {
      const events: string[] = [];
      const unsub = client.onEvent((event) => events.push(event));
      unsub();
      await client.initialize();
      expect(events).not.toContain('initialized');
    });
  });

  describe('dispose', () => {
    it('resets isInitialized to false', async () => {
      await client.initialize();
      expect(client.isInitialized).toBe(true);
      client.dispose();
      expect(client.isInitialized).toBe(false);
    });

    it('is safe to call multiple times', () => {
      client.dispose();
      client.dispose();
      expect(client.isInitialized).toBe(false);
    });
  });
});
