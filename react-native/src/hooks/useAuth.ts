import { useState, useEffect, useCallback } from 'react';
import { useMultando } from './useMultando';
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

export function useAuth(): UseAuthResult {
  const { client } = useMultando();
  const [isAuthenticated, setIsAuthenticated] = useState(client.isAuthenticated);
  const [isLoading, setIsLoading] = useState(false);
  const [user, setUser] = useState<UserProfile | null>(client.currentUser);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const unsubscribe = client.auth.onAuthStateChange((state) => {
      setIsAuthenticated(state.isAuthenticated);
      setUser(state.user);
    });
    return unsubscribe;
  }, [client]);

  const login = useCallback(
    async (request: LoginRequest): Promise<UserProfile> => {
      setIsLoading(true);
      setError(null);
      try {
        const profile = await client.auth.login(request);
        return profile;
      } catch (err) {
        const e = err instanceof Error ? err : new Error(String(err));
        setError(e);
        throw e;
      } finally {
        setIsLoading(false);
      }
    },
    [client],
  );

  const register = useCallback(
    async (request: RegisterRequest): Promise<UserProfile> => {
      setIsLoading(true);
      setError(null);
      try {
        const profile = await client.auth.register(request);
        return profile;
      } catch (err) {
        const e = err instanceof Error ? err : new Error(String(err));
        setError(e);
        throw e;
      } finally {
        setIsLoading(false);
      }
    },
    [client],
  );

  const logout = useCallback(async (): Promise<void> => {
    setIsLoading(true);
    setError(null);
    try {
      await client.auth.logout();
    } catch (err) {
      const e = err instanceof Error ? err : new Error(String(err));
      setError(e);
      throw e;
    } finally {
      setIsLoading(false);
    }
  }, [client]);

  const linkWallet = useCallback(
    async (request: WalletLinkRequest): Promise<UserProfile> => {
      setIsLoading(true);
      setError(null);
      try {
        const profile = await client.auth.linkWallet(request);
        return profile;
      } catch (err) {
        const e = err instanceof Error ? err : new Error(String(err));
        setError(e);
        throw e;
      } finally {
        setIsLoading(false);
      }
    },
    [client],
  );

  const refreshProfile = useCallback(async (): Promise<UserProfile> => {
    setIsLoading(true);
    setError(null);
    try {
      const profile = await client.auth.getMe();
      return profile;
    } catch (err) {
      const e = err instanceof Error ? err : new Error(String(err));
      setError(e);
      throw e;
    } finally {
      setIsLoading(false);
    }
  }, [client]);

  return {
    isAuthenticated,
    isLoading,
    user,
    error,
    login,
    register,
    logout,
    linkWallet,
    refreshProfile,
  };
}
