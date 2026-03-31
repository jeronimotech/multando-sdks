import { LogLevel } from '../models/enums';

const LOG_PRIORITY: Record<LogLevel, number> = {
  [LogLevel.None]: 0,
  [LogLevel.Error]: 1,
  [LogLevel.Warn]: 2,
  [LogLevel.Info]: 3,
  [LogLevel.Debug]: 4,
};

export class Logger {
  private level: LogLevel;
  private prefix = '[Multando]';

  constructor(level: LogLevel) {
    this.level = level;
  }

  private shouldLog(level: LogLevel): boolean {
    return LOG_PRIORITY[this.level] >= LOG_PRIORITY[level];
  }

  error(message: string, data?: unknown): void {
    if (this.shouldLog(LogLevel.Error)) {
      console.error(`${this.prefix} ERROR: ${message}`, data ?? '');
    }
  }

  warn(message: string, data?: unknown): void {
    if (this.shouldLog(LogLevel.Warn)) {
      console.warn(`${this.prefix} WARN: ${message}`, data ?? '');
    }
  }

  info(message: string, data?: unknown): void {
    if (this.shouldLog(LogLevel.Info)) {
      console.info(`${this.prefix} INFO: ${message}`, data ?? '');
    }
  }

  debug(message: string, data?: unknown): void {
    if (this.shouldLog(LogLevel.Debug)) {
      console.debug(`${this.prefix} DEBUG: ${message}`, data ?? '');
    }
  }
}
