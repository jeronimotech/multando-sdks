import { VehicleTypeResponse } from '../models/vehicleType';
export interface UseVehicleTypesResult {
    vehicleTypes: VehicleTypeResponse[];
    isLoading: boolean;
    error: Error | null;
    refresh: () => Promise<void>;
    getById: (id: string) => VehicleTypeResponse | undefined;
}
export declare function useVehicleTypes(autoFetch?: boolean): UseVehicleTypesResult;
//# sourceMappingURL=useVehicleTypes.d.ts.map