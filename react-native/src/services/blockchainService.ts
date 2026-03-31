import { AxiosInstance } from 'axios';
import { Logger } from '../core/logger';
import {
  TokenBalance,
  StakeRequest,
  StakingInfo,
  TokenTransaction,
  ClaimRewardsResponse,
} from '../models/blockchain';

export class BlockchainService {
  private http: AxiosInstance;
  private logger: Logger;

  constructor(http: AxiosInstance, logger: Logger) {
    this.http = http;
    this.logger = logger;
  }

  async getBalance(): Promise<TokenBalance> {
    const response = await this.http.get<TokenBalance>('/blockchain/balance');
    return response.data;
  }

  async stake(request: StakeRequest): Promise<StakingInfo> {
    this.logger.info('Staking tokens', { amount: request.amount });
    const response = await this.http.post<StakingInfo>(
      '/blockchain/stake',
      request,
    );
    return response.data;
  }

  async unstake(request: StakeRequest): Promise<StakingInfo> {
    this.logger.info('Unstaking tokens', { amount: request.amount });
    const response = await this.http.post<StakingInfo>(
      '/blockchain/unstake',
      request,
    );
    return response.data;
  }

  async getStakingInfo(): Promise<StakingInfo> {
    const response = await this.http.get<StakingInfo>(
      '/blockchain/staking-info',
    );
    return response.data;
  }

  async getTransactions(): Promise<TokenTransaction[]> {
    const response = await this.http.get<TokenTransaction[]>(
      '/blockchain/transactions',
    );
    return response.data;
  }

  async claimRewards(): Promise<ClaimRewardsResponse> {
    this.logger.info('Claiming rewards');
    const response = await this.http.post<ClaimRewardsResponse>(
      '/blockchain/claim-rewards',
    );
    return response.data;
  }
}
