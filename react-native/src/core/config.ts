import { LogLevel, Locale } from '../models/enums';

export interface MultandoConfig {
  baseUrl: string;
  apiKey: string;
  locale?: Locale;
  timeout?: number;
  enableOfflineQueue?: boolean;
  logLevel?: LogLevel;
}

export const DEFAULT_CONFIG: Required<Omit<MultandoConfig, 'baseUrl' | 'apiKey'>> = {
  locale: Locale.En,
  timeout: 30000,
  enableOfflineQueue: true,
  logLevel: LogLevel.Error,
};

export function resolveConfig(config: MultandoConfig): Required<MultandoConfig> {
  return {
    ...DEFAULT_CONFIG,
    ...config,
  };
}
