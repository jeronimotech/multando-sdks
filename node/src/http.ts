/**
 * HTTP wrapper using native fetch (Node 18+, zero dependencies).
 */

import {
  MultandoError,
  AuthenticationError,
  NotFoundError,
  RateLimitError,
  ValidationError,
} from './errors.js';

export class HttpClient {
  private baseUrl: string;
  private apiKey?: string;
  private accessToken?: string;

  constructor(baseUrl: string, apiKey?: string) {
    // Strip trailing slash
    this.baseUrl = baseUrl.replace(/\/+$/, '');
    this.apiKey = apiKey;
  }

  setAccessToken(token: string): void {
    this.accessToken = token;
  }

  clearAccessToken(): void {
    this.accessToken = undefined;
  }

  private buildHeaders(): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    };
    if (this.apiKey) {
      headers['X-API-Key'] = this.apiKey;
    }
    if (this.accessToken) {
      headers['Authorization'] = `Bearer ${this.accessToken}`;
    }
    return headers;
  }

  private buildUrl(path: string, params?: Record<string, string>): string {
    const url = new URL(`${this.baseUrl}${path}`);
    if (params) {
      for (const [key, value] of Object.entries(params)) {
        if (value !== undefined && value !== null) {
          url.searchParams.set(key, value);
        }
      }
    }
    return url.toString();
  }

  private async handleResponse<T>(response: Response): Promise<T> {
    let body: unknown;
    const contentType = response.headers.get('content-type') ?? '';
    if (contentType.includes('application/json')) {
      body = await response.json();
    } else {
      body = await response.text();
    }

    if (response.ok) {
      return body as T;
    }

    const detail = typeof body === 'object' && body !== null && 'detail' in body
      ? (body as Record<string, unknown>).detail
      : body;

    const message = typeof detail === 'string'
      ? detail
      : `Request failed with status ${response.status}`;

    switch (response.status) {
      case 401:
        throw new AuthenticationError(message, detail);
      case 404:
        throw new NotFoundError(message, detail);
      case 422:
        throw new ValidationError(message, detail);
      case 429: {
        const retryAfter = response.headers.get('retry-after');
        const scope = response.headers.get('x-ratelimit-scope') ?? undefined;
        throw new RateLimitError(
          message,
          retryAfter ? parseInt(retryAfter, 10) : undefined,
          scope,
          detail,
        );
      }
      default:
        throw new MultandoError(message, response.status, detail);
    }
  }

  async get<T>(path: string, params?: Record<string, string>): Promise<T> {
    const response = await fetch(this.buildUrl(path, params), {
      method: 'GET',
      headers: this.buildHeaders(),
    });
    return this.handleResponse<T>(response);
  }

  async post<T>(path: string, body?: unknown): Promise<T> {
    const response = await fetch(this.buildUrl(path), {
      method: 'POST',
      headers: this.buildHeaders(),
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
    return this.handleResponse<T>(response);
  }

  async put<T>(path: string, body?: unknown): Promise<T> {
    const response = await fetch(this.buildUrl(path), {
      method: 'PUT',
      headers: this.buildHeaders(),
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
    return this.handleResponse<T>(response);
  }

  async delete<T>(path: string): Promise<T> {
    const response = await fetch(this.buildUrl(path), {
      method: 'DELETE',
      headers: this.buildHeaders(),
    });
    return this.handleResponse<T>(response);
  }
}
