/**
 * Error classes for the Multando Node.js client.
 */

export class MultandoError extends Error {
  statusCode?: number;
  detail?: unknown;

  constructor(message: string, statusCode?: number, detail?: unknown) {
    super(message);
    this.name = 'MultandoError';
    this.statusCode = statusCode;
    this.detail = detail;
  }
}

export class AuthenticationError extends MultandoError {
  constructor(message = 'Authentication failed', detail?: unknown) {
    super(message, 401, detail);
    this.name = 'AuthenticationError';
  }
}

export class NotFoundError extends MultandoError {
  constructor(message = 'Resource not found', detail?: unknown) {
    super(message, 404, detail);
    this.name = 'NotFoundError';
  }
}

export class ValidationError extends MultandoError {
  constructor(message = 'Validation error', detail?: unknown) {
    super(message, 422, detail);
    this.name = 'ValidationError';
  }
}

export class RateLimitError extends MultandoError {
  retryAfter?: number;
  scope?: string;

  constructor(
    message = 'Rate limit exceeded',
    retryAfter?: number,
    scope?: string,
    detail?: unknown,
  ) {
    super(message, 429, detail);
    this.name = 'RateLimitError';
    this.retryAfter = retryAfter;
    this.scope = scope;
  }
}
