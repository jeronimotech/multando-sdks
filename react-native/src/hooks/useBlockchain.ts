import { useState, useCallback } from 'react';
import { useMultando } from './useMultando';
import {
  TokenBalance,
  StakingInfo,
  TokenTransaction,
  ClaimRewardsResponse,
} from '../models/blockchain';

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

export function useBlockchain(): UseBlockchainResult {
  const { client } = useMultando();
  const [balance, setBalance] = useState<TokenBalance | null>(null);
  const [stakingInfo, setStakingInfo] = useState<StakingInfo | null>(null);
  const [transactions, setTransactions] = useState<TokenTransaction[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const fetchBalance = useCallback(async (): Promise<TokenBalance> => {
    setIsLoading(true);
    setError(null);
    try {
      const result = await client.blockchain.getBalance();
      setBalance(result);
      return result;
    } catch (err) {
      const e = err instanceof Error ? err : new Error(String(err));
      setError(e);
      throw e;
    } finally {
      setIsLoading(false);
    }
  }, [client]);

  const fetchStakingInfo = useCallback(async (): Promise<StakingInfo> => {
    setIsLoading(true);
    setError(null);
    try {
      const result = await client.blockchain.getStakingInfo();
      setStakingInfo(result);
      return result;
    } catch (err) {
      const e = err instanceof Error ? err : new Error(String(err));
      setError(e);
      throw e;
    } finally {
      setIsLoading(false);
    }
  }, [client]);

  const fetchTransactions = useCallback(async (): Promise<TokenTransaction[]> => {
    setIsLoading(true);
    setError(null);
    try {
      const result = await client.blockchain.getTransactions();
      setTransactions(result);
      return result;
    } catch (err) {
      const e = err instanceof Error ? err : new Error(String(err));
      setError(e);
      throw e;
    } finally {
      setIsLoading(false);
    }
  }, [client]);

  const stake = useCallback(
    async (amount: number): Promise<StakingInfo> => {
      setIsLoading(true);
      setError(null);
      try {
        const result = await client.blockchain.stake({ amount });
        setStakingInfo(result);
        await fetchBalance();
        return result;
      } catch (err) {
        const e = err instanceof Error ? err : new Error(String(err));
        setError(e);
        throw e;
      } finally {
        setIsLoading(false);
      }
    },
    [client, fetchBalance],
  );

  const unstake = useCallback(
    async (amount: number): Promise<StakingInfo> => {
      setIsLoading(true);
      setError(null);
      try {
        const result = await client.blockchain.unstake({ amount });
        setStakingInfo(result);
        await fetchBalance();
        return result;
      } catch (err) {
        const e = err instanceof Error ? err : new Error(String(err));
        setError(e);
        throw e;
      } finally {
        setIsLoading(false);
      }
    },
    [client, fetchBalance],
  );

  const claimRewards = useCallback(async (): Promise<ClaimRewardsResponse> => {
    setIsLoading(true);
    setError(null);
    try {
      const result = await client.blockchain.claimRewards();
      await fetchBalance();
      return result;
    } catch (err) {
      const e = err instanceof Error ? err : new Error(String(err));
      setError(e);
      throw e;
    } finally {
      setIsLoading(false);
    }
  }, [client, fetchBalance]);

  return {
    balance,
    stakingInfo,
    transactions,
    isLoading,
    error,
    fetchBalance,
    fetchStakingInfo,
    fetchTransactions,
    stake,
    unstake,
    claimRewards,
  };
}
