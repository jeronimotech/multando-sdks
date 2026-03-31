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
}
export interface UserPublic {
    id: string;
    fullName: string;
    isVerified: boolean;
    reputationScore: number;
    totalReports: number;
    verifiedReports: number;
}
//# sourceMappingURL=user.d.ts.map