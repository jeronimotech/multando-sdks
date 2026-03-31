import { useState, useEffect, useCallback } from 'react';
import { useMultando } from './useMultando';
import { QueuedRequest } from '../core/offlineQueue';

export interface UseOfflineQueueResult {
  count: number;
  items: ReadonlyArray<QueuedRequest>;
  isFlushing: boolean;
  flush: () => Promise<void>;
  remove: (id: string) => Promise<void>;
}

export function useOfflineQueue(): UseOfflineQueueResult {
  const { client } = useMultando();
  const [count, setCount] = useState(client.offlineQueueCount);
  const [items, setItems] = useState<ReadonlyArray<QueuedRequest>>(
    client.offlineQueueItems,
  );
  const [isFlushing, setIsFlushing] = useState(false);

  const refreshState = useCallback(() => {
    setCount(client.offlineQueueCount);
    setItems(client.offlineQueueItems);
  }, [client]);

  useEffect(() => {
    const unsubscribe = client.onEvent((event, data) => {
      if (event === 'offline_queue_changed') {
        refreshState();
        const detail = data as { event?: string } | undefined;
        if (detail?.event === 'flushing') {
          setIsFlushing(true);
        } else if (
          detail?.event === 'flushed' ||
          detail?.event === 'flush_error'
        ) {
          setIsFlushing(false);
        }
      }
    });
    return unsubscribe;
  }, [client, refreshState]);

  const flush = useCallback(async (): Promise<void> => {
    setIsFlushing(true);
    try {
      await client.flushOfflineQueue();
    } finally {
      setIsFlushing(false);
      refreshState();
    }
  }, [client, refreshState]);

  const remove = useCallback(
    async (id: string): Promise<void> => {
      await client.removeFromOfflineQueue(id);
      refreshState();
    },
    [client, refreshState],
  );

  return {
    count,
    items,
    isFlushing,
    flush,
    remove,
  };
}
