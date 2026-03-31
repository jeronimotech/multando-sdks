import { TransactionType } from './enums';
export interface TokenBalance {
    available: number;
    staked: number;
    pendingRewards: number;
    total: number;
    walletAddress: string;
}
export interface StakeRequest {
    amount: number;
}
export interface StakingInfo {
    totalStaked: number;
    stakingSince: string | null;
    estimatedApy: number;
    pendingRewards: number;
    lockPeriodEnds: string | null;
    isLocked: boolean;
}
export interface TokenTransaction {
    id: string;
    type: TransactionType;
    amount: number;
    txHash: string | null;
    status: string;
    createdAt: string;
    confirmedAt: string | null;
    description: string;
}
export interface ClaimRewardsResponse {
    amountClaimed: number;
    txHash: string;
    newBalance: number;
}
//# sourceMappingURL=blockchain.d.ts.map