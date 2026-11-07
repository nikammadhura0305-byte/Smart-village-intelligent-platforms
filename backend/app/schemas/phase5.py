from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class VerificationRequest(BaseModel):
    solved: bool
    reason: str | None = Field(default=None, max_length=2000)


class ComplaintCreateRequest(BaseModel):
    complaint_text: str = Field(min_length=5, max_length=5000)
    language: str = Field(default="english", min_length=2, max_length=30)
    affected_people: int = Field(default=1, ge=1, le=1_000_000)
    location_importance: int = Field(default=0, ge=0, le=10)
    lane: str | None = Field(default=None, max_length=250)
    lane_number: str | None = Field(default=None, max_length=100)
    exact_location: str | None = Field(default=None, max_length=1000)
    area: str | None = Field(default=None, max_length=250)
    latitude: float | None = Field(default=None, ge=-90, le=90)
    longitude: float | None = Field(default=None, ge=-180, le=180)
    evidence_url: str | None = Field(default=None, max_length=1000)
    evidence_media_type: str | None = None
    evidence_size_bytes: int | None = Field(default=None, ge=1)


class ComplaintCreateResponse(BaseModel):
    complaint_id: int
    status: str
    analysis_id: int


class CitizenComplaintResponse(BaseModel):
    complaint_id: int
    complaint_text: str
    status: str
    language: str
    created_at: datetime | None
    category: str | None
    severity: str | None
    priority_level: str | None
    priority_score: float | None
    lane: str | None
    lane_number: str | None
    exact_location: str | None
    area: str | None


class VerificationResponse(BaseModel):
    id: int
    complaint_id: int
    response: Literal["yes", "no"] | None
    reason: str | None
    responded_at: datetime | None


class NotificationResponse(BaseModel):
    id: int
    complaint_id: int | None
    notification_type: str
    channel: str
    status: str
    message: str
    created_at: datetime | None


class EscalationRunResponse(BaseModel):
    escalated_count: int
    threshold_hours: int


class AnalyticsResponse(BaseModel):
    complaint_trends: list[dict[str, int | str]]
    category_trends: list[dict[str, int | str]]
    department_workload: dict[str, int]
    repeated_issue_areas: list[dict[str, int | str | None]]
    resolution_time: dict[str, float | int | None]
    pending_complaints: int
    severity_trends: dict[str, int]
    heat_map: list[dict[str, int | float | str | None]]


class PredictionResponse(BaseModel):
    status: Literal["insufficient_data", "baseline_available"]
    message: str
    required_samples: int
    sample_count: int
    predictions: list[dict[str, int | str | float | None]]


class ReportResponse(BaseModel):
    generated_at: datetime
    summary: dict[str, int | float]
    complaints_by_category: dict[str, int]
    complaints_by_month: dict[str, int]
    department_performance: list[dict[str, int | float | str | None]]
    critical_issues: list[dict[str, int | str | None]]
    village_issue_summary: list[dict[str, int | str | None]]
