import { AxiosInstance } from 'axios';
import { OfflineQueue } from '../core/offlineQueue';
import { Logger } from '../core/logger';
import { ReportCreate, ReportDetail, ReportList } from '../models/report';
export interface ReportListParams {
    page?: number;
    pageSize?: number;
    status?: string;
}
export declare class ReportService {
    private http;
    private offlineQueue;
    private logger;
    constructor(http: AxiosInstance, offlineQueue: OfflineQueue, logger: Logger);
    create(report: ReportCreate): Promise<ReportDetail | string>;
    list(params?: ReportListParams): Promise<ReportList>;
    getById(id: string): Promise<ReportDetail>;
    getByPlate(plate: string): Promise<ReportList>;
    delete(id: string): Promise<void>;
    private isNetworkError;
}
//# sourceMappingURL=reportService.d.ts.map