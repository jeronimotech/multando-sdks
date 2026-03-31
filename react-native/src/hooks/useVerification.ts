import { useState, useCallback } from 'react';
import { useMultando } from './useMultando';
import {
  RejectRequest,
  VerificationResult,
  VerificationQueue,
} from '../models/verification';

export interface UseVerificationResult {
  queue: VerificationQueue | null;
  isLoading: boolean;
  error: Error | null;
  fetchQueue: () => Promise<VerificationQueue>;
  verify: (reportId: string) => Promise<VerificationResult>;
  reject: (reportId: string, request: RejectRequest) => Promise<VerificationResult>;
}

export function useVerification(): UseVerificationResult {
  const { client } = useMultando();
  const [queue, setQueue] = useState<VerificationQueue | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const fetchQueue = useCallback(async (): Promise<VerificationQueue> => {
    setIsLoading(true);
    setError(null);
    try {
      const result = await client.verification.getQueue();
      setQueue(result);
      return result;
    } catch (err) {
      const e = err instanceof Error ? err : new Error(String(err));
      setError(e);
      throw e;
    } finally {
      setIsLoading(false);
    }
  }, [client]);

  const verify = useCallback(
    async (reportId: string): Promise<VerificationResult> => {
      setIsLoading(true);
      setError(null);
      try {
        const result = await client.verification.verify(reportId);
        // Remove from local queue
        if (queue) {
          setQueue({
            ...queue,
            items: queue.items.filter((item) => item.report.id !== reportId),
            total: queue.total - 1,
          });
        }
        return result;
      } catch (err) {
        const e = err instanceof Error ? err : new Error(String(err));
        setError(e);
        throw e;
      } finally {
        setIsLoading(false);
      }
    },
    [client, queue],
  );

  const reject = useCallback(
    async (
      reportId: string,
      request: RejectRequest,
    ): Promise<VerificationResult> => {
      setIsLoading(true);
      setError(null);
      try {
        const result = await client.verification.reject(reportId, request);
        if (queue) {
          setQueue({
            ...queue,
            items: queue.items.filter((item) => item.report.id !== reportId),
            total: queue.total - 1,
          });
        }
        return result;
      } catch (err) {
        const e = err instanceof Error ? err : new Error(String(err));
        setError(e);
        throw e;
      } finally {
        setIsLoading(false);
      }
    },
    [client, queue],
  );

  return {
    queue,
    isLoading,
    error,
    fetchQueue,
    verify,
    reject,
  };
}
