export class MultandoError extends Error {
  public readonly code: string;
  public readonly timestamp: Date;

  constructor(message: string, code: string) {
    super(message);
    this.name = 'MultandoError';
    this.code = code;
    this.timestamp = new Date();
    Object.setPrototypeOf(this, new.target.prototype);
  }
}

export class MultandoApiError extends MultandoError {
  public readonly statusCode: number;
  public readonly detail: string | Record<string, unknown> | null;

  constructor(
    message: string,
    statusCode: number,
    detail: string | Record<string, unknown> | null = null,
  ) {
    super(message, 'API_ERROR');
    this.name = 'MultandoApiError';
    this.statusCode = statusCode;
    this.detail = detail;
  }
}

export class MultandoNetworkError extends MultandoError {
  public readonly isOffline: boolean;

  constructor(message: string, isOffline: boolean = false) {
    super(message, 'NETWORK_ERROR');
    this.name = 'MultandoNetworkError';
    this.isOffline = isOffline;
  }
}

export class MultandoValidationError extends MultandoError {
  public readonly fields: Record<string, string[]>;

  constructor(message: string, fields: Record<string, string[]> = {}) {
    super(message, 'VALIDATION_ERROR');
    this.name = 'MultandoValidationError';
    this.fields = fields;
  }
}

export class MultandoAuthError extends MultandoError {
  public readonly isExpired: boolean;

  constructor(message: string, isExpired: boolean = false) {
    super(message, 'AUTH_ERROR');
    this.name = 'MultandoAuthError';
    this.isExpired = isExpired;
  }
}

/**
 * Thrown when the backend returns HTTP 429 with a structured
 * ``error: "rate_limit_exceeded"`` body.
 *
 * ``scope`` mirrors the backend ``limit`` field — values include
 * ``reports_per_hour`` and ``reports_per_day`` (see
 * ``multando-backend/app/services/rate_limiter.py``). Apps typically
 * branch on ``scope`` to show a localized hourly/daily message.
 */
export class RateLimitError extends MultandoError {
  public readonly statusCode: number = 429;
  public readonly retryAfterSeconds: number;
  public readonly scope: string;

  constructor(message: string, retryAfterSeconds: number, scope: string) {
    super(message, 'RATE_LIMIT');
    this.name = 'RateLimitError';
    this.retryAfterSeconds = retryAfterSeconds;
    this.scope = scope;
  }
}

/**
 * Thrown when the backend blocks a report because the same plate was
 * already reported (either by this user or globally near this
 * location) inside the plate-cooldown window.
 *
 * Surfaced as HTTP 429 with ``error: "rate_limit_exceeded"`` and a
 * ``limit`` of ``same_plate_per_user_24h`` or ``plate_reports_24h``.
 */
export class PlateCooldownError extends MultandoError {
  public readonly statusCode: number = 429;
  public readonly plate: string;
  public readonly retryAfterHours: number;

  constructor(message: string, plate: string, retryAfterHours: number) {
    super(message, 'PLATE_COOLDOWN');
    this.name = 'PlateCooldownError';
    this.plate = plate;
    this.retryAfterHours = retryAfterHours;
  }
}
