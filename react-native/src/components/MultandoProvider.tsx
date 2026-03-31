import React, { useEffect, useRef, useState, useMemo } from 'react';
import { MultandoClient } from '../core/MultandoClient';
import { MultandoConfig } from '../core/config';
import { MultandoContext, getTranslation } from '../hooks/useMultando';
import { Locale } from '../models/enums';

export interface MultandoProviderProps {
  config: MultandoConfig;
  children: React.ReactNode;
  onInitialized?: () => void;
  onError?: (error: Error) => void;
}

export function MultandoProvider({
  config,
  children,
  onInitialized,
  onError,
}: MultandoProviderProps): React.ReactElement | null {
  const clientRef = useRef<MultandoClient | null>(null);
  const [isReady, setIsReady] = useState(false);

  // Create client only once (or when config identity changes)
  if (!clientRef.current) {
    clientRef.current = new MultandoClient(config);
  }

  useEffect(() => {
    const client = clientRef.current;
    if (!client) return;

    let disposed = false;

    client
      .initialize()
      .then(() => {
        if (!disposed) {
          setIsReady(true);
          onInitialized?.();
        }
      })
      .catch((error: unknown) => {
        if (!disposed) {
          const err =
            error instanceof Error ? error : new Error(String(error));
          onError?.(err);
        }
      });

    return () => {
      disposed = true;
      client.dispose();
      clientRef.current = null;
    };
    // We intentionally only run this once on mount.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const locale = config.locale ?? Locale.En;
  const t = useMemo(() => getTranslation(locale), [locale]);

  const contextValue = useMemo(() => {
    if (!clientRef.current) return null;
    return {
      client: clientRef.current,
      locale,
      t,
    };
  }, [locale, t, isReady]); // isReady is included to trigger re-render after init

  if (!contextValue) return null;

  return (
    <MultandoContext.Provider value={contextValue}>
      {isReady ? children : null}
    </MultandoContext.Provider>
  );
}
