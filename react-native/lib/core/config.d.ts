import { LogLevel, Locale } from '../models/enums';
export interface MultandoConfig {
    baseUrl: string;
    apiKey: string;
    locale?: Locale;
    timeout?: number;
    enableOfflineQueue?: boolean;
    logLevel?: LogLevel;
}
export declare const DEFAULT_CONFIG: Required<Omit<MultandoConfig, 'baseUrl' | 'apiKey'>>;
export declare function resolveConfig(config: MultandoConfig): Required<MultandoConfig>;
//# sourceMappingURL=config.d.ts.map