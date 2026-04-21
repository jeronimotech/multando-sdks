"""High-level Multando API clients (async and sync)."""

from __future__ import annotations

from typing import Optional

from ._http import HttpClient, SyncHttpClient
from .auth import AuthService, SyncAuthService
from .infractions import InfractionsService, SyncInfractionsService
from .models import TokenResponse
from .reports import ReportsService, SyncReportsService
from .wallet import WalletService, SyncWalletService


class MultandoClient:
    """Async client for the Multando API.

    Usage::

        async with MultandoClient(api_key="mult_live_xxx") as client:
            await client.login("user@example.com", "password")
            infractions = await client.infractions.list()
    """

    def __init__(
        self,
        base_url: str = "https://api.multando.com",
        api_key: Optional[str] = None,
        access_token: Optional[str] = None,
        timeout: float = 30.0,
    ) -> None:
        self._http = HttpClient(
            base_url=f"{base_url.rstrip('/')}/api/v1",
            api_key=api_key,
            access_token=access_token,
            timeout=timeout,
        )
        self.auth = AuthService(self._http)
        self.reports = ReportsService(self._http)
        self.infractions = InfractionsService(self._http)
        self.wallet = WalletService(self._http)

    async def login(self, email: str, password: str) -> TokenResponse:
        """Authenticate and store the access token for subsequent requests."""
        token = await self.auth.login(email, password)
        self._http.set_access_token(token.access_token)
        return token

    # Context-manager support -------------------------------------------

    async def __aenter__(self) -> "MultandoClient":
        return self

    async def __aexit__(self, *exc: object) -> None:
        await self._http.aclose()

    async def close(self) -> None:
        await self._http.aclose()


class MultandoSyncClient:
    """Synchronous client for the Multando API.

    Usage::

        client = MultandoSyncClient(api_key="mult_live_xxx")
        client.login("user@example.com", "password")
        reports = client.reports.list()
    """

    def __init__(
        self,
        base_url: str = "https://api.multando.com",
        api_key: Optional[str] = None,
        access_token: Optional[str] = None,
        timeout: float = 30.0,
    ) -> None:
        self._http = SyncHttpClient(
            base_url=f"{base_url.rstrip('/')}/api/v1",
            api_key=api_key,
            access_token=access_token,
            timeout=timeout,
        )
        self.auth = SyncAuthService(self._http)
        self.reports = SyncReportsService(self._http)
        self.infractions = SyncInfractionsService(self._http)
        self.wallet = SyncWalletService(self._http)

    def login(self, email: str, password: str) -> TokenResponse:
        """Authenticate and store the access token for subsequent requests."""
        token = self.auth.login(email, password)
        self._http.set_access_token(token.access_token)
        return token

    # Context-manager support -------------------------------------------

    def __enter__(self) -> "MultandoSyncClient":
        return self

    def __exit__(self, *exc: object) -> None:
        self._http.close()

    def close(self) -> None:
        self._http.close()
