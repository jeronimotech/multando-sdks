"""Authentication service."""

from __future__ import annotations

from typing import Optional, TYPE_CHECKING

from .models import TokenResponse, User

if TYPE_CHECKING:
    from ._http import HttpClient, SyncHttpClient


class AuthService:
    """Async authentication operations."""

    def __init__(self, http: "HttpClient") -> None:
        self._http = http

    async def register(
        self,
        username: str,
        display_name: str,
        email: str,
        password: str,
        phone: Optional[str] = None,
        locale: str = "en",
    ) -> TokenResponse:
        payload: dict = {
            "username": username,
            "display_name": display_name,
            "email": email,
            "password": password,
            "locale": locale,
        }
        if phone is not None:
            payload["phone_number"] = phone
        data = await self._http.post("/auth/register", json=payload)
        return TokenResponse.from_dict(data)

    async def login(self, email: str, password: str) -> TokenResponse:
        data = await self._http.post(
            "/auth/login", json={"email": email, "password": password},
        )
        return TokenResponse.from_dict(data)

    async def social_login(
        self,
        provider: str = "google",
        id_token: Optional[str] = None,
        code: Optional[str] = None,
        redirect_uri: Optional[str] = None,
    ) -> TokenResponse:
        payload: dict = {"provider": provider}
        if id_token is not None:
            payload["id_token"] = id_token
        if code is not None:
            payload["code"] = code
        if redirect_uri is not None:
            payload["redirect_uri"] = redirect_uri
        data = await self._http.post(f"/auth/oauth/{provider}", json=payload)
        return TokenResponse.from_dict(data)

    async def refresh(self, refresh_token: str) -> TokenResponse:
        data = await self._http.post(
            "/auth/refresh", json={"refresh_token": refresh_token},
        )
        return TokenResponse.from_dict(data)

    async def me(self) -> User:
        data = await self._http.get("/auth/me")
        return User.from_dict(data)

    async def exchange_oauth_code(
        self, code: str, redirect_uri: str,
    ) -> TokenResponse:
        """Exchange an OAuth authorization code for tokens."""
        data = await self._http.post("/oauth/token", json={
            "grant_type": "authorization_code",
            "code": code,
            "client_id": self._http._api_key or "",
            "redirect_uri": redirect_uri,
        })
        return TokenResponse.from_dict(data)

    def build_authorize_url(
        self,
        redirect_uri: str,
        scope: str = "reports:create,reports:read,infractions:read,balance:read",
        state: Optional[str] = None,
    ) -> str:
        """Build the OAuth authorization URL for the Multando consent screen."""
        from urllib.parse import urlencode
        base = self._http._base_url.replace("/api/v1", "")
        # Derive web frontend URL
        import re
        host = re.sub(r"https?://", "", base)
        if "multando.com" in host:
            web = "https://www.multando.com"
        else:
            web = base.rsplit(":", 1)[0] + ":3000"
        params = {
            "client_id": self._http._api_key or "",
            "redirect_uri": redirect_uri,
            "scope": scope,
            "response_type": "code",
            "api_base": self._http._base_url,
        }
        if state:
            params["state"] = state
        return f"{web}/oauth/authorize?{urlencode(params)}"


class SyncAuthService:
    """Synchronous authentication operations."""

    def __init__(self, http: "SyncHttpClient") -> None:
        self._http = http

    def register(
        self,
        username: str,
        display_name: str,
        email: str,
        password: str,
        phone: Optional[str] = None,
        locale: str = "en",
    ) -> TokenResponse:
        payload: dict = {
            "username": username,
            "display_name": display_name,
            "email": email,
            "password": password,
            "locale": locale,
        }
        if phone is not None:
            payload["phone_number"] = phone
        data = self._http.post("/auth/register", json=payload)
        return TokenResponse.from_dict(data)

    def login(self, email: str, password: str) -> TokenResponse:
        data = self._http.post(
            "/auth/login", json={"email": email, "password": password},
        )
        return TokenResponse.from_dict(data)

    def social_login(
        self,
        provider: str = "google",
        id_token: Optional[str] = None,
        code: Optional[str] = None,
        redirect_uri: Optional[str] = None,
    ) -> TokenResponse:
        payload: dict = {"provider": provider}
        if id_token is not None:
            payload["id_token"] = id_token
        if code is not None:
            payload["code"] = code
        if redirect_uri is not None:
            payload["redirect_uri"] = redirect_uri
        data = self._http.post(f"/auth/oauth/{provider}", json=payload)
        return TokenResponse.from_dict(data)

    def refresh(self, refresh_token: str) -> TokenResponse:
        data = self._http.post(
            "/auth/refresh", json={"refresh_token": refresh_token},
        )
        return TokenResponse.from_dict(data)

    def me(self) -> User:
        data = self._http.get("/auth/me")
        return User.from_dict(data)

    def exchange_oauth_code(
        self, code: str, redirect_uri: str,
    ) -> TokenResponse:
        """Exchange an OAuth authorization code for tokens."""
        data = self._http.post("/oauth/token", json={
            "grant_type": "authorization_code",
            "code": code,
            "client_id": self._http._api_key or "",
            "redirect_uri": redirect_uri,
        })
        return TokenResponse.from_dict(data)

    def build_authorize_url(
        self,
        redirect_uri: str,
        scope: str = "reports:create,reports:read,infractions:read,balance:read",
        state: Optional[str] = None,
    ) -> str:
        """Build the OAuth authorization URL for the Multando consent screen."""
        from urllib.parse import urlencode
        base = self._http._base_url.replace("/api/v1", "")
        import re
        host = re.sub(r"https?://", "", base)
        if "multando.com" in host:
            web = "https://www.multando.com"
        else:
            web = base.rsplit(":", 1)[0] + ":3000"
        params = {
            "client_id": self._http._api_key or "",
            "redirect_uri": redirect_uri,
            "scope": scope,
            "response_type": "code",
            "api_base": self._http._base_url,
        }
        if state:
            params["state"] = state
        return f"{web}/oauth/authorize?{urlencode(params)}"
