import { AxiosInstance } from 'axios';
import { AuthManager } from '../core/authManager';
import { RegisterRequest, LoginRequest, TokenResponse, WalletLinkRequest } from '../models/auth';
import { UserProfile } from '../models/user';
import { Logger } from '../core/logger';
export declare class AuthService {
    private http;
    private authManager;
    private logger;
    constructor(http: AxiosInstance, authManager: AuthManager, logger: Logger);
    register(request: RegisterRequest): Promise<UserProfile>;
    login(request: LoginRequest): Promise<UserProfile>;
    refresh(): Promise<TokenResponse>;
    getMe(): Promise<UserProfile>;
    linkWallet(request: WalletLinkRequest): Promise<UserProfile>;
    logout(): Promise<void>;
    get isAuthenticated(): boolean;
    get currentUser(): UserProfile | null;
    onAuthStateChange(listener: (state: {
        isAuthenticated: boolean;
        isLoading: boolean;
        user: UserProfile | null;
    }) => void): () => void;
}
//# sourceMappingURL=authService.d.ts.map