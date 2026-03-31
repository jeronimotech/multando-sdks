import { AxiosInstance } from 'axios';
import { TokenResponse } from '../models/auth';
import { UserProfile } from '../models/user';
import { Logger } from './logger';
export type AuthState = {
    isAuthenticated: boolean;
    isLoading: boolean;
    user: UserProfile | null;
};
type AuthStateListener = (state: AuthState) => void;
export declare class AuthManager {
    private accessToken;
    private refreshToken;
    private tokenExpiry;
    private user;
    private listeners;
    private initialized;
    private baseUrl;
    private apiKey;
    private logger;
    constructor(baseUrl: string, apiKey: string, logger: Logger);
    initialize(): Promise<void>;
    getAccessToken(): Promise<string | null>;
    getRefreshTokenValue(): string | null;
    isTokenExpired(): boolean;
    get isAuthenticated(): boolean;
    get currentUser(): UserProfile | null;
    setTokens(response: TokenResponse): Promise<void>;
    setUser(user: UserProfile): Promise<void>;
    refreshAccessToken(): Promise<void>;
    clearTokens(): Promise<void>;
    onAuthStateChange(listener: AuthStateListener): () => void;
    getState(): AuthState;
    private notifyListeners;
    /** Expose a raw axios instance for the auth service (bypasses main interceptors). */
    createRawClient(): AxiosInstance;
}
export {};
//# sourceMappingURL=authManager.d.ts.map