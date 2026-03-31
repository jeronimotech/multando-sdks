"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.VerificationService = void 0;
class VerificationService {
    constructor(http, logger) {
        this.http = http;
        this.logger = logger;
    }
    async verify(reportId) {
        this.logger.info('Verifying report', { reportId });
        const response = await this.http.post(`/verification/${reportId}/verify`);
        return response.data;
    }
    async reject(reportId, request) {
        this.logger.info('Rejecting report', { reportId });
        const response = await this.http.post(`/verification/${reportId}/reject`, request);
        return response.data;
    }
    async getQueue() {
        const response = await this.http.get('/verification/queue');
        return response.data;
    }
}
exports.VerificationService = VerificationService;
//# sourceMappingURL=verificationService.js.map