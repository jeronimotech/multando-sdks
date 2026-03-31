import { useState, useCallback } from 'react';
import { useMultando } from './useMultando';
import {
  ReportCreate,
  ReportDetail,
  ReportList,
} from '../models/report';
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

export function useReports(): UseReportsResult {
  const { client } = useMultando();
  const [reports, setReports] = useState<ReportList | null>(null);
  const [currentReport, setCurrentReport] = useState<ReportDetail | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);

  const list = useCallback(
    async (params?: ReportListParams): Promise<ReportList> => {
      setIsLoading(true);
      setError(null);
      try {
        const result = await client.reports.list(params);
        setReports(result);
        return result;
      } catch (err) {
        const e = err instanceof Error ? err : new Error(String(err));
        setError(e);
        throw e;
      } finally {
        setIsLoading(false);
      }
    },
    [client],
  );

  const getById = useCallback(
    async (id: string): Promise<ReportDetail> => {
      setIsLoading(true);
      setError(null);
      try {
        const result = await client.reports.getById(id);
        setCurrentReport(result);
        return result;
      } catch (err) {
        const e = err instanceof Error ? err : new Error(String(err));
        setError(e);
        throw e;
      } finally {
        setIsLoading(false);
      }
    },
    [client],
  );

  const getByPlate = useCallback(
    async (plate: string): Promise<ReportList> => {
      setIsLoading(true);
      setError(null);
      try {
        const result = await client.reports.getByPlate(plate);
        setReports(result);
        return result;
      } catch (err) {
        const e = err instanceof Error ? err : new Error(String(err));
        setError(e);
        throw e;
      } finally {
        setIsLoading(false);
      }
    },
    [client],
  );

  const create = useCallback(
    async (report: ReportCreate): Promise<ReportDetail | string> => {
      setIsLoading(true);
      setError(null);
      try {
        const result = await client.reports.create(report);
        return result;
      } catch (err) {
        const e = err instanceof Error ? err : new Error(String(err));
        setError(e);
        throw e;
      } finally {
        setIsLoading(false);
      }
    },
    [client],
  );

  const remove = useCallback(
    async (id: string): Promise<void> => {
      setIsLoading(true);
      setError(null);
      try {
        await client.reports.delete(id);
        if (reports) {
          setReports({
            ...reports,
            items: reports.items.filter((r) => r.id !== id),
            total: reports.total - 1,
          });
        }
      } catch (err) {
        const e = err instanceof Error ? err : new Error(String(err));
        setError(e);
        throw e;
      } finally {
        setIsLoading(false);
      }
    },
    [client, reports],
  );

  const refresh = useCallback(
    async (params?: ReportListParams): Promise<ReportList> => {
      return list(params);
    },
    [list],
  );

  return {
    reports,
    currentReport,
    isLoading,
    error,
    list,
    getById,
    getByPlate,
    create,
    remove,
    refresh,
  };
}
