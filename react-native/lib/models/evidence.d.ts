import { EvidenceType } from './enums';
export interface EvidenceCreate {
    type: EvidenceType;
    url: string;
    mimeType: string;
}
export interface EvidenceResponse {
    id: string;
    reportId: string;
    type: EvidenceType;
    url: string;
    mimeType: string;
    createdAt: string;
}
//# sourceMappingURL=evidence.d.ts.map