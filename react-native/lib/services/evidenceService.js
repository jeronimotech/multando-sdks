"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.EvidenceService = void 0;
class EvidenceService {
    constructor(http, logger) {
        this.http = http;
        this.logger = logger;
    }
    async addEvidence(reportId, evidence) {
        this.logger.debug('Adding evidence to report', { reportId });
        // The API accepts type, url, mime_type as query params
        const response = await this.http.post(`/reports/${reportId}/evidence`, null, {
            params: {
                type: evidence.type,
                url: evidence.url,
                mimeType: evidence.mimeType,
            },
        });
        return response.data;
    }
}
exports.EvidenceService = EvidenceService;
//# sourceMappingURL=evidenceService.js.map