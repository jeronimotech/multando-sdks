import axios, {
  AxiosInstance,
  AxiosRequestConfig,
  InternalAxiosRequestConfig,
  AxiosResponse,
  AxiosError,
} from 'axios';
import { MultandoConfig } from './config';
import { AuthManager } from './authManager';
import {
  MultandoApiError,
  MultandoNetworkError,
  MultandoValidationError,
  MultandoAuthError,
} from '../models/error';
import { Logger } from './logger';

function toSnakeCase(str: string): string {
  return str.replace(/[A-Z]/g, (letter) => `_${letter.toLowerCase()}`);
}

function toCamelCase(str: string): string {
  return str.replace(/_([a-z])/g, (_, letter: string) => letter.toUpperCase());
}

function transformKeys(
  obj: unknown,
  transformer: (key: string) => string,
): unknown {
  if (obj === null || obj === undefined) return obj;
  if (Array.isArray(obj)) {
    return obj.map((item) => transformKeys(item, transformer));
  }
  if (typeof obj === 'object' && !(obj instanceof Date)) {
    const result: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(obj as Record<string, unknown>)) {
      result[transformer(key)] = transformKeys(value, transformer);
    }
    return result;
  }
  return obj;
}

export function createHttpClient(
  config: Required<MultandoConfig>,
  authManager: AuthManager,
  logger: Logger,
): AxiosInstance {
  const client = axios.create({
    baseURL: `${config.baseUrl}/api/v1`,
    timeout: config.timeout,
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': config.apiKey,
    },
  });

  let isRefreshing = false;
  let failedQueue: Array<{
    resolve: (value: unknown) => void;
    reject: (reason: unknown) => void;
    config: InternalAxiosRequestConfig;
  }> = [];

  function processQueue(error: Error | null): void {
    failedQueue.forEach(({ resolve, reject, config: reqConfig }) => {
      if (error) {
        reject(error);
      } else {
        resolve(client.request(reqConfig));
      }
    });
    failedQueue = [];
  }

  // Request interceptor: inject auth token and transform to snake_case
  client.interceptors.request.use(
    async (reqConfig: InternalAxiosRequestConfig) => {
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
    },
    (error: AxiosError) => Promise.reject(error),
  );

  // Response interceptor: transform to camelCase and handle 401
  client.interceptors.response.use(
    (response: AxiosResponse) => {
      if (response.data && typeof response.data === 'object') {
        response.data = transformKeys(response.data, toCamelCase);
      }
      logger.debug('Response', {
        status: response.status,
        url: response.config.url,
      });
      return response;
    },
    async (error: AxiosError) => {
      const originalRequest = error.config as InternalAxiosRequestConfig & {
        _retry?: boolean;
      };

      // Handle 401 with token refresh
      if (
        error.response?.status === 401 &&
        originalRequest &&
        !originalRequest._retry
      ) {
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
        } catch (refreshError) {
          processQueue(refreshError as Error);
          await authManager.clearTokens();
          throw new MultandoAuthError(
            'Session expired. Please log in again.',
            true,
          );
        } finally {
          isRefreshing = false;
        }
      }

      throw mapAxiosError(error);
    },
  );

  return client;
}

function mapAxiosError(error: AxiosError): MultandoError {
  if (!error.response) {
    return new MultandoNetworkError(
      error.message || 'Network request failed',
      !error.response && error.code === 'ERR_NETWORK',
    );
  }

  const { status, data } = error.response;
  const responseData = data as Record<string, unknown> | undefined;

  if (status === 401 || status === 403) {
    return new MultandoAuthError(
      (responseData?.detail as string) || 'Authentication failed',
      status === 401,
    );
  }

  if (status === 422) {
    const detail = responseData?.detail;
    const fields: Record<string, string[]> = {};
    if (Array.isArray(detail)) {
      for (const err of detail as Array<{ loc: string[]; msg: string }>) {
        const field = err.loc?.[err.loc.length - 1] || 'unknown';
        const camelField = field.replace(/_([a-z])/g, (_, l: string) =>
          l.toUpperCase(),
        );
        if (!fields[camelField]) fields[camelField] = [];
        fields[camelField].push(err.msg);
      }
    }
    return new MultandoValidationError('Validation failed', fields);
  }

  return new MultandoApiError(
    (responseData?.detail as string) || `Request failed with status ${status}`,
    status,
    responseData?.detail as string | Record<string, unknown> | null,
  );
}

type MultandoError =
  | MultandoApiError
  | MultandoNetworkError
  | MultandoValidationError
  | MultandoAuthError;

export type { AxiosInstance, AxiosRequestConfig };
