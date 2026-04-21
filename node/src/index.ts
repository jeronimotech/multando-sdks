/**
 * @multando/node — Official Node.js client for the Multando API.
 */

export { MultandoClient, type MultandoClientOptions } from './client.js';
export { HttpClient } from './http.js';
export { AuthService } from './auth.js';
export { ReportsService, type ReportListOptions } from './reports.js';
export { InfractionsService } from './infractions.js';
export { WalletService } from './wallet.js';

export type {
  TokenResponse,
  RegisterRequest,
  LoginRequest,
  SocialLoginOptions,
  User,
  Report,
  CreateReportRequest,
  Infraction,
  WalletBalance,
  Activity,
  PaginatedResponse,
  LocationData,
} from './models.js';

export {
  MultandoError,
  AuthenticationError,
  NotFoundError,
  RateLimitError,
  ValidationError,
} from './errors.js';
