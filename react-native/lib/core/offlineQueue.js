"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.OfflineQueue = void 0;
const async_storage_1 = __importDefault(require("@react-native-async-storage/async-storage"));
const netinfo_1 = __importDefault(require("@react-native-community/netinfo"));
const QUEUE_STORAGE_KEY = '@multando/offline_queue';
class OfflineQueue {
    constructor(logger, enabled) {
        this.queue = [];
        this.httpClient = null;
        this.isFlushing = false;
        this.unsubscribeNetInfo = null;
        this.listeners = new Set();
        this.maxRetries = 3;
        this.logger = logger;
        this.enabled = enabled;
    }
    async initialize(httpClient) {
        this.httpClient = httpClient;
        if (!this.enabled)
            return;
        await this.loadQueue();
        this.unsubscribeNetInfo = netinfo_1.default.addEventListener((state) => {
            if (state.isConnected && this.queue.length > 0) {
                this.logger.info('Network restored, flushing offline queue');
                this.flush();
            }
        });
    }
    async enqueue(request) {
        const id = `${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
        const item = {
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
    async remove(id) {
        this.queue = this.queue.filter((item) => item.id !== id);
        await this.persistQueue();
        this.emit('removed', { id });
    }
    async flush() {
        if (this.isFlushing || this.queue.length === 0 || !this.httpClient)
            return;
        this.isFlushing = true;
        this.emit('flushing');
        const toProcess = [...this.queue];
        const failed = [];
        for (const item of toProcess) {
            try {
                await this.httpClient.request({
                    method: item.method,
                    url: item.url,
                    data: item.data,
                    params: item.params,
                });
                this.logger.debug('Flushed queued request', { id: item.id });
            }
            catch (error) {
                item.retryCount += 1;
                if (item.retryCount < this.maxRetries) {
                    failed.push(item);
                    this.logger.warn('Failed to flush request, will retry', {
                        id: item.id,
                        retryCount: item.retryCount,
                    });
                }
                else {
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
    get count() {
        return this.queue.length;
    }
    getQueue() {
        return [...this.queue];
    }
    onEvent(listener) {
        this.listeners.add(listener);
        return () => {
            this.listeners.delete(listener);
        };
    }
    dispose() {
        if (this.unsubscribeNetInfo) {
            this.unsubscribeNetInfo();
            this.unsubscribeNetInfo = null;
        }
        this.listeners.clear();
    }
    emit(event, detail) {
        this.listeners.forEach((listener) => listener(event, detail));
    }
    async loadQueue() {
        try {
            const stored = await async_storage_1.default.getItem(QUEUE_STORAGE_KEY);
            if (stored) {
                this.queue = JSON.parse(stored);
                this.logger.debug(`Loaded ${this.queue.length} items from offline queue`);
            }
        }
        catch (error) {
            this.logger.error('Failed to load offline queue', error);
            this.queue = [];
        }
    }
    async persistQueue() {
        try {
            await async_storage_1.default.setItem(QUEUE_STORAGE_KEY, JSON.stringify(this.queue));
        }
        catch (error) {
            this.logger.error('Failed to persist offline queue', error);
        }
    }
}
exports.OfflineQueue = OfflineQueue;
//# sourceMappingURL=offlineQueue.js.map