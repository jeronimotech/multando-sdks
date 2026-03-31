import { RejectRequest, VerificationResult, VerificationQueue } from '../models/verification';
export interface UseVerificationResult {
    queue: VerificationQueue | null;
    isLoading: boolean;
    error: Error | null;
    fetchQueue: () => Promise<VerificationQueue>;
    verify: (reportId: string) => Promise<VerificationResult>;
    reject: (reportId: string, request: RejectRequest) => Promise<VerificationResult>;
}
export declare function useVerification(): UseVerificationResult;
//# sourceMappingURL=useVerification.d.ts.map