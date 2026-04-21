"""Low-level HTTP transport for the Multando client.

Provides both async (``HttpClient``) and synchronous (``SyncHttpClient``)
wrappers around *httpx* with automatic retry on 429 / 5xx responses.
"""

from __future__ import annotations

import asyncio
import time
from typing import Any, Dict, Optional

import httpx

from .errors import (
    AuthenticationError,
    MultandoError,
    NotFoundError,
    RateLimitError,
    ValidationError,
)

_MAX_RETRIES = 3
_RETRY_BACKOFF = 1.0  # seconds, doubled each attempt


def _default_headers(
    api_key: Optional[str] = None,
    access_token: Optional[str] = None,
) -> Dict[str, str]:
    headers: Dict[str, str] = {"Accept": "application/json"}
    if api_key:
        headers["X-API-Key"] = api_key
    if access_token:
        headers["Authorization"] = f"Bearer {access_token}"
    return headers


def _raise_for_status(response: httpx.Response) -> None:
    status = response.status_code
    if status < 400:
        return

    try:
        body = response.json()
    except Exception:
        body = {"detail": response.text}

    message = body.get("detail", body.get("message", response.text))
    if isinstance(message, list):
        message = "; ".join(str(m) for m in message)

    if status == 401:
        raise AuthenticationError(str(message), status_code=status, detail=body)
    if status == 404:
        raise NotFoundError(str(message), status_code=status, detail=body)
    if status == 422:
        raise ValidationError(str(message), status_code=status, detail=body)
    if status == 429:
        retry_after = response.headers.get("Retry-After")
        scope = response.headers.get("X-RateLimit-Scope")
        raise RateLimitError(
            str(message),
            retry_after=float(retry_after) if retry_after else None,
            scope=scope,
            detail=body,
        )
    raise MultandoError(str(message), status_code=status, detail=body)


def _should_retry(status_code: int) -> bool:
    return status_code == 429 or status_code >= 500


# ------------------------------------------------------------------
# Async client
# ------------------------------------------------------------------

class HttpClient:
    """Async HTTP client with retry logic."""

    def __init__(
        self,
        base_url: str,
        api_key: Optional[str] = None,
        access_token: Optional[str] = None,
        timeout: float = 30.0,
    ) -> None:
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self.access_token = access_token
        self._client = httpx.AsyncClient(
            base_url=self.base_url,
            headers=_default_headers(api_key, access_token),
            timeout=timeout,
        )

    # Allow updating the bearer token after login.
    def set_access_token(self, token: str) -> None:
        self.access_token = token
        self._client.headers["Authorization"] = f"Bearer {token}"

    async def _request(
        self,
        method: str,
        path: str,
        *,
        params: Optional[Dict[str, Any]] = None,
        json: Optional[Any] = None,
    ) -> dict:
        last_exc: Optional[Exception] = None
        for attempt in range(_MAX_RETRIES):
            try:
                resp = await self._client.request(
                    method, path, params=params, json=json,
                )
                if _should_retry(resp.status_code) and attempt < _MAX_RETRIES - 1:
                    wait = _RETRY_BACKOFF * (2 ** attempt)
                    retry_hdr = resp.headers.get("Retry-After")
                    if retry_hdr:
                        wait = max(wait, float(retry_hdr))
                    await asyncio.sleep(wait)
                    continue
                _raise_for_status(resp)
                if resp.status_code == 204:
                    return {}
                return resp.json()
            except (httpx.TransportError, httpx.TimeoutException) as exc:
                last_exc = exc
                if attempt < _MAX_RETRIES - 1:
                    await asyncio.sleep(_RETRY_BACKOFF * (2 ** attempt))
                    continue
                raise MultandoError(str(exc)) from exc
        raise MultandoError("Max retries exceeded") from last_exc  # pragma: no cover

    async def get(self, path: str, params: Optional[Dict[str, Any]] = None) -> dict:
        return await self._request("GET", path, params=params)

    async def post(self, path: str, json: Optional[Any] = None) -> dict:
        return await self._request("POST", path, json=json)

    async def put(self, path: str, json: Optional[Any] = None) -> dict:
        return await self._request("PUT", path, json=json)

    async def delete(self, path: str) -> dict:
        return await self._request("DELETE", path)

    async def aclose(self) -> None:
        await self._client.aclose()


# ------------------------------------------------------------------
# Sync client
# ------------------------------------------------------------------

class SyncHttpClient:
    """Synchronous HTTP client with retry logic."""

    def __init__(
        self,
        base_url: str,
        api_key: Optional[str] = None,
        access_token: Optional[str] = None,
        timeout: float = 30.0,
    ) -> None:
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self.access_token = access_token
        self._client = httpx.Client(
            base_url=self.base_url,
            headers=_default_headers(api_key, access_token),
            timeout=timeout,
        )

    def set_access_token(self, token: str) -> None:
        self.access_token = token
        self._client.headers["Authorization"] = f"Bearer {token}"

    def _request(
        self,
        method: str,
        path: str,
        *,
        params: Optional[Dict[str, Any]] = None,
        json: Optional[Any] = None,
    ) -> dict:
        last_exc: Optional[Exception] = None
        for attempt in range(_MAX_RETRIES):
            try:
                resp = self._client.request(
                    method, path, params=params, json=json,
                )
                if _should_retry(resp.status_code) and attempt < _MAX_RETRIES - 1:
                    wait = _RETRY_BACKOFF * (2 ** attempt)
                    retry_hdr = resp.headers.get("Retry-After")
                    if retry_hdr:
                        wait = max(wait, float(retry_hdr))
                    time.sleep(wait)
                    continue
                _raise_for_status(resp)
                if resp.status_code == 204:
                    return {}
                return resp.json()
            except (httpx.TransportError, httpx.TimeoutException) as exc:
                last_exc = exc
                if attempt < _MAX_RETRIES - 1:
                    time.sleep(_RETRY_BACKOFF * (2 ** attempt))
                    continue
                raise MultandoError(str(exc)) from exc
        raise MultandoError("Max retries exceeded") from last_exc  # pragma: no cover

    def get(self, path: str, params: Optional[Dict[str, Any]] = None) -> dict:
        return self._request("GET", path, params=params)

    def post(self, path: str, json: Optional[Any] = None) -> dict:
        return self._request("POST", path, json=json)

    def put(self, path: str, json: Optional[Any] = None) -> dict:
        return self._request("PUT", path, json=json)

    def delete(self, path: str) -> dict:
        return self._request("DELETE", path)

    def close(self) -> None:
        self._client.close()
