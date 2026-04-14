export enum ReportStatus {
  Draft = 'draft',
  Submitted = 'submitted',
  UnderReview = 'under_review',
  Verified = 'verified',
  Rejected = 'rejected',
  Resolved = 'resolved',
  /** Report reached the community-verification threshold. */
  CommunityVerified = 'community_verified',
  /** Report is awaiting authority review before becoming a citation. */
  AuthorityReview = 'authority_review',
}

export enum EvidenceType {
  Photo = 'photo',
  Video = 'video',
  Document = 'document',
}

export enum InfractionSeverity {
  Low = 'low',
  Medium = 'medium',
  High = 'high',
  Critical = 'critical',
}

export enum InfractionCategory {
  Parking = 'parking',
  Traffic = 'traffic',
  Safety = 'safety',
  Environmental = 'environmental',
  Documentation = 'documentation',
  Other = 'other',
}

export enum LogLevel {
  None = 'none',
  Error = 'error',
  Warn = 'warn',
  Info = 'info',
  Debug = 'debug',
}

export enum TransactionType {
  Stake = 'stake',
  Unstake = 'unstake',
  Reward = 'reward',
  Transfer = 'transfer',
}

export enum Locale {
  En = 'en',
  Es = 'es',
}
