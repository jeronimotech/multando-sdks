"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MultandoClient = void 0;
const config_1 = require("./config");
const httpClient_1 = require("./httpClient");
const authManager_1 = require("./authManager");
const offlineQueue_1 = require("./offlineQueue");
const logger_1 = require("./logger");
const authService_1 = require("../services/authService");
const reportService_1 = require("../services/reportService");
const evidenceService_1 = require("../services/evidenceService");
const infractionService_1 = require("../services/infractionService");
const vehicleTypeService_1 = require("../services/vehicleTypeService");
const verificationService_1 = require("../services/verificationService");
const blockchainService_1 = require("../services/blockchainService");
class MultandoClient {
    constructor(config) {
        this.listeners = new Set();
        this._initialized = false;
        this.config = (0, config_1.resolveConfig)(config);
        this.logger = new logger_1.Logger(this.config.logLevel);
        this.authManager = new authManager_1.AuthManager(this.config.baseUrl, this.config.apiKey, this.logger);
        this.offlineQueue = new offlineQueue_1.OfflineQueue(this.logger, this.config.enableOfflineQueue);
        const httpClient = (0, httpClient_1.createHttpClient)(this.config, this.authManager, this.logger);
        this.auth = new authService_1.AuthService(httpClient, this.authManager, this.logger);
        this.reports = new reportService_1.ReportService(httpClient, this.offlineQueue, this.logger);
        this.evidence = new evidenceService_1.EvidenceService(httpClient, this.logger);
        this.infractions = new infractionService_1.InfractionService(httpClient, this.logger);
        this.vehicleTypes = new vehicleTypeService_1.VehicleTypeService(httpClient, this.logger);
        this.verification = new verificationService_1.VerificationService(httpClient, this.logger);
        this.blockchain = new blockchainService_1.BlockchainService(httpClient, this.logger);
    }
    async initialize() {
        if (this._initialized)
            return;
        this.logger.info('Initializing Multando SDK');
        await this.authManager.initialize();
        const httpClient = (0, httpClient_1.createHttpClient)(this.config, this.authManager, this.logger);
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
    get isAuthenticated() {
        return this.authManager.isAuthenticated;
    }
    get currentUser() {
        return this.authManager.currentUser;
    }
    get offlineQueueCount() {
        return this.offlineQueue.count;
    }
    get offlineQueueItems() {
        return this.offlineQueue.getQueue();
    }
    async flushOfflineQueue() {
        await this.offlineQueue.flush();
    }
    async removeFromOfflineQueue(id) {
        await this.offlineQueue.remove(id);
    }
    get isInitialized() {
        return this._initialized;
    }
    onEvent(listener) {
        this.listeners.add(listener);
        return () => {
            this.listeners.delete(listener);
        };
    }
    dispose() {
        this.logger.info('Disposing Multando SDK');
        this.offlineQueue.dispose();
        this.listeners.clear();
        this._initialized = false;
    }
    emit(event, data) {
        this.listeners.forEach((listener) => {
            try {
                listener(event, data);
            }
            catch (error) {
                this.logger.error('Error in event listener', error);
            }
        });
    }
}
exports.MultandoClient = MultandoClient;
//# sourceMappingURL=MultandoClient.js.map