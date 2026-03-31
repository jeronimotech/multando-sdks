import { InfractionResponse } from '../models/infraction';
export interface UseInfractionsResult {
    infractions: InfractionResponse[];
    isLoading: boolean;
    error: Error | null;
    refresh: () => Promise<void>;
    getById: (id: string) => InfractionResponse | undefined;
}
export declare function useInfractions(autoFetch?: boolean): UseInfractionsResult;
//# sourceMappingURL=useInfractions.d.ts.map