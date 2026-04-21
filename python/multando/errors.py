"""Multando API error types."""

from __future__ import annotations


class MultandoError(Exception):
    """Base error for all Multando API failures."""

    def __init__(
        self,
        message: str,
        status_code: int | None = None,
        detail: object = None,
    ) -> None:
        super().__init__(message)
        self.message = message
        self.status_code = status_code
        self.detail = detail

    def __repr__(self) -> str:
        return (
            f"{type(self).__name__}(message={self.message!r}, "
            f"status_code={self.status_code!r})"
        )


class AuthenticationError(MultandoError):
    """Raised on 401 Unauthorized responses."""


class NotFoundError(MultandoError):
    """Raised on 404 Not Found responses."""


class ValidationError(MultandoError):
    """Raised on 422 Unprocessable Entity responses."""


class RateLimitError(MultandoError):
    """Raised on 429 Too Many Requests responses."""

    def __init__(
        self,
        message: str,
        retry_after: float | None = None,
        scope: str | None = None,
        status_code: int = 429,
        detail: object = None,
    ) -> None:
        super().__init__(message, status_code=status_code, detail=detail)
        self.retry_after = retry_after
        self.scope = scope
