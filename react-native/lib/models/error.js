"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MultandoAuthError = exports.MultandoValidationError = exports.MultandoNetworkError = exports.MultandoApiError = exports.MultandoError = void 0;
class MultandoError extends Error {
    constructor(message, code) {
        super(message);
        this.name = 'MultandoError';
        this.code = code;
        this.timestamp = new Date();
        Object.setPrototypeOf(this, new.target.prototype);
    }
}
exports.MultandoError = MultandoError;
class MultandoApiError extends MultandoError {
    constructor(message, statusCode, detail = null) {
        super(message, 'API_ERROR');
        this.name = 'MultandoApiError';
        this.statusCode = statusCode;
        this.detail = detail;
    }
}
exports.MultandoApiError = MultandoApiError;
class MultandoNetworkError extends MultandoError {
    constructor(message, isOffline = false) {
        super(message, 'NETWORK_ERROR');
        this.name = 'MultandoNetworkError';
        this.isOffline = isOffline;
    }
}
exports.MultandoNetworkError = MultandoNetworkError;
class MultandoValidationError extends MultandoError {
    constructor(message, fields = {}) {
        super(message, 'VALIDATION_ERROR');
        this.name = 'MultandoValidationError';
        this.fields = fields;
    }
}
exports.MultandoValidationError = MultandoValidationError;
class MultandoAuthError extends MultandoError {
    constructor(message, isExpired = false) {
        super(message, 'AUTH_ERROR');
        this.name = 'MultandoAuthError';
        this.isExpired = isExpired;
    }
}
exports.MultandoAuthError = MultandoAuthError;
//# sourceMappingURL=error.js.map