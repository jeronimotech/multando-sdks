export declare class MultandoError extends Error {
    readonly code: string;
    readonly timestamp: Date;
    constructor(message: string, code: string);
}
export declare class MultandoApiError extends MultandoError {
    readonly statusCode: number;
    readonly detail: string | Record<string, unknown> | null;
    constructor(message: string, statusCode: number, detail?: string | Record<string, unknown> | null);
}
export declare class MultandoNetworkError extends MultandoError {
    readonly isOffline: boolean;
    constructor(message: string, isOffline?: boolean);
}
export declare class MultandoValidationError extends MultandoError {
    readonly fields: Record<string, string[]>;
    constructor(message: string, fields?: Record<string, string[]>);
}
export declare class MultandoAuthError extends MultandoError {
    readonly isExpired: boolean;
    constructor(message: string, isExpired?: boolean);
}
//# sourceMappingURL=error.d.ts.map