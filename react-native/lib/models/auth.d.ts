export interface RegisterRequest {
    email: string;
    password: string;
    fullName: string;
    phoneNumber?: string;
}
export interface LoginRequest {
    email: string;
    password: string;
}
export interface TokenResponse {
    accessToken: string;
    refreshToken: string;
    tokenType: string;
    expiresIn: number;
}
export interface RefreshRequest {
    refreshToken: string;
}
export interface WalletLinkRequest {
    walletAddress: string;
    signature: string;
    message: string;
}
//# sourceMappingURL=auth.d.ts.map