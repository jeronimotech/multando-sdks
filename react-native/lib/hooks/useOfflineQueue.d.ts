import { QueuedRequest } from '../core/offlineQueue';
export interface UseOfflineQueueResult {
    count: number;
    items: ReadonlyArray<QueuedRequest>;
    isFlushing: boolean;
    flush: () => Promise<void>;
    remove: (id: string) => Promise<void>;
}
export declare function useOfflineQueue(): UseOfflineQueueResult;
//# sourceMappingURL=useOfflineQueue.d.ts.map