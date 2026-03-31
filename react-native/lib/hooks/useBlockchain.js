"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.useBlockchain = useBlockchain;
const react_1 = require("react");
const useMultando_1 = require("./useMultando");
function useBlockchain() {
    const { client } = (0, useMultando_1.useMultando)();
    const [balance, setBalance] = (0, react_1.useState)(null);
    const [stakingInfo, setStakingInfo] = (0, react_1.useState)(null);
    const [transactions, setTransactions] = (0, react_1.useState)([]);
    const [isLoading, setIsLoading] = (0, react_1.useState)(false);
    const [error, setError] = (0, react_1.useState)(null);
    const fetchBalance = (0, react_1.useCallback)(async () => {
        setIsLoading(true);
        setError(null);
        try {
            const result = await client.blockchain.getBalance();
            setBalance(result);
            return result;
        }
        catch (err) {
            const e = err instanceof Error ? err : new Error(String(err));
            setError(e);
            throw e;
        }
        finally {
            setIsLoading(false);
        }
    }, [client]);
    const fetchStakingInfo = (0, react_1.useCallback)(async () => {
        setIsLoading(true);
        setError(null);
        try {
            const result = await client.blockchain.getStakingInfo();
            setStakingInfo(result);
            return result;
        }
        catch (err) {
            const e = err instanceof Error ? err : new Error(String(err));
            setError(e);
            throw e;
        }
        finally {
            setIsLoading(false);
        }
    }, [client]);
    const fetchTransactions = (0, react_1.useCallback)(async () => {
        setIsLoading(true);
        setError(null);
        try {
            const result = await client.blockchain.getTransactions();
            setTransactions(result);
            return result;
        }
        catch (err) {
            const e = err instanceof Error ? err : new Error(String(err));
            setError(e);
            throw e;
        }
        finally {
            setIsLoading(false);
        }
    }, [client]);
    const stake = (0, react_1.useCallback)(async (amount) => {
        setIsLoading(true);
        setError(null);
        try {
            const result = await client.blockchain.stake({ amount });
            setStakingInfo(result);
            await fetchBalance();
            return result;
        }
        catch (err) {
            const e = err instanceof Error ? err : new Error(String(err));
            setError(e);
            throw e;
        }
        finally {
            setIsLoading(false);
        }
    }, [client, fetchBalance]);
    const unstake = (0, react_1.useCallback)(async (amount) => {
        setIsLoading(true);
        setError(null);
        try {
            const result = await client.blockchain.unstake({ amount });
            setStakingInfo(result);
            await fetchBalance();
            return result;
        }
        catch (err) {
            const e = err instanceof Error ? err : new Error(String(err));
            setError(e);
            throw e;
        }
        finally {
            setIsLoading(false);
        }
    }, [client, fetchBalance]);
    const claimRewards = (0, react_1.useCallback)(async () => {
        setIsLoading(true);
        setError(null);
        try {
            const result = await client.blockchain.claimRewards();
            await fetchBalance();
            return result;
        }
        catch (err) {
            const e = err instanceof Error ? err : new Error(String(err));
            setError(e);
            throw e;
        }
        finally {
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
//# sourceMappingURL=useBlockchain.js.map