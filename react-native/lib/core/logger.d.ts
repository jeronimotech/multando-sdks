import { LogLevel } from '../models/enums';
export declare class Logger {
    private level;
    private prefix;
    constructor(level: LogLevel);
    private shouldLog;
    error(message: string, data?: unknown): void;
    warn(message: string, data?: unknown): void;
    info(message: string, data?: unknown): void;
    debug(message: string, data?: unknown): void;
}
//# sourceMappingURL=logger.d.ts.map