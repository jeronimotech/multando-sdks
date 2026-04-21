"""Infractions service."""

from __future__ import annotations

from typing import List, TYPE_CHECKING

from .models import Infraction

if TYPE_CHECKING:
    from ._http import HttpClient, SyncHttpClient


class InfractionsService:
    """Async infraction operations."""

    def __init__(self, http: "HttpClient") -> None:
        self._http = http

    async def list(self) -> List[Infraction]:
        data = await self._http.get("/infractions")
        items = data.get("items", data) if isinstance(data, dict) else data
        return [Infraction.from_dict(i) for i in items]

    async def get(self, infraction_id: int) -> Infraction:
        data = await self._http.get(f"/infractions/{infraction_id}")
        return Infraction.from_dict(data)


class SyncInfractionsService:
    """Synchronous infraction operations."""

    def __init__(self, http: "SyncHttpClient") -> None:
        self._http = http

    def list(self) -> List[Infraction]:
        data = self._http.get("/infractions")
        items = data.get("items", data) if isinstance(data, dict) else data
        return [Infraction.from_dict(i) for i in items]

    def get(self, infraction_id: int) -> Infraction:
        data = self._http.get(f"/infractions/{infraction_id}")
        return Infraction.from_dict(data)
