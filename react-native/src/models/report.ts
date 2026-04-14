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

  /** Optional signed evidence fields */
  evidenceImageBase64?: string;
  evidenceMediaType?: string;
  evidenceImageHash?: string;
  evidenceSignature?: string;
  evidenceTimestamp?: string;
  evidenceDeviceId?: string;
  evidenceCaptureMethod?: string;
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
  /**
   * Anonymized display label for the reporter (e.g. "Reporter #4821").
   * Backend emits this in place of a real name when the viewer is not
   * the reporter themselves — keeping reporter identity private from
   * the reported party and the general public.
   */
  reporterDisplayName?: string;
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
