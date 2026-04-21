"""Reports service."""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, TYPE_CHECKING

from .models import Report, ReportList

if TYPE_CHECKING:
    from ._http import HttpClient, SyncHttpClient


class ReportsService:
    """Async report operations."""

    def __init__(self, http: "HttpClient") -> None:
        self._http = http

    async def create(
        self,
        infraction_id: int,
        plate_number: str,
        latitude: float,
        longitude: float,
        description: str = "",
        vehicle_type_id: Optional[int] = None,
        vehicle_category: str = "private",
        source: str = "web",
        incident_datetime: Optional[str] = None,
    ) -> Report:
        payload: Dict[str, Any] = {
            "infraction_id": infraction_id,
            "vehicle_plate": plate_number,
            "location": {"lat": latitude, "lon": longitude},
            "vehicle_category": vehicle_category,
            "source": source,
            "incident_datetime": incident_datetime or datetime.now(timezone.utc).isoformat(),
        }
        if vehicle_type_id is not None:
            payload["vehicle_type_id"] = vehicle_type_id
        # description is not a top-level field in ReportCreate but kept for
        # forward-compatibility; the API will ignore unknown fields.
        if description:
            payload["description"] = description
        data = await self._http.post("/reports", json=payload)
        return Report.from_dict(data)

    async def list(
        self,
        page: int = 1,
        page_size: int = 20,
        status: Optional[str] = None,
    ) -> ReportList:
        params: Dict[str, Any] = {"page": page, "page_size": page_size}
        if status is not None:
            params["status"] = status
        data = await self._http.get("/reports", params=params)
        return ReportList.from_dict(data)

    async def get(self, report_id: str) -> Report:
        """Fetch a single report by UUID or short_id (e.g. RPT-A1B2C3)."""
        data = await self._http.get(f"/reports/{report_id}")
        return Report.from_dict(data)

    async def get_by_plate(self, plate: str) -> List[Report]:
        data = await self._http.get(f"/reports/by-plate/{plate}")
        if isinstance(data, list):
            return [Report.from_dict(r) for r in data]
        return [Report.from_dict(r) for r in data.get("items", data.get("results", []))]

    async def delete(self, report_id: str) -> bool:
        await self._http.delete(f"/reports/{report_id}")
        return True


class SyncReportsService:
    """Synchronous report operations."""

    def __init__(self, http: "SyncHttpClient") -> None:
        self._http = http

    def create(
        self,
        infraction_id: int,
        plate_number: str,
        latitude: float,
        longitude: float,
        description: str = "",
        vehicle_type_id: Optional[int] = None,
        vehicle_category: str = "private",
        source: str = "web",
        incident_datetime: Optional[str] = None,
    ) -> Report:
        payload: Dict[str, Any] = {
            "infraction_id": infraction_id,
            "vehicle_plate": plate_number,
            "location": {"lat": latitude, "lon": longitude},
            "vehicle_category": vehicle_category,
            "source": source,
            "incident_datetime": incident_datetime or datetime.now(timezone.utc).isoformat(),
        }
        if vehicle_type_id is not None:
            payload["vehicle_type_id"] = vehicle_type_id
        if description:
            payload["description"] = description
        data = self._http.post("/reports", json=payload)
        return Report.from_dict(data)

    def list(
        self,
        page: int = 1,
        page_size: int = 20,
        status: Optional[str] = None,
    ) -> ReportList:
        params: Dict[str, Any] = {"page": page, "page_size": page_size}
        if status is not None:
            params["status"] = status
        data = self._http.get("/reports", params=params)
        return ReportList.from_dict(data)

    def get(self, report_id: str) -> Report:
        data = self._http.get(f"/reports/{report_id}")
        return Report.from_dict(data)

    def get_by_plate(self, plate: str) -> List[Report]:
        data = self._http.get(f"/reports/by-plate/{plate}")
        if isinstance(data, list):
            return [Report.from_dict(r) for r in data]
        return [Report.from_dict(r) for r in data.get("items", data.get("results", []))]

    def delete(self, report_id: str) -> bool:
        self._http.delete(f"/reports/{report_id}")
        return True
