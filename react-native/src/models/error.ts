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
