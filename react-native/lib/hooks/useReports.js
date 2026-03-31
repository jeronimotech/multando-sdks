"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.useReports = useReports;
const react_1 = require("react");
const useMultando_1 = require("./useMultando");
function useReports() {
    const { client } = (0, useMultando_1.useMultando)();
    const [reports, setReports] = (0, react_1.useState)(null);
    const [currentReport, setCurrentReport] = (0, react_1.useState)(null);
    const [isLoading, setIsLoading] = (0, react_1.useState)(false);
    const [error, setError] = (0, react_1.useState)(null);
    const list = (0, react_1.useCallback)(async (params) => {
        setIsLoading(true);
        setError(null);
        try {
            const result = await client.reports.list(params);
            setReports(result);
            return result;
        }
        catch (err) {
            const e = err instanceof Error ? err : new Error(String(err));
            setError(e);
            throw e;
        }
        finally {
            setIsLoading(false);
        }
    }, [client]);
    const getById = (0, react_1.useCallback)(async (id) => {
        setIsLoading(true);
        setError(null);
        try {
            const result = await client.reports.getById(id);
            setCurrentReport(result);
            return result;
        }
        catch (err) {
            const e = err instanceof Error ? err : new Error(String(err));
            setError(e);
            throw e;
        }
        finally {
            setIsLoading(false);
        }
    }, [client]);
    const getByPlate = (0, react_1.useCallback)(async (plate) => {
        setIsLoading(true);
        setError(null);
        try {
            const result = await client.reports.getByPlate(plate);
            setReports(result);
            return result;
        }
        catch (err) {
            const e = err instanceof Error ? err : new Error(String(err));
            setError(e);
            throw e;
        }
        finally {
            setIsLoading(false);
        }
    }, [client]);
    const create = (0, react_1.useCallback)(async (report) => {
        setIsLoading(true);
        setError(null);
        try {
            const result = await client.reports.create(report);
            return result;
        }
        catch (err) {
            const e = err instanceof Error ? err : new Error(String(err));
            setError(e);
            throw e;
        }
        finally {
            setIsLoading(false);
        }
    }, [client]);
    const remove = (0, react_1.useCallback)(async (id) => {
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
        }
        catch (err) {
            const e = err instanceof Error ? err : new Error(String(err));
            setError(e);
            throw e;
        }
        finally {
            setIsLoading(false);
        }
    }, [client, reports]);
    const refresh = (0, react_1.useCallback)(async (params) => {
        return list(params);
    }, [list]);
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
//# sourceMappingURL=useReports.js.map