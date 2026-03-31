"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createHttpClient = createHttpClient;
const axios_1 = __importDefault(require("axios"));
const error_1 = require("../models/error");
function toSnakeCase(str) {
    return str.replace(/[A-Z]/g, (letter) => `_${letter.toLowerCase()}`);
}
function toCamelCase(str) {
    return str.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
}
function transformKeys(obj, transformer) {
    if (obj === null || obj === undefined)
        return obj;
    if (Array.isArray(obj)) {
        return obj.map((item) => transformKeys(item, transformer));
    }
    if (typeof obj === 'object' && !(obj instanceof Date)) {
        const result = {};
        for (const [key, value] of Object.entries(obj)) {
            result[transformer(key)] = transformKeys(value, transformer);
        }
        return result;
    }
    return obj;
}
function createHttpClient(config, authManager, logger) {
    const client = axios_1.default.create({
        baseURL: `${config.baseUrl}/api/v1`,
        timeout: config.timeout,
        headers: {
            'Content-Type': 'application/json',
            'X-API-Key': config.apiKey,
        },
    });
    let isRefreshing = false;
    let failedQueue = [];
    function processQueue(error) {
        failedQueue.forEach(({ resolve, reject, config: reqConfig }) => {
            if (error) {
                reject(error);
            }
            else {
                resolve(client.request(reqConfig));
            }
        });
        failedQueue = [];
    }
    // Request interceptor: inject auth token and transform to snake_case
    client.interceptors.request.use(async (reqConfig) => {
        const token = await authManager.getAccessToken();
        if (token) {
            reqConfig.headers.Authorization = `Bearer ${token}`;
        }
        if (reqConfig.data && typeof reqConfig.data === 'object') {
            reqConfig.data = transformKeys(reqConfig.data, toSnakeCase);
        }
        if (reqConfig.params && typeof reqConfig.params === 'object') {
            reqConfig.params = transformKeys(reqConfig.params, toSnakeCase);
        }
        logger.debug('Request', {
            method: reqConfig.method,
            url: reqConfig.url,
        });
        return reqConfig;
    }, (error) => Promise.reject(error));
    // Response interceptor: transform to camelCase and handle 401
    client.interceptors.response.use((response) => {
        if (response.data && typeof response.data === 'object') {
            response.data = transformKeys(response.data, toCamelCase);
        }
        logger.debug('Response', {
            status: response.status,
            url: response.config.url,
        });
        return response;
    }, async (error) => {
        const originalRequest = error.config;
        // Handle 401 with token refresh
        if (error.response?.status === 401 &&
            originalRequest &&
            !originalRequest._retry) {
            if (isRefreshing) {
                return new Promise((resolve, reject) => {
                    failedQueue.push({
                        resolve,
                        reject,
                        config: originalRequest,
                    });
                });
            }
            originalRequest._retry = true;
            isRefreshing = true;
            try {
                await authManager.refreshAccessToken();
                processQueue(null);
                const newToken = await authManager.getAccessToken();
                if (newToken) {
                    originalRequest.headers.Authorization = `Bearer ${newToken}`;
                }
                return client.request(originalRequest);
            }
            catch (refreshError) {
                processQueue(refreshError);
                await authManager.clearTokens();
                throw new error_1.MultandoAuthError('Session expired. Please log in again.', true);
            }
            finally {
                isRefreshing = false;
            }
        }
        throw mapAxiosError(error);
    });
    return client;
}
function mapAxiosError(error) {
    if (!error.response) {
        return new error_1.MultandoNetworkError(error.message || 'Network request failed', !error.response && error.code === 'ERR_NETWORK');
    }
    const { status, data } = error.response;
    const responseData = data;
    if (status === 401 || status === 403) {
        return new error_1.MultandoAuthError(responseData?.detail || 'Authentication failed', status === 401);
    }
    if (status === 422) {
        const detail = responseData?.detail;
        const fields = {};
        if (Array.isArray(detail)) {
            for (const err of detail) {
                const field = err.loc?.[err.loc.length - 1] || 'unknown';
                const camelField = field.replace(/_([a-z])/g, (_, l) => l.toUpperCase());
                if (!fields[camelField])
                    fields[camelField] = [];
                fields[camelField].push(err.msg);
            }
        }
        return new error_1.MultandoValidationError('Validation failed', fields);
    }
    return new error_1.MultandoApiError(responseData?.detail || `Request failed with status ${status}`, status, responseData?.detail);
}
//# sourceMappingURL=httpClient.js.map