import { ReportStatus, InfractionSeverity } from './enums';
import { EvidenceResponse } from './evidence';
import { UserPublic } from './user';
export interface LocationData {
    latitude: number;
    longitude: number;
    address?: string;
    city?: string;
    state?: string;
    country?: string;
    postalCode?: string;
}
export interface ReportCreate {
    plateNumber: string;
    vehicleTypeId: string;
    infractionId: string;
    description: string;
    location: LocationData;
    occurredAt?: string;
}
export interface ReportSummary {
    id: string;
    plateNumber: string;
    infractionName: string;
    severity: InfractionSeverity;
    status: ReportStatus;
    location: LocationData;
    occurredAt: string;
    createdAt: string;
    evidenceCount: number;
}
export interface ReportDetail {
    id: string;
    plateNumber: string;
    vehicleTypeId: string;
    vehicleTypeName: string;
    infractionId: string;
    infractionName: string;
    severity: InfractionSeverity;
    description: string;
    status: ReportStatus;
    location: LocationData;
    occurredAt: string;
    createdAt: string;
    updatedAt: string;
    reporter: UserPublic;
    evidence: EvidenceResponse[];
    verificationCount: number;
    rejectionCount: number;
}
export interface ReportList {
    items: ReportSummary[];
    total: number;
    page: number;
    pageSize: number;
    totalPages: number;
}
//# sourceMappingURL=report.d.ts.map