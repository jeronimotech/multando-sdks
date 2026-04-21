"""Wallet service."""

from __future__ import annotations

from typing import Any, Dict, TYPE_CHECKING

from .models import ActivityList, WalletBalance

if TYPE_CHECKING:
    from ._http import HttpClient, SyncHttpClient


class WalletService:
    """Async wallet operations."""

    def __init__(self, http: "HttpClient") -> None:
        self._http = http

    async def balance(self) -> WalletBalance:
        data = await self._http.get("/wallet/info")
        return WalletBalance.from_dict(data)

    async def activities(self, page: int = 1) -> ActivityList:
        params: Dict[str, Any] = {"page": page}
        data = await self._http.get("/wallet/withdrawals", params=params)
        return ActivityList.from_dict(data)


class SyncWalletService:
    """Synchronous wallet operations."""

    def __init__(self, http: "SyncHttpClient") -> None:
        self._http = http

    def balance(self) -> WalletBalance:
        data = self._http.get("/wallet/info")
        return WalletBalance.from_dict(data)

    def activities(self, page: int = 1) -> ActivityList:
        params: Dict[str, Any] = {"page": page}
        data = self._http.get("/wallet/withdrawals", params=params)
        return ActivityList.from_dict(data)
