"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.useVehicleTypes = useVehicleTypes;
const react_1 = require("react");
const useMultando_1 = require("./useMultando");
function useVehicleTypes(autoFetch = true) {
    const { client } = (0, useMultando_1.useMultando)();
    const [vehicleTypes, setVehicleTypes] = (0, react_1.useState)([]);
    const [isLoading, setIsLoading] = (0, react_1.useState)(false);
    const [error, setError] = (0, react_1.useState)(null);
    const fetchVehicleTypes = (0, react_1.useCallback)(async (forceRefresh = false) => {
        setIsLoading(true);
        setError(null);
        try {
            const result = await client.vehicleTypes.list(forceRefresh);
            setVehicleTypes(result);
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
            fetchVehicleTypes();
        }
    }, [autoFetch, fetchVehicleTypes]);
    const refresh = (0, react_1.useCallback)(async () => {
        await fetchVehicleTypes(true);
    }, [fetchVehicleTypes]);
    const getById = (0, react_1.useCallback)((id) => {
        return vehicleTypes.find((vt) => vt.id === id);
    }, [vehicleTypes]);
    return {
        vehicleTypes,
        isLoading,
        error,
        refresh,
        getById,
    };
}
//# sourceMappingURL=useVehicleTypes.js.map