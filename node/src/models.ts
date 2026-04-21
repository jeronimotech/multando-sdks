/**
 * TypeScript interfaces for the Multando API.
 */

// ── Auth ────────────────────────────────────────────────────────────

export interface TokenResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
  expires_in: number;
}

export interface RegisterRequest {
  username: string;
  display_name: string;
  email: string;
  password: string;
  phone?: string;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface SocialLoginOptions {
  provider: string;
  idToken?: string;
  code?: string;
  redirectUri?: string;
}

// ── User ────────────────────────────────────────────────────────────

export interface User {
  id: string;
  email: string;
  username: string;
  display_name: string;
  avatar_url: string | null;
  is_verified: boolean;
  role: string;
  created_at: string;
}

// ── Reports ─────────────────────────────────────────────────────────

export interface LocationData {
  latitude: number;
  longitude: number;
  address?: string;
  city?: string;
  country?: string;
}

export interface CreateReportRequest {
  infraction_id: number;
  plate_number: string;
  latitude: number;
  longitude: number;
  description: string;
  vehicle_type_id?: string;
  source?: string;
}

export interface Report {
  id: string;
  short_id: string;
  status: string;
  vehicle_plate: string;
  infraction_id: number;
  latitude: number;
  longitude: number;
  description: string;
  created_at: string;
}

// ── Infractions ─────────────────────────────────────────────────────

export interface Infraction {
  id: number;
  code: string;
  name: string;
  description: string;
  severity: string;
  points_reward: number;
  multa_reward: number;
}

// ── Wallet ──────────────────────────────────────────────────────────

export interface WalletBalance {
  points: number;
  multa_balance: number;
}

export interface Activity {
  id: string;
  type: string;
  points_earned: number;
  multa_earned: number;
  created_at: string;
}

// ── Pagination ──────────────────────────────────────────────────────

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  page_size: number;
}
