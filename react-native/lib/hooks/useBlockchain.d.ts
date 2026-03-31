import { TokenBalance, StakingInfo, TokenTransaction, ClaimRewardsResponse } from '../models/blockchain';
export interface UseBlockchainResult {
    balance: TokenBalance | null;
    stakingInfo: StakingInfo | null;
    transactions: TokenTransaction[];
    isLoading: boolean;
    error: Error | null;
    fetchBalance: () => Promise<TokenBalance>;
    fetchStakingInfo: () => Promise<StakingInfo>;
    fetchTransactions: () => Promise<TokenTransaction[]>;
    stake: (amount: number) => Promise<StakingInfo>;
    unstake: (amount: number) => Promise<StakingInfo>;
    claimRewards: () => Promise<ClaimRewardsResponse>;
}
export declare function useBlockchain(): UseBlockchainResult;
//# sourceMappingURL=useBlockchain.d.ts.map