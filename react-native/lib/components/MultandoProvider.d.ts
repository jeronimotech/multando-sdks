import React from 'react';
import { MultandoConfig } from '../core/config';
export interface MultandoProviderProps {
    config: MultandoConfig;
    children: React.ReactNode;
    onInitialized?: () => void;
    onError?: (error: Error) => void;
}
export declare function MultandoProvider({ config, children, onInitialized, onError, }: MultandoProviderProps): React.ReactElement | null;
//# sourceMappingURL=MultandoProvider.d.ts.map