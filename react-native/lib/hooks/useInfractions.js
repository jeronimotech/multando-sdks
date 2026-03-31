"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.useInfractions = useInfractions;
const react_1 = require("react");
const useMultando_1 = require("./useMultando");
function useInfractions(autoFetch = true) {
    const { client } = (0, useMultando_1.useMultando)();
    const [infractions, setInfractions] = (0, react_1.useState)([]);
    const [isLoading, setIsLoading] = (0, react_1.useState)(false);
    const [error, setError] = (0, react_1.useState)(null);
    const fetchInfractions = (0, react_1.useCallback)(async (forceRefresh = false) => {
        setIsLoading(true);
        setError(null);
        try {
            const result = await client.infractions.list(forceRefresh);
            setInfractions(result);
        }
        catch (err) {
            const e = err instanceof Error ? err : new Error(String(err));
            setError(e);
        }
        finally {
            setIsLoading(false);
        }
    }, [client]);
    (0, react_1.useEffect)(() => {
        if (autoFetch) {
            fetchInfractions();
        }
    }, [autoFetch, fetchInfractions]);
    const refresh = (0, react_1.useCallback)(async () => {
        await fetchInfractions(true);
    }, [fetchInfractions]);
    const getById = (0, react_1.useCallback)((id) => {
        return infractions.find((i) => i.id === id);
    }, [infractions]);
    return {
        infractions,
        isLoading,
        error,
        refresh,
        getById,
    };
}
//# sourceMappingURL=useInfractions.js.map