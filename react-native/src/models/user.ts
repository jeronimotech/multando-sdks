export interface UserProfile {
  id: string;
  email: string;
  fullName: string;
  phoneNumber: string | null;
  walletAddress: string | null;
  isVerified: boolean;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
  totalReports: number;
  verifiedReports: number;
  reputationScore: number;

  /**
   * Responsible-reporting counters. The backend returns these as
   * ``total_reports_count`` / ``rejected_reports_count`` /
   * ``rejection_rate`` / ``rejection_rate_warning``; they are parsed
   * into camelCase by the HTTP client interceptor.
   *
   * ``rejectionRateWarning`` is ``true`` when the user's rejection
   * rate crosses the 30% threshold — client apps should surface the
   * :data:`rejection_rate_warning` string and the responsible-
   * reporting info panel when this flag is set.
   */
  totalReportsCount: number;
  rejectedReportsCount?: number;
  rejectionRate?: number;
  rejectionRateWarning: boolean;
}

export interface UserPublic {
  id: string;
  fullName: string;
  isVerified: boolean;
  reputationScore: number;
  totalReports: number;
  verifiedReports: number;
}
