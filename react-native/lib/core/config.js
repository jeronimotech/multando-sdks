"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DEFAULT_CONFIG = void 0;
exports.resolveConfig = resolveConfig;
const enums_1 = require("../models/enums");
exports.DEFAULT_CONFIG = {
    locale: enums_1.Locale.En,
    timeout: 30000,
    enableOfflineQueue: true,
    logLevel: enums_1.LogLevel.Error,
};
function resolveConfig(config) {
    return {
        ...exports.DEFAULT_CONFIG,
        ...config,
    };
}
//# sourceMappingURL=config.js.map