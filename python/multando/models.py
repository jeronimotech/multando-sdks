"""Multando API response models.

Lightweight dataclasses -- no Pydantic dependency required.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, List, Optional


def _parse_dt(value: Any) -> Optional[datetime]:
    if value is None:
        return None
    if isinstance(value, datetime):
        return value
    return datetime.fromisoformat(value)


# ------------------------------------------------------------------
# Auth
# ------------------------------------------------------------------

@dataclass
class TokenResponse:
    access_token: str
    refresh_token: str
    token_type: str
    expires_in: int

    @classmethod
    def from_dict(cls, data: dict) -> "TokenResponse":
        return cls(
            access_token=data["access_token"],
            refresh_token=data["refresh_token"],
            token_type=data.get("token_type", "bearer"),
            expires_in=data["expires_in"],
        )


# ------------------------------------------------------------------
# User
# ------------------------------------------------------------------

@dataclass
class User:
    id: str
    email: str
    username: str
    display_name: str
    avatar_url: Optional[str] = None
    is_verified: bool = False
    role: str = "user"
    points: int = 0
    reputation_score: float = 0.0
    wallet_address: Optional[str] = None
    phone_number: Optional[str] = None
    created_at: Optional[datetime] = None

    @classmethod
    def from_dict(cls, data: dict) -> "User":
        return cls(
            id=str(data["id"]),
            email=data.get("email", ""),
            username=data.get("username", ""),
            display_name=data.get("display_name", ""),
            avatar_url=data.get("avatar_url"),
            is_verified=data.get("is_verified", False),
            role=data.get("role", "user"),
            points=data.get("points", 0),
            reputation_score=float(data.get("reputation_score", 0)),
            wallet_address=data.get("wallet_address"),
            phone_number=data.get("phone_number"),
            created_at=_parse_dt(data.get("created_at")),
        )


# ------------------------------------------------------------------
# Infractions
# ------------------------------------------------------------------

@dataclass
class Infraction:
    id: int
    code: str
    name_en: str
    name_es: str
    description_en: str
    description_es: str
    category: str
    severity: str
    points_reward: int = 0
    multa_reward: float = 0.0
    icon: Optional[str] = None

    @classmethod
    def from_dict(cls, data: dict) -> "Infraction":
        return cls(
            id=data["id"],
            code=data["code"],
            name_en=data.get("name_en", ""),
            name_es=data.get("name_es", ""),
            description_en=data.get("description_en", ""),
            description_es=data.get("description_es", ""),
            category=data.get("category", ""),
            severity=data.get("severity", ""),
            points_reward=data.get("points_reward", 0),
            multa_reward=float(data.get("multa_reward", 0)),
            icon=data.get("icon"),
        )


# ------------------------------------------------------------------
# Reports
# ------------------------------------------------------------------

@dataclass
class Location:
    lat: float
    lon: float
    address: Optional[str] = None
    city: Optional[str] = None
    country: Optional[str] = None

    @classmethod
    def from_dict(cls, data: dict) -> "Location":
        return cls(
            lat=data["lat"],
            lon=data["lon"],
            address=data.get("address"),
            city=data.get("city"),
            country=data.get("country"),
        )


@dataclass
class Report:
    id: str
    short_id: str
    status: str
    vehicle_plate: Optional[str] = None
    infraction_id: Optional[int] = None
    infraction: Optional[Infraction] = None
    location: Optional[Location] = None
    description: str = ""
    source: str = ""
    vehicle_category: str = "private"
    on_chain: bool = False
    tx_signature: Optional[str] = None
    confidence_score: int = 50
    verification_count: int = 0
    rejection_count: int = 0
    rejection_reason: Optional[str] = None
    created_at: Optional[datetime] = None
    verified_at: Optional[datetime] = None
    incident_datetime: Optional[datetime] = None

    @classmethod
    def from_dict(cls, data: dict) -> "Report":
        infraction_data = data.get("infraction")
        location_data = data.get("location")
        return cls(
            id=str(data["id"]),
            short_id=data.get("short_id", ""),
            status=data.get("status", ""),
            vehicle_plate=data.get("vehicle_plate"),
            infraction_id=infraction_data.get("id") if infraction_data else data.get("infraction_id"),
            infraction=Infraction.from_dict(infraction_data) if infraction_data else None,
            location=Location.from_dict(location_data) if location_data else None,
            description=data.get("description", ""),
            source=data.get("source", ""),
            vehicle_category=data.get("vehicle_category", "private"),
            on_chain=data.get("on_chain", False),
            tx_signature=data.get("tx_signature"),
            confidence_score=data.get("confidence_score", 50),
            verification_count=data.get("verification_count", 0),
            rejection_count=data.get("rejection_count", 0),
            rejection_reason=data.get("rejection_reason"),
            created_at=_parse_dt(data.get("created_at")),
            verified_at=_parse_dt(data.get("verified_at")),
            incident_datetime=_parse_dt(data.get("incident_datetime")),
        )


@dataclass
class ReportList:
    items: List[Report]
    total: int
    page: int
    page_size: int

    @classmethod
    def from_dict(cls, data: dict) -> "ReportList":
        return cls(
            items=[Report.from_dict(r) for r in data.get("items", [])],
            total=data.get("total", 0),
            page=data.get("page", 1),
            page_size=data.get("page_size", 20),
        )


# ------------------------------------------------------------------
# Wallet
# ------------------------------------------------------------------

@dataclass
class WalletBalance:
    wallet_type: str = "custodial"
    public_key: Optional[str] = None
    status: str = "active"
    balance: float = 0.0
    staked_balance: float = 0.0
    pending_rewards: float = 0.0
    total_earned: float = 0.0
    can_withdraw: bool = False

    @classmethod
    def from_dict(cls, data: dict) -> "WalletBalance":
        return cls(
            wallet_type=data.get("wallet_type", "custodial"),
            public_key=data.get("public_key"),
            status=data.get("status", "active"),
            balance=float(data.get("balance", 0)),
            staked_balance=float(data.get("staked_balance", 0)),
            pending_rewards=float(data.get("pending_rewards", 0)),
            total_earned=float(data.get("total_earned", 0)),
            can_withdraw=data.get("can_withdraw", False),
        )


@dataclass
class Activity:
    id: str
    type: str
    points_earned: int = 0
    multa_earned: float = 0.0
    created_at: Optional[datetime] = None

    @classmethod
    def from_dict(cls, data: dict) -> "Activity":
        return cls(
            id=str(data["id"]),
            type=data.get("type", ""),
            points_earned=data.get("points_earned", 0),
            multa_earned=float(data.get("multa_earned", 0)),
            created_at=_parse_dt(data.get("created_at")),
        )


@dataclass
class ActivityList:
    items: List[Activity]
    total: int
    page: int
    page_size: int

    @classmethod
    def from_dict(cls, data: dict) -> "ActivityList":
        return cls(
            items=[Activity.from_dict(a) for a in data.get("items", [])],
            total=data.get("total", 0),
            page=data.get("page", 1),
            page_size=data.get("page_size", 20),
        )
