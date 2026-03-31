"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.InfractionService = void 0;
class InfractionService {
    constructor(http, logger, cacheTtlMs = 300000) {
        this.cache = null;
        this.cacheTimestamp = 0;
        this.http = http;
        this.logger = logger;
        this.cacheTtl = cacheTtlMs;
    }
    async list(forceRefresh = false) {
        if (!forceRefresh && this.cache && this.isCacheValid()) {
            this.logger.debug('Returning cached infractions');
            return this.cache;
        }
        this.logger.debug('Fetching infractions from API');
        const response = await this.http.get('/infractions');
        this.cache = response.data;
        this.cacheTimestamp = Date.now();
        return this.cache;
    }
    getById(id) {
        return this.cache?.find((infraction) => infraction.id === id);
    }
    clearCache() {
        this.cache = null;
        this.cacheTimestamp = 0;
    }
    isCacheValid() {
        return Date.now() - this.cacheTimestamp < this.cacheTtl;
    }
}
exports.InfractionService = InfractionService;
//# sourceMappingURL=infractionService.js.map