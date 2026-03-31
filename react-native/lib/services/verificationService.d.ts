import { AxiosInstance } from 'axios';
import { Logger } from '../core/logger';
import { RejectRequest, VerificationResult, VerificationQueue } from '../models/verification';
export declare class VerificationService {
    private http;
    private logger;
    constructor(http: AxiosInstance, logger: Logger);
    verify(reportId: string): Promise<VerificationResult>;
    reject(reportId: string, request: RejectRequest): Promise<VerificationResult>;
    getQueue(): Promise<VerificationQueue>;
}
//# sourceMappingURL=verificationService.d.ts.map