import { ReportDetail } from './report';

export interface RejectRequest {
  reason: string;
  details?: string;
}

export interface VerificationResult {
  reportId: string;
  action: 'verified' | 'rejected';
  message: string;
}

export interface VerificationQueueItem {
  report: ReportDetail;
  assignedAt: string;
  expiresAt: string;
}

export interface VerificationQueue {
  items: VerificationQueueItem[];
  total: number;
}
