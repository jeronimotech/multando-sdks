"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ReportService = void 0;
class ReportService {
    constructor(http, offlineQueue, logger) {
        this.http = http;
        this.offlineQueue = offlineQueue;
        this.logger = logger;
    }
    async create(report) {
        try {
            const response = await this.http.post('/reports', report);
            return response.data;
        }
        catch (error) {
            if (this.isNetworkError(error) && this.offlineQueue.count >= 0) {
                this.logger.info('Network unavailable, queuing report creation');
                const queueId = await this.offlineQueue.enqueue({
                    method: 'post',
                    url: '/reports',
                    data: report,
                });
                return queueId;
            }
            throw error;
        }
    }
    async list(params) {
        const response = await this.http.get('/reports', {
            params,
        });
        return response.data;
    }
    async getById(id) {
        const response = await this.http.get(`/reports/${id}`);
        return response.data;
    }
    async getByPlate(plate) {
        const response = await this.http.get(`/reports/by-plate/${encodeURIComponent(plate)}`);
        return response.data;
    }
    async delete(id) {
        await this.http.delete(`/reports/${id}`);
    }
    isNetworkError(error) {
        if (error && typeof error === 'object' && 'code' in error) {
            return error.code === 'ERR_NETWORK';
        }
        return false;
    }
}
exports.ReportService = ReportService;
//# sourceMappingURL=reportService.js.map