import { AxiosInstance } from 'axios';
import { Logger } from './logger';
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
export declare class OfflineQueue {
    private queue;
    private httpClient;
    private logger;
    private enabled;
    private isFlushing;
    private unsubscribeNetInfo;
    private listeners;
    private maxRetries;
    constructor(logger: Logger, enabled: boolean);
    initialize(httpClient: AxiosInstance): Promise<void>;
    enqueue(request: Omit<QueuedRequest, 'id' | 'createdAt' | 'retryCount'>): Promise<string>;
    remove(id: string): Promise<void>;
    flush(): Promise<void>;
    get count(): number;
    getQueue(): ReadonlyArray<QueuedRequest>;
    onEvent(listener: QueueEventListener): () => void;
    dispose(): void;
    private emit;
    private loadQueue;
    private persistQueue;
}
export {};
//# sourceMappingURL=offlineQueue.d.ts.map