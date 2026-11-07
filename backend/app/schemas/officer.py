from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


ComplaintStatus = Literal["Pending", "Assigned", "In Progress", "Resolved", "Closed", "Reopened", "Escalated", "Rejected"]


class AssignmentRequest(BaseModel):
    assigned_department: str = Field(min_length=2, max_length=150)
    assigned_officer_id: int | None = Field(default=None, gt=0)
    expected_resolution_date: datetime | None = None


class StatusUpdateRequest(BaseModel):
    status: ComplaintStatus
    action_notes: str | None = Field(default=None, max_length=5000)
    repair_evidence_url: str | None = Field(default=None, max_length=1000)
    completion_date: datetime | None = None


class WorkOrderActionRequest(BaseModel):
    action: Literal["accept", "reject", "reassign"]
    reason: str = Field(min_length=2, max_length=1000)
    reassigned_department: str | None = Field(default=None, max_length=150)
    reassigned_officer_id: int | None = Field(default=None, gt=0)


class AIOverrideRequest(BaseModel):
    corrected_category: str | None = Field(default=None, max_length=100)
    corrected_severity: str | None = Field(default=None, max_length=50)
    override_reason: str = Field(min_length=2, max_length=1000)


class VillageAsset(BaseModel):
    asset_id: str
    domain: str
    name: str
    location: str
    condition_index: int
    status: str
    active_complaints_count: int = 0
    last_inspected: str
    maintenance_notes: str


class ComplaintSummary(BaseModel):
    id: int
    title: str
    text: str
    village: str | None
    district: str | None = None
    taluka: str | None = None
    status: str
    created_at: datetime | None
    category: str | None
    severity: str | None
    priority_level: str | None
    priority_score: float | None
    assigned_department: str | None
    location: str | None = None
    has_coordinates: bool = False
    is_overdue: bool = False


class ComplaintDetail(ComplaintSummary):
    model_config = ConfigDict(from_attributes=True)

    language: str
    lane: str | None
    lane_number: str | None
    exact_location: str | None
    area: str | None
    latitude: float | None
    longitude: float | None
    is_valid_coordinate: bool = False
    evidence_url: str | None
    affected_people: int
    repeated_complaints: int
    assigned_officer_id: int | None
    assigned_officer_name: str | None
    assigned_at: datetime | None
    expected_resolution_date: datetime | None
    action_notes: str | None
    repair_evidence_url: str | None
    completion_date: datetime | None
    ai_confidence: float | None
    duplicate_possible: bool | None
    matching_complaint_id: int | None
    similarity_score: float | None
    recommended_department: str | None
    severity_explanation: str | None
    priority_explanation: str | None


class OfficerOption(BaseModel):
    id: int
    full_name: str
    village: str | None


class VillageOption(BaseModel):
    id: int
    name: str
    district: str
    taluka: str | None = None


class DirectoryVillageCreateRequest(BaseModel):
    name: str
    district: str
    taluka: str
    latitude: float | None = None
    longitude: float | None = None
    boundary_radius_km: float = 3.0
    state: str = "Maharashtra"


class DashboardResponse(BaseModel):
    total_complaints: int
    pending_complaints: int
    in_progress_complaints: int
    resolved_complaints: int
    overdue_complaints: int = 0
    critical_complaints: int
    high_priority_complaints: int
    complaints_by_category: dict[str, int]


class InsightResponse(BaseModel):
    status_counts: dict[str, int] = {}
    category_counts: dict[str, int] = {}
    severity_counts: dict[str, int] = {}
    priority_counts: dict[str, int] = {}
    complaints_over_time: list[dict[str, str | int]] = []
    resolution_rate: dict[str, float | int | str] = {}
    overdue_complaints: list[dict[str, int | str | bool | None]] = []
    repeated_complaints: list[dict[str, int | str | None]] = []
    department_workload: dict[str, int] = {}
    ai_insights: list[dict[str, int | str | float | None]] = []


class DigitalTwinResponse(BaseModel):
    village: dict[str, int | float | str | None]
    resources: list[dict[str, int | str]]
    assets: list[VillageAsset] = []
    map_points: list[dict[str, int | float | str | bool | None]]
    boundary_alerts: list[dict[str, int | float | str | bool | None]] = []
    map_message: str | None = None



class AreaBubblePoint(BaseModel):
    area_name: str
    complaint_count: int
    avg_priority_score: float
    total_affected_or_repeated: int
    avg_severity_score: float
    dominant_category: str


class CategoryBubblePoint(BaseModel):
    category: str
    total_count: int
    unresolved_count: int
    avg_severity_score: float
    avg_priority_score: float = 0.0


class ResolutionAnalytics(BaseModel):
    average_hours: float | None = None
    min_hours: float | None = None
    max_hours: float | None = None
    resolved_count: int = 0
    histogram_bins: dict[str, int] = {}
    by_category: dict[str, float] = {}
    by_department: dict[str, float] = {}


class FrequentIssueItem(BaseModel):
    location: str
    category: str
    count: int
    unresolved_count: int


class HeatmapPoint(BaseModel):
    complaint_id: int
    latitude: float
    longitude: float
    weight: float
    category: str | None = None
    severity: str | None = None


class AdvancedAnalyticsResponse(BaseModel):
    kpi_summary: dict[str, int | float]
    category_distribution: dict[str, int]
    status_distribution: dict[str, int]
    trend_timeline: list[dict[str, str | int]]
    area_bubble_metrics: list[AreaBubblePoint] = []
    category_bubble_metrics: list[CategoryBubblePoint] = []
    resolution_analytics: ResolutionAnalytics
    frequent_problems: list[FrequentIssueItem] = []
    heatmap_points: list[HeatmapPoint] = []
    department_workload: dict[str, int] = {}
    available_areas: list[str] = []
    available_categories: list[str] = []
    available_departments: list[str] = []
