// Core
export { MultandoClient } from './core/MultandoClient';
export type { MultandoEventType } from './core/MultandoClient';
export type { MultandoConfig } from './core/config';
export { AuthManager } from './core/authManager';
export type { AuthState } from './core/authManager';
export { OfflineQueue } from './core/offlineQueue';
export type { QueuedRequest } from './core/offlineQueue';
export { Logger } from './core/logger';

// Models - Auth
export type {
  RegisterRequest,
  LoginRequest,
  TokenResponse,
  RefreshRequest,
  WalletLinkRequest,
} from './models/auth';

// Models - User
export type { UserProfile, UserPublic } from './models/user';

// Models - Report
export type {
  ReportCreate,
  ReportDetail,
  ReportSummary,
  ReportList,
  LocationData,
} from './models/report';

// Models - Evidence
export type { EvidenceCreate, EvidenceResponse } from './models/evidence';

// Models - Infraction
export type { InfractionResponse } from './models/infraction';

// Models - Vehicle Type
export type { VehicleTypeResponse } from './models/vehicleType';

// Models - Blockchain
export type {
  TokenBalance,
  StakeRequest,
  StakingInfo,
  TokenTransaction,
  ClaimRewardsResponse,
} from './models/blockchain';

// Models - Verification
export type {
  RejectRequest,
  VerificationResult,
  VerificationQueueItem,
  VerificationQueue,
} from './models/verification';

// Models - Enums
export {
  ReportStatus,
  EvidenceType,
  InfractionSeverity,
  InfractionCategory,
  LogLevel,
  TransactionType,
  Locale,
} from './models/enums';

// Models - Errors
export {
  MultandoError,
  MultandoApiError,
  MultandoNetworkError,
  MultandoValidationError,
  MultandoAuthError,
} from './models/error';

// Services
export { AuthService } from './services/authService';
export { ReportService } from './services/reportService';
export type { ReportListParams } from './services/reportService';
export { EvidenceService } from './services/evidenceService';
export { InfractionService } from './services/infractionService';
export { VehicleTypeService } from './services/vehicleTypeService';
export { VerificationService } from './services/verificationService';
export { BlockchainService } from './services/blockchainService';

// Hooks
export { useMultando } from './hooks/useMultando';
export type { MultandoContextValue } from './hooks/useMultando';
export { useAuth } from './hooks/useAuth';
export type { UseAuthResult } from './hooks/useAuth';
export { useReports } from './hooks/useReports';
export type { UseReportsResult } from './hooks/useReports';
export { useInfractions } from './hooks/useInfractions';
export type { UseInfractionsResult } from './hooks/useInfractions';
export { useVehicleTypes } from './hooks/useVehicleTypes';
export type { UseVehicleTypesResult } from './hooks/useVehicleTypes';
export { useVerification } from './hooks/useVerification';
export type { UseVerificationResult } from './hooks/useVerification';
export { useBlockchain } from './hooks/useBlockchain';
export type { UseBlockchainResult } from './hooks/useBlockchain';
export { useOfflineQueue } from './hooks/useOfflineQueue';
export type { UseOfflineQueueResult } from './hooks/useOfflineQueue';

// Components
export { MultandoProvider } from './components/MultandoProvider';
export type { MultandoProviderProps } from './components/MultandoProvider';
export { ReportForm } from './components/ReportForm';
export type { ReportFormProps } from './components/ReportForm';
