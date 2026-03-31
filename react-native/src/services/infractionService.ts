import { AxiosInstance } from 'axios';
import { Logger } from '../core/logger';
import { InfractionResponse } from '../models/infraction';

export class InfractionService {
  private http: AxiosInstance;
  private logger: Logger;
  private cache: InfractionResponse[] | null = null;
  private cacheTimestamp: number = 0;
  private cacheTtl: number;

  constructor(http: AxiosInstance, logger: Logger, cacheTtlMs: number = 300000) {
    this.http = http;
    this.logger = logger;
    this.cacheTtl = cacheTtlMs;
  }

  async list(forceRefresh = false): Promise<InfractionResponse[]> {
    if (!forceRefresh && this.cache && this.isCacheValid()) {
      this.logger.debug('Returning cached infractions');
      return this.cache;
    }

    this.logger.debug('Fetching infractions from API');
    const response = await this.http.get<InfractionResponse[]>('/infractions');
    this.cache = response.data;
    this.cacheTimestamp = Date.now();
    return this.cache;
  }

  getById(id: string): InfractionResponse | undefined {
    return this.cache?.find((infraction) => infraction.id === id);
  }

  clearCache(): void {
    this.cache = null;
    this.cacheTimestamp = 0;
  }

  private isCacheValid(): boolean {
    return Date.now() - this.cacheTimestamp < this.cacheTtl;
  }
}
