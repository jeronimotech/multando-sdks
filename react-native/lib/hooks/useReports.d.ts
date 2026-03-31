import { ReportCreate, ReportDetail, ReportList } from '../models/report';
import { ReportListParams } from '../services/reportService';
export interface UseReportsResult {
    reports: ReportList | null;
    currentReport: ReportDetail | null;
    isLoading: boolean;
    error: Error | null;
    list: (params?: ReportListParams) => Promise<ReportList>;
    getById: (id: string) => Promise<ReportDetail>;
    getByPlate: (plate: string) => Promise<ReportList>;
    create: (report: ReportCreate) => Promise<ReportDetail | string>;
    remove: (id: string) => Promise<void>;
    refresh: (params?: ReportListParams) => Promise<ReportList>;
}
export declare function useReports(): UseReportsResult;
//# sourceMappingURL=useReports.d.ts.map