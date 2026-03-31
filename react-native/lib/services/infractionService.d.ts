import { AxiosInstance } from 'axios';
import { Logger } from '../core/logger';
import { InfractionResponse } from '../models/infraction';
export declare class InfractionService {
    private http;
    private logger;
    private cache;
    private cacheTimestamp;
    private cacheTtl;
    constructor(http: AxiosInstance, logger: Logger, cacheTtlMs?: number);
    list(forceRefresh?: boolean): Promise<InfractionResponse[]>;
    getById(id: string): InfractionResponse | undefined;
    clearCache(): void;
    private isCacheValid;
}
//# sourceMappingURL=infractionService.d.ts.map