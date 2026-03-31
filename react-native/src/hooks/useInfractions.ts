import { useState, useCallback, useEffect } from 'react';
import { useMultando } from './useMultando';
import { InfractionResponse } from '../models/infraction';

export interface UseInfractionsResult {
  infractions: InfractionResponse[];
  isLoading: boolean;
  error: Error | null;
  refresh: () => Promise<void>;
  getById: (id: string) => InfractionResponse | undefined;
}

export function useInfractions(autoFetch = true): UseInfractionsResult {
  const { client } = useMultando();
  const [infractions, setInfractions] = useState<InfractionResponse[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const fetchInfractions = useCallback(
    async (forceRefresh = false): Promise<void> => {
      setIsLoading(true);
      setError(null);
      try {
        const result = await client.infractions.list(forceRefresh);
        setInfractions(result);
      } catch (err) {
        const e = err instanceof Error ? err : new Error(String(err));
        setError(e);
      } finally {
        setIsLoading(false);
      }
    },
    [client],
  );

  useEffect(() => {
    if (autoFetch) {
      fetchInfractions();
    }
  }, [autoFetch, fetchInfractions]);

  const refresh = useCallback(async (): Promise<void> => {
    await fetchInfractions(true);
  }, [fetchInfractions]);

  const getById = useCallback(
    (id: string): InfractionResponse | undefined => {
      return infractions.find((i) => i.id === id);
    },
    [infractions],
  );

  return {
    infractions,
    isLoading,
    error,
    refresh,
    getById,
  };
}
