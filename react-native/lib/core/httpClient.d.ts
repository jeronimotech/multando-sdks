import { AxiosInstance, AxiosRequestConfig } from 'axios';
import { MultandoConfig } from './config';
import { AuthManager } from './authManager';
import { Logger } from './logger';
export declare function createHttpClient(config: Required<MultandoConfig>, authManager: AuthManager, logger: Logger): AxiosInstance;
export type { AxiosInstance, AxiosRequestConfig };
//# sourceMappingURL=httpClient.d.ts.map