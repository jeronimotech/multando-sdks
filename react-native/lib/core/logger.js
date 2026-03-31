"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Logger = void 0;
const enums_1 = require("../models/enums");
const LOG_PRIORITY = {
    [enums_1.LogLevel.None]: 0,
    [enums_1.LogLevel.Error]: 1,
    [enums_1.LogLevel.Warn]: 2,
    [enums_1.LogLevel.Info]: 3,
    [enums_1.LogLevel.Debug]: 4,
};
class Logger {
    constructor(level) {
        this.prefix = '[Multando]';
        this.level = level;
    }
    shouldLog(level) {
        return LOG_PRIORITY[this.level] >= LOG_PRIORITY[level];
    }
    error(message, data) {
        if (this.shouldLog(enums_1.LogLevel.Error)) {
            console.error(`${this.prefix} ERROR: ${message}`, data ?? '');
        }
    }
    warn(message, data) {
        if (this.shouldLog(enums_1.LogLevel.Warn)) {
            console.warn(`${this.prefix} WARN: ${message}`, data ?? '');
        }
    }
    info(message, data) {
        if (this.shouldLog(enums_1.LogLevel.Info)) {
            console.info(`${this.prefix} INFO: ${message}`, data ?? '');
        }
    }
    debug(message, data) {
        if (this.shouldLog(enums_1.LogLevel.Debug)) {
            console.debug(`${this.prefix} DEBUG: ${message}`, data ?? '');
        }
    }
}
exports.Logger = Logger;
//# sourceMappingURL=logger.js.map