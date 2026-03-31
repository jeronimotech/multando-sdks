import AsyncStorage from '@react-native-async-storage/async-storage';
import NetInfo, { NetInfoState } from '@react-native-community/netinfo';
import { AxiosInstance } from 'axios';
import { Logger } from './logger';

const QUEUE_STORAGE_KEY = '@multando/offline_queue';

export interface QueuedRequest {
  id: string;
  method: 'post' | 'put' | 'patch' | 'delete';
  url: string;
  data?: unknown;
  params?: Record<string, unknown>;
  createdAt: number;
  retryCount: number;
}

type QueueEventType = 'enqueued' | 'flushing' | 'flushed' | 'flush_error' | 'removed';

type QueueEventListener = (event: QueueEventType, detail?: unknown) => void;

export class OfflineQueue {
  private queue: QueuedRequest[] = [];
  private httpClient: AxiosInstance | null = null;
  private logger: Logger;
  private enabled: boolean;
  private isFlushing = false;
  private unsubscribeNetInfo: (() => void) | null = null;
  private listeners: Set<QueueEventListener> = new Set();
  private maxRetries = 3;

  constructor(logger: Logger, enabled: boolean) {
    this.logger = logger;
    this.enabled = enabled;
  }

  async initialize(httpClient: AxiosInstance): Promise<void> {
    this.httpClient = httpClient;

    if (!this.enabled) return;

    await this.loadQueue();

    this.unsubscribeNetInfo = NetInfo.addEventListener(
      (state: NetInfoState) => {
        if (state.isConnected && this.queue.length > 0) {
          this.logger.info('Network restored, flushing offline queue');
          this.flush();
        }
      },
    );
  }

  async enqueue(request: Omit<QueuedRequest, 'id' | 'createdAt' | 'retryCount'>): Promise<string> {
    const id = `${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
    const item: QueuedRequest = {
      ...request,
      id,
      createdAt: Date.now(),
      retryCount: 0,
    };

    this.queue.push(item);
    await this.persistQueue();
    this.emit('enqueued', item);
    this.logger.debug('Request enqueued for offline processing', { id, url: request.url });
    return id;
  }

  async remove(id: string): Promise<void> {
    this.queue = this.queue.filter((item) => item.id !== id);
    await this.persistQueue();
    this.emit('removed', { id });
  }

  async flush(): Promise<void> {
    if (this.isFlushing || this.queue.length === 0 || !this.httpClient) return;

    this.isFlushing = true;
    this.emit('flushing');

    const toProcess = [...this.queue];
    const failed: QueuedRequest[] = [];

    for (const item of toProcess) {
      try {
        await this.httpClient.request({
          method: item.method,
          url: item.url,
          data: item.data,
          params: item.params,
        });
        this.logger.debug('Flushed queued request', { id: item.id });
      } catch (error) {
        item.retryCount += 1;
        if (item.retryCount < this.maxRetries) {
          failed.push(item);
          this.logger.warn('Failed to flush request, will retry', {
            id: item.id,
            retryCount: item.retryCount,
          });
        } else {
          this.logger.error('Max retries reached for queued request, discarding', {
            id: item.id,
          });
          this.emit('flush_error', { id: item.id, error });
        }
      }
    }

    this.queue = failed;
    await this.persistQueue();
    this.isFlushing = false;
    this.emit('flushed', { remaining: failed.length });
  }

  get count(): number {
    return this.queue.length;
  }

  getQueue(): ReadonlyArray<QueuedRequest> {
    return [...this.queue];
  }

  onEvent(listener: QueueEventListener): () => void {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  }

  dispose(): void {
    if (this.unsubscribeNetInfo) {
      this.unsubscribeNetInfo();
      this.unsubscribeNetInfo = null;
    }
    this.listeners.clear();
  }

  private emit(event: QueueEventType, detail?: unknown): void {
    this.listeners.forEach((listener) => listener(event, detail));
  }

  private async loadQueue(): Promise<void> {
    try {
      const stored = await AsyncStorage.getItem(QUEUE_STORAGE_KEY);
      if (stored) {
        this.queue = JSON.parse(stored);
        this.logger.debug(`Loaded ${this.queue.length} items from offline queue`);
      }
    } catch (error) {
      this.logger.error('Failed to load offline queue', error);
      this.queue = [];
    }
  }

  private async persistQueue(): Promise<void> {
    try {
      await AsyncStorage.setItem(QUEUE_STORAGE_KEY, JSON.stringify(this.queue));
    } catch (error) {
      this.logger.error('Failed to persist offline queue', error);
    }
  }
}
