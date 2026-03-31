"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.useVerification = useVerification;
const react_1 = require("react");
const useMultando_1 = require("./useMultando");
function useVerification() {
    const { client } = (0, useMultando_1.useMultando)();
    const [queue, setQueue] = (0, react_1.useState)(null);
    const [isLoading, setIsLoading] = (0, react_1.useState)(false);
    const [error, setError] = (0, react_1.useState)(null);
    const fetchQueue = (0, react_1.useCallback)(async () => {
        setIsLoading(true);
        setError(null);
        try {
            const result = await client.verification.getQueue();
            setQueue(result);
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
    const verify = (0, react_1.useCallback)(async (reportId) => {
        setIsLoading(true);
        setError(null);
        try {
            const result = await client.verification.verify(reportId);
            // Remove from local queue
            if (queue) {
                setQueue({
                    ...queue,
                    items: queue.items.filter((item) => item.report.id !== reportId),
                    total: queue.total - 1,
                });
            }
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
    }, [client, queue]);
    const reject = (0, react_1.useCallback)(async (reportId, request) => {
        setIsLoading(true);
        setError(null);
        try {
            const result = await client.verification.reject(reportId, request);
            if (queue) {
                setQueue({
                    ...queue,
                    items: queue.items.filter((item) => item.report.id !== reportId),
                    total: queue.total - 1,
                });
            }
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
    }, [client, queue]);
    return {
        queue,
        isLoading,
        error,
        fetchQueue,
        verify,
        reject,
    };
}
//# sourceMappingURL=useVerification.js.map