import { AxiosInstance } from 'axios';
import { Logger } from '../core/logger';
import { TokenBalance, StakeRequest, StakingInfo, TokenTransaction, ClaimRewardsResponse } from '../models/blockchain';
export declare class BlockchainService {
    private http;
    private logger;
    constructor(http: AxiosInstance, logger: Logger);
    getBalance(): Promise<TokenBalance>;
    stake(request: StakeRequest): Promise<StakingInfo>;
    unstake(request: StakeRequest): Promise<StakingInfo>;
    getStakingInfo(): Promise<StakingInfo>;
    getTransactions(): Promise<TokenTransaction[]>;
    claimRewards(): Promise<ClaimRewardsResponse>;
}
//# sourceMappingURL=blockchainService.d.ts.map