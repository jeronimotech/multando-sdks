import { AxiosInstance } from 'axios';
import { Logger } from '../core/logger';
import { VehicleTypeResponse } from '../models/vehicleType';
export declare class VehicleTypeService {
    private http;
    private logger;
    private cache;
    private cacheTimestamp;
    private cacheTtl;
    constructor(http: AxiosInstance, logger: Logger, cacheTtlMs?: number);
    list(forceRefresh?: boolean): Promise<VehicleTypeResponse[]>;
    getById(id: string): VehicleTypeResponse | undefined;
    clearCache(): void;
    private isCacheValid;
}
//# sourceMappingURL=vehicleTypeService.d.ts.map