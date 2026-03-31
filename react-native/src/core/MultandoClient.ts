import { MultandoConfig, resolveConfig } from './config';
import { createHttpClient } from './httpClient';
import { AuthManager } from './authManager';
import { OfflineQueue } from './offlineQueue';
import { Logger } from './logger';
import { AuthService } from '../services/authService';
import { ReportService } from '../services/reportService';
import { EvidenceService } from '../services/evidenceService';
import { InfractionService } from '../services/infractionService';
import { VehicleTypeService } from '../services/vehicleTypeService';
import { VerificationService } from '../services/verificationService';
import { BlockchainService } from '../services/blockchainService';
import { ChatService } from '../services/chatService';
import { UserProfile } from '../models/user';

export type MultandoEventType =
  | 'initialized'
  | 'auth_state_changed'
  | 'offline_queue_changed'
  | 'error';

type MultandoEventListener = (
  event: MultandoEventType,
  data?: unknown,
) => void;

export class MultandoClient {
  private config: Required<MultandoConfig>;
  private logger: Logger;
  private authManager: AuthManager;
  private offlineQueue: OfflineQueue;
  private listeners: Set<MultandoEventListener> = new Set();
  private _initialized = false;

  public readonly auth: AuthService;
  public readonly reports: ReportService;
  public readonly evidence: EvidenceService;
  public readonly infractions: InfractionService;
  public readonly vehicleTypes: VehicleTypeService;
  public readonly verification: VerificationService;
  public readonly blockchain: BlockchainService;
  public readonly chat: ChatService;

  constructor(config: MultandoConfig) {
    this.config = resolveConfig(config);
    this.logger = new Logger(this.config.logLevel);
    this.authManager = new AuthManager(
      this.config.baseUrl,
      this.config.apiKey,
      this.logger,
    );
    this.offlineQueue = new OfflineQueue(
      this.logger,
      this.config.enableOfflineQueue,
    );

    const httpClient = createHttpClient(
      this.config,
      this.authManager,
      this.logger,
    );

    this.auth = new AuthService(httpClient, this.authManager, this.logger);
    this.reports = new ReportService(httpClient, this.offlineQueue, this.logger);
    this.evidence = new EvidenceService(httpClient, this.logger);
    this.infractions = new InfractionService(httpClient, this.logger);
    this.vehicleTypes = new VehicleTypeService(httpClient, this.logger);
    this.verification = new VerificationService(httpClient, this.logger);
    this.blockchain = new BlockchainService(httpClient, this.logger);
    this.chat = new ChatService(httpClient, this.logger);
  }

  async initialize(): Promise<void> {
    if (this._initialized) return;

    this.logger.info('Initializing Multando SDK');

    await this.authManager.initialize();

    const httpClient = createHttpClient(
      this.config,
      this.authManager,
      this.logger,
    );
    await this.offlineQueue.initialize(httpClient);

    // Subscribe to auth state changes
    this.authManager.onAuthStateChange((state) => {
      this.emit('auth_state_changed', state);
    });

    // Subscribe to offline queue events
    this.offlineQueue.onEvent((event, detail) => {
      this.emit('offline_queue_changed', { event, detail });
    });

    this._initialized = true;
    this.emit('initialized');
    this.logger.info('Multando SDK initialized');
  }

  get isAuthenticated(): boolean {
    return this.authManager.isAuthenticated;
  }

  get currentUser(): UserProfile | null {
    return this.authManager.currentUser;
  }

  get offlineQueueCount(): number {
    return this.offlineQueue.count;
  }

  get offlineQueueItems(): ReadonlyArray<import('./offlineQueue').QueuedRequest> {
    return this.offlineQueue.getQueue();
  }

  async flushOfflineQueue(): Promise<void> {
    await this.offlineQueue.flush();
  }

  async removeFromOfflineQueue(id: string): Promise<void> {
    await this.offlineQueue.remove(id);
  }

  get isInitialized(): boolean {
    return this._initialized;
  }

  onEvent(listener: MultandoEventListener): () => void {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  }

  dispose(): void {
    this.logger.info('Disposing Multando SDK');
    this.offlineQueue.dispose();
    this.listeners.clear();
    this._initialized = false;
  }

  private emit(event: MultandoEventType, data?: unknown): void {
    this.listeners.forEach((listener) => {
      try {
        listener(event, data);
      } catch (error) {
        this.logger.error('Error in event listener', error);
      }
    });
  }
}
