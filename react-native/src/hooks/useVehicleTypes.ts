import { useState, useCallback, useEffect } from 'react';
import { useMultando } from './useMultando';
import { VehicleTypeResponse } from '../models/vehicleType';

export interface UseVehicleTypesResult {
  vehicleTypes: VehicleTypeResponse[];
  isLoading: boolean;
  error: Error | null;
  refresh: () => Promise<void>;
  getById: (id: string) => VehicleTypeResponse | undefined;
}

export function useVehicleTypes(autoFetch = true): UseVehicleTypesResult {
  const { client } = useMultando();
  const [vehicleTypes, setVehicleTypes] = useState<VehicleTypeResponse[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const fetchVehicleTypes = useCallback(
    async (forceRefresh = false): Promise<void> => {
      setIsLoading(true);
      setError(null);
      try {
        const result = await client.vehicleTypes.list(forceRefresh);
        setVehicleTypes(result);
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
      fetchVehicleTypes();
    }
  }, [autoFetch, fetchVehicleTypes]);

  const refresh = useCallback(async (): Promise<void> => {
    await fetchVehicleTypes(true);
  }, [fetchVehicleTypes]);

  const getById = useCallback(
    (id: string): VehicleTypeResponse | undefined => {
      return vehicleTypes.find((vt) => vt.id === id);
    },
    [vehicleTypes],
  );

  return {
    vehicleTypes,
    isLoading,
    error,
    refresh,
    getById,
  };
}
