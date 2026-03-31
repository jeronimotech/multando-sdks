import { AxiosInstance } from 'axios';
import { Logger } from '../core/logger';
import { VehicleTypeResponse } from '../models/vehicleType';

export class VehicleTypeService {
  private http: AxiosInstance;
  private logger: Logger;
  private cache: VehicleTypeResponse[] | null = null;
  private cacheTimestamp: number = 0;
  private cacheTtl: number;

  constructor(http: AxiosInstance, logger: Logger, cacheTtlMs: number = 300000) {
    this.http = http;
    this.logger = logger;
    this.cacheTtl = cacheTtlMs;
  }

  async list(forceRefresh = false): Promise<VehicleTypeResponse[]> {
    if (!forceRefresh && this.cache && this.isCacheValid()) {
      this.logger.debug('Returning cached vehicle types');
      return this.cache;
    }

    this.logger.debug('Fetching vehicle types from API');
    const response = await this.http.get<VehicleTypeResponse[]>('/vehicle-types');
    this.cache = response.data;
    this.cacheTimestamp = Date.now();
    return this.cache;
  }

  getById(id: string): VehicleTypeResponse | undefined {
    return this.cache?.find((vt) => vt.id === id);
  }

  clearCache(): void {
    this.cache = null;
    this.cacheTimestamp = 0;
  }

  private isCacheValid(): boolean {
    return Date.now() - this.cacheTimestamp < this.cacheTtl;
  }
}
