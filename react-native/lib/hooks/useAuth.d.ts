import { UserProfile } from '../models/user';
import { RegisterRequest, LoginRequest, WalletLinkRequest } from '../models/auth';
export interface UseAuthResult {
    isAuthenticated: boolean;
    isLoading: boolean;
    user: UserProfile | null;
    error: Error | null;
    login: (request: LoginRequest) => Promise<UserProfile>;
    register: (request: RegisterRequest) => Promise<UserProfile>;
    logout: () => Promise<void>;
    linkWallet: (request: WalletLinkRequest) => Promise<UserProfile>;
    refreshProfile: () => Promise<UserProfile>;
}
export declare function useAuth(): UseAuthResult;
//# sourceMappingURL=useAuth.d.ts.map