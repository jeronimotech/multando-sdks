import { AxiosInstance } from 'axios';
import { Logger } from '../core/logger';
import { EvidenceCreate, EvidenceResponse } from '../models/evidence';
export declare class EvidenceService {
    private http;
    private logger;
    constructor(http: AxiosInstance, logger: Logger);
    addEvidence(reportId: string, evidence: EvidenceCreate): Promise<EvidenceResponse>;
}
//# sourceMappingURL=evidenceService.d.ts.map