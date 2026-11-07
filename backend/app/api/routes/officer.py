import mimetypes
from pathlib import Path

UPLOAD_DIR = Path(__file__).resolve().parents[3] / "uploads" / "evidence"

import csv
import io
import math
from collections import Counter, defaultdict
from datetime import UTC, datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.responses import FileResponse, Response
from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from app.ai.departments import CATEGORY_DEPARTMENTS
from app.core.dependencies import require_officer
from app.db.session import get_db
from app.models import AIAnalysis, Complaint, User, Village
from app.services.notifications import NotificationEvent, NotificationService
from app.services.verification import VerificationService
from app.services.village_scope import selected_village_ids
from app.schemas.officer import (
    AdvancedAnalyticsResponse,
    AIOverrideRequest,
    AreaBubblePoint,
    AssignmentRequest,
    CategoryBubblePoint,
    ComplaintDetail,
    ComplaintStatus,
    ComplaintSummary,
    DashboardResponse,
    DigitalTwinResponse,
    FrequentIssueItem,
    HeatmapPoint,
    InsightResponse,
    OfficerOption,
    ResolutionAnalytics,
    StatusUpdateRequest,
    VillageAsset,
    VillageOption,
    DirectoryVillageCreateRequest,
    WorkOrderActionRequest,
)

router = APIRouter(prefix="/officer", tags=["officer"], dependencies=[Depends(require_officer)])
notification_service = NotificationService()
verification_service = VerificationService(notification_service)


def latest_analysis(db: Session, complaint_id: int) -> AIAnalysis | None:
    return db.scalar(
        select(AIAnalysis)
        .where(AIAnalysis.complaint_id == complaint_id)
        .order_by(desc(AIAnalysis.analysis_timestamp))
        .limit(1)
    )


def as_utc(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)


def complaint_rows(
    db: Session,
    current_user: User,
    village_id: int | None = None,
    district: str | None = None,
    all_villages: bool = False,
    taluka: str | None = None,
) -> list[tuple[Complaint, AIAnalysis | None]]:
    village_ids = selected_village_ids(
        db, current_user, village_id, district, all_villages, taluka
    )
    query = select(Complaint)
    if village_ids is not None:
        if not village_ids:
            return []
        query = query.where(Complaint.village_id.in_(village_ids))

    complaints = db.scalars(
        query.order_by(
            desc(Complaint.created_at),
            desc(Complaint.id),
        )
    ).all()

    return [
        (complaint, latest_analysis(db, complaint.id))
        for complaint in complaints
    ]


def get_complaint_in_scope(
    db: Session,
    current_user: User,
    complaint_id: int,
    village_id: int | None = None,
    district: str | None = None,
    all_villages: bool = False,
    taluka: str | None = None,
) -> Complaint:
    complaint = db.get(Complaint, complaint_id)
    if complaint is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Complaint not found",
        )

    if current_user.role == "admin":
        if village_id is not None or district is not None or taluka is not None or all_villages:
            allowed_village_ids = selected_village_ids(
                db,
                current_user,
                village_id,
                district,
                all_villages,
                taluka,
            )
            if allowed_village_ids is not None and complaint.village_id not in allowed_village_ids:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Complaint not found in selected scope",
                )
        return complaint

    # Strict village officer boundary lockdown (Phase 5)
    if current_user.village_id is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: You have no assigned village",
        )

    if complaint.village_id is not None and complaint.village_id != current_user.village_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: You are not authorized to access complaints outside your assigned village",
        )

    # Validate query parameters against officer's scope
    selected_village_ids(
        db,
        current_user,
        village_id,
        district,
        all_villages,
        taluka,
    )

    return complaint


def normalize_filter(value: str | None) -> str | None:
    if value is None:
        return None
    normalized = value.strip()
    return normalized.lower() if normalized else None


def search_matches(complaint: Complaint, analysis: AIAnalysis | None, query: str) -> bool:
    searchable_values = [
        complaint.text,
        complaint.exact_location,
        complaint.area,
        complaint.lane,
        complaint.lane_number,
        complaint.status,
        complaint.assigned_department,
        complaint.village.name if complaint.village else None,
        analysis.category if analysis and analysis.category else None,
        analysis.recommended_department if analysis and analysis.recommended_department else None,
    ]
    haystack = " ".join(
        str(value) for value in searchable_values if value is not None and str(value).strip()
    ).lower()
    return query in haystack


def is_valid_coordinate(latitude: float | int | str | None, longitude: float | int | str | None) -> bool:
    try:
        lat = float(latitude)
        lon = float(longitude)
    except (TypeError, ValueError):
        return False

    return math.isfinite(lat) and math.isfinite(lon) and -90 <= lat <= 90 and -180 <= lon <= 180


def haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    rlat1 = math.radians(lat1)
    rlat2 = math.radians(lat2)
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(rlat1) * math.cos(rlat2) * math.sin(dlon / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return 6371.0 * c


def complaint_boundary_status(
    complaint: Complaint,
    village: Village | None = None,
) -> dict[str, float | bool | None]:
    village_obj = complaint.village if complaint.village is not None else village
    if village_obj is None:
        return {
            "distance_from_village_km": None,
            "boundary_radius_km": None,
            "is_valid_coordinate": is_valid_coordinate(complaint.latitude, complaint.longitude),
            "is_outside_boundary": False,
        }

    valid = is_valid_coordinate(complaint.latitude, complaint.longitude)
    if not valid or village_obj.latitude is None or village_obj.longitude is None:
        return {
            "distance_from_village_km": None,
            "boundary_radius_km": village_obj.boundary_radius_km if hasattr(village_obj, "boundary_radius_km") else None,
            "is_valid_coordinate": valid,
            "is_outside_boundary": False,
        }

    distance_km = haversine_km(
        float(complaint.latitude),
        float(complaint.longitude),
        float(village_obj.latitude),
        float(village_obj.longitude),
    )
    radius_km = float(village_obj.boundary_radius_km) if village_obj.boundary_radius_km is not None else None
    is_outside_boundary = radius_km is not None and distance_km > radius_km

    return {
        "distance_from_village_km": round(distance_km, 2),
        "boundary_radius_km": round(radius_km, 2) if radius_km is not None else None,
        "is_valid_coordinate": True,
        "is_outside_boundary": is_outside_boundary,
    }


def is_complaint_overdue(complaint: Complaint) -> bool:
    if complaint.status not in {"Pending", "Assigned", "In Progress", "Reopened"}:
        return False

    expected_resolution_date = complaint.expected_resolution_date
    if expected_resolution_date is None:
        return False

    if expected_resolution_date.tzinfo is None:
        expected_resolution_date = expected_resolution_date.replace(tzinfo=UTC)

    return expected_resolution_date < datetime.now(UTC)


def summary(complaint: Complaint, analysis: AIAnalysis | None) -> ComplaintSummary:
    complaint_title = complaint.text.strip()[:80] if complaint.text else "Complaint"
    location_parts = [
        part
        for part in [
            complaint.lane,
            complaint.lane_number,
            complaint.exact_location,
            complaint.area,
        ]
        if part
    ]

    has_coords = is_valid_coordinate(complaint.latitude, complaint.longitude)
    district_name = complaint.village.district if complaint.village else None
    taluka_name = getattr(complaint.village, "taluka", None) if complaint.village else None

    return ComplaintSummary(
        id=complaint.id,
        title=complaint_title,
        text=complaint.text,
        village=complaint.village.name if complaint.village else None,
        district=district_name,
        taluka=taluka_name,
        status=complaint.status,
        created_at=complaint.created_at,
        category=analysis.category if analysis else None,
        severity=analysis.severity if analysis else None,
        priority_level=analysis.priority_level if analysis else None,
        priority_score=analysis.priority_score if analysis else None,
        assigned_department=complaint.assigned_department,
        location=" · ".join(location_parts) if location_parts else None,
        has_coordinates=has_coords,
        is_overdue=is_complaint_overdue(complaint),
    )


def detail(complaint: Complaint, analysis: AIAnalysis | None) -> ComplaintDetail:
    summary_data = summary(complaint, analysis)
    valid_coords = is_valid_coordinate(complaint.latitude, complaint.longitude)
    return ComplaintDetail(
        **summary_data.model_dump(),
        language=complaint.language,
        lane=complaint.lane,
        lane_number=complaint.lane_number,
        exact_location=complaint.exact_location,
        area=complaint.area,
        latitude=complaint.latitude,
        longitude=complaint.longitude,
        is_valid_coordinate=valid_coords,
        evidence_url=complaint.evidence_url,
        affected_people=complaint.affected_people,
        repeated_complaints=complaint.repeated_complaints,
        assigned_officer_id=complaint.assigned_officer_id,
        assigned_officer_name=complaint.assigned_officer.full_name if complaint.assigned_officer else None,
        assigned_at=as_utc(complaint.assigned_at),
        expected_resolution_date=as_utc(complaint.expected_resolution_date),
        action_notes=complaint.action_notes,
        repair_evidence_url=complaint.repair_evidence_url,
        completion_date=as_utc(complaint.completion_date),
        ai_confidence=analysis.confidence if analysis else None,
        duplicate_possible=analysis.possible_duplicate if analysis else None,
        matching_complaint_id=analysis.matching_complaint_id if analysis else None,
        similarity_score=analysis.similarity_score if analysis else None,
        recommended_department=analysis.recommended_department if analysis else None,
        severity_explanation=analysis.severity_explanation if analysis else None,
        priority_explanation=analysis.priority_explanation if analysis else None,
    )


@router.get("/dashboard", response_model=DashboardResponse)
def dashboard(
    village_id: int | None = Query(default=None, gt=0),
    district: str | None = Query(default=None, min_length=1),
    taluka: str | None = Query(default=None, min_length=1),
    all_villages: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_officer),
) -> DashboardResponse:
    rows = complaint_rows(db, current_user, village_id, district, all_villages, taluka)

    category_counts = Counter(analysis.category for _, analysis in rows if analysis)
    pending = sum(complaint.status == "Pending" for complaint, _ in rows)
    in_progress = sum(complaint.status == "In Progress" for complaint, _ in rows)
    resolved = sum(complaint.status == "Resolved" for complaint, _ in rows)
    critical = sum(analysis.severity == "Critical" for _, analysis in rows if analysis)
    high_priority = sum(analysis.priority_level == "High" for _, analysis in rows if analysis)
    overdue = sum(is_complaint_overdue(complaint) for complaint, _ in rows)

    return DashboardResponse(
        total_complaints=len(rows),
        pending_complaints=pending,
        in_progress_complaints=in_progress,
        resolved_complaints=resolved,
        overdue_complaints=overdue,
        critical_complaints=critical,
        high_priority_complaints=high_priority,
        complaints_by_category=dict(sorted(category_counts.items())),
    )


@router.get("/officers", response_model=list[OfficerOption])
def list_officers(
    village_id: int | None = Query(default=None, gt=0),
    district: str | None = Query(default=None, min_length=1),
    taluka: str | None = Query(default=None, min_length=1),
    all_villages: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_officer),
) -> list[OfficerOption]:
    village_ids = selected_village_ids(
        db, current_user, village_id, district, all_villages, taluka
    )
    query = select(User).where(
        User.role.in_({"village_officer", "admin"}),
        User.is_active.is_(True),
    )
    if village_ids is not None:
        if not village_ids:
            return []
        query = query.where(User.village_id.in_(village_ids))

    officers = db.scalars(query.order_by(User.full_name, User.id)).all()
    return [
        OfficerOption(
            id=officer.id,
            full_name=officer.full_name,
            village=officer.village.name if officer.village else None,
        )
        for officer in officers
    ]


@router.get("/districts", response_model=list[str])
def list_officer_districts(
    db: Session = Depends(get_db),
    _: User = Depends(require_officer),
) -> list[str]:
    from app.services.directory import list_directory_districts
    return list_directory_districts(db)


@router.get("/talukas", response_model=list[str])
def list_officer_talukas(
    district: str = Query(min_length=1),
    db: Session = Depends(get_db),
    _: User = Depends(require_officer),
) -> list[str]:
    from app.services.directory import list_directory_talukas
    return list_directory_talukas(db, district)


@router.get("/villages", response_model=list[VillageOption])
def list_villages(
    district: str | None = Query(default=None),
    taluka: str | None = Query(default=None),
    db: Session = Depends(get_db),
    _: User = Depends(require_officer),
) -> list[VillageOption]:
    from app.services.directory import list_directory_villages
    villages = list_directory_villages(db, district=district, taluka=taluka)
    return [
        VillageOption(
            id=village.id,
            name=village.name,
            district=village.district,
            taluka=village.taluka,
        )
        for village in villages
    ]


@router.post("/directory/villages", response_model=VillageOption, status_code=status.HTTP_201_CREATED)
def create_directory_village(
    payload: DirectoryVillageCreateRequest,
    current_user: User = Depends(require_officer),
    db: Session = Depends(get_db),
) -> VillageOption:
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only administrators can add administrative directory records.",
        )
    from app.services.directory import add_directory_village
    v = add_directory_village(
        db,
        name=payload.name,
        district=payload.district,
        taluka=payload.taluka,
        latitude=payload.latitude,
        longitude=payload.longitude,
        boundary_radius_km=payload.boundary_radius_km,
        state=payload.state,
    )
    return VillageOption(id=v.id, name=v.name, district=v.district, taluka=v.taluka)


@router.post("/directory/seed", status_code=status.HTTP_200_OK)
def seed_directory_endpoint(
    current_user: User = Depends(require_officer),
    db: Session = Depends(get_db),
) -> dict:
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only administrators can trigger directory seeding.",
        )
    from app.services.directory import seed_maharashtra_directory
    return seed_maharashtra_directory(db)


@router.get("/complaints", response_model=list[ComplaintSummary])
def list_complaints(
    category: str | None = Query(default=None),
    severity: str | None = Query(default=None),
    priority: str | None = Query(default=None),
    complaint_status: ComplaintStatus | None = Query(default=None, alias="status"),
    department: str | None = Query(default=None),
    start_date: str | None = Query(default=None),
    end_date: str | None = Query(default=None),
    search: str | None = Query(default=None, min_length=1),
    village_id: int | None = Query(default=None, gt=0),
    district: str | None = Query(default=None, min_length=1),
    taluka: str | None = Query(default=None, min_length=1),
    all_villages: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_officer),
) -> list[ComplaintSummary]:
    rows = complaint_rows(db, current_user, village_id, district, all_villages, taluka)
    category_value = normalize_filter(category)
    severity_value = normalize_filter(severity)
    priority_value = normalize_filter(priority)
    complaint_status_value = normalize_filter(str(complaint_status) if complaint_status else None)
    department_value = normalize_filter(department)
    search_value = normalize_filter(search)

    s_dt = None
    if start_date:
        try:
            s_dt = datetime.strptime(start_date, "%Y-%m-%d").date()
        except ValueError:
            pass

    e_dt = None
    if end_date:
        try:
            e_dt = datetime.strptime(end_date, "%Y-%m-%d").date()
        except ValueError:
            pass

    filtered: list[ComplaintSummary] = []

    for complaint, analysis in rows:
        if category_value and (analysis is None or normalize_filter(analysis.category) != category_value):
            continue
        if severity_value and (analysis is None or normalize_filter(analysis.severity) != severity_value):
            continue
        if priority_value and (analysis is None or normalize_filter(analysis.priority_level) != priority_value):
            continue
        if complaint_status_value and normalize_filter(complaint.status) != complaint_status_value:
            continue
        if department_value and normalize_filter(complaint.assigned_department) != department_value:
            continue
        if s_dt and complaint.created_at and complaint.created_at.date() < s_dt:
            continue
        if e_dt and complaint.created_at and complaint.created_at.date() > e_dt:
            continue
        if search_value and not search_matches(complaint, analysis, search_value):
            continue

        filtered.append(summary(complaint, analysis))

    return filtered


@router.get("/complaints/{complaint_id}", response_model=ComplaintDetail)
def get_complaint(
    complaint_id: int,
    village_id: int | None = Query(default=None, gt=0),
    district: str | None = Query(default=None, min_length=1),
    taluka: str | None = Query(default=None, min_length=1),
    all_villages: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_officer),
) -> ComplaintDetail:
    complaint = get_complaint_in_scope(
        db,
        current_user,
        complaint_id,
        village_id=village_id,
        district=district,
        all_villages=all_villages,
        taluka=taluka,
    )
    return detail(complaint, latest_analysis(db, complaint.id))


@router.patch("/complaints/{complaint_id}/assignment", response_model=ComplaintDetail)
def assign_complaint(
    complaint_id: int,
    payload: AssignmentRequest,
    village_id: int | None = Query(default=None, gt=0),
    district: str | None = Query(default=None, min_length=1),
    taluka: str | None = Query(default=None, min_length=1),
    all_villages: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_officer),
) -> ComplaintDetail:
    complaint = get_complaint_in_scope(
        db,
        current_user,
        complaint_id,
        village_id=village_id,
        district=district,
        all_villages=all_villages,
        taluka=taluka,
    )

    if payload.assigned_officer_id is not None:
        officer = db.get(User, payload.assigned_officer_id)

        if officer is None or officer.role not in {"village_officer", "admin"}:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Assigned user is not an officer",
            )

        if (
            officer.role != "admin"
            and officer.village_id != complaint.village_id
        ):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Assigned officer must belong to the complaint's village",
            )

    complaint.assigned_department = payload.assigned_department
    complaint.assigned_officer_id = payload.assigned_officer_id
    complaint.assigned_at = datetime.now(UTC)
    complaint.expected_resolution_date = payload.expected_resolution_date

    if complaint.status == "Pending":
        complaint.status = "Assigned"

    assigned_officer_id = complaint.assigned_officer_id
    if assigned_officer_id is not None:
        notification_service.notify(
            db,
            user_id=assigned_officer_id,
            complaint_id=complaint.id,
            notification_type=NotificationEvent.COMPLAINT_ASSIGNED,
            message=f"Complaint #{complaint.id} was assigned to you.",
        )

    db.commit()
    db.refresh(complaint)
    return detail(complaint, latest_analysis(db, complaint.id))


@router.patch("/complaints/{complaint_id}/status", response_model=ComplaintDetail)
def update_status(
    complaint_id: int,
    payload: StatusUpdateRequest,
    village_id: int | None = Query(default=None, gt=0),
    district: str | None = Query(default=None, min_length=1),
    taluka: str | None = Query(default=None, min_length=1),
    all_villages: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_officer),
) -> ComplaintDetail:
    complaint = get_complaint_in_scope(
        db,
        current_user,
        complaint_id,
        village_id=village_id,
        district=district,
        all_villages=all_villages,
        taluka=taluka,
    )

    # Valid status transitions
    valid_transitions = {
        "Pending": {"Pending", "Assigned", "In Progress", "Rejected"},
        "Assigned": {"Assigned", "In Progress", "Resolved", "Rejected", "Pending"},
        "In Progress": {"In Progress", "Resolved", "Pending", "Escalated", "Rejected"},
        "Resolved": {"Resolved", "Closed", "Reopened"},
        "Closed": {"Closed", "Reopened"},
        "Reopened": {"Reopened", "In Progress", "Assigned", "Pending", "Resolved"},
        "Escalated": {"Escalated", "In Progress", "Resolved", "Assigned"},
        "Rejected": {"Rejected", "Pending", "Reopened"},
    }
    allowed = valid_transitions.get(complaint.status, {complaint.status, "In Progress", "Resolved", "Rejected"})
    if payload.status not in allowed:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Invalid status transition from '{complaint.status}' to '{payload.status}'.",
        )

    if payload.status == "Rejected":
        if not payload.action_notes or not payload.action_notes.strip():
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Rejection reason is required when rejecting a complaint.",
            )

    complaint.status = payload.status

    if payload.action_notes is not None:
        complaint.action_notes = payload.action_notes

    if payload.repair_evidence_url is not None:
        complaint.repair_evidence_url = payload.repair_evidence_url

    if payload.completion_date is not None:
        complaint.completion_date = payload.completion_date
    elif payload.status == "Resolved" and complaint.completion_date is None:
        complaint.completion_date = datetime.now(UTC)

    notification_recipient_ids = {
        user_id
        for user_id in (complaint.user_id, complaint.assigned_officer_id)
        if user_id is not None
    }
    for user_id in notification_recipient_ids:
        notification_service.notify(
            db,
            user_id=user_id,
            complaint_id=complaint.id,
            notification_type=NotificationEvent.STATUS_CHANGED,
            message=f"Complaint #{complaint.id} status changed to {payload.status}.",
        )

    if payload.status == "Resolved":
        verification_service.request_for_resolved_complaint(db, complaint)

    db.commit()
    db.refresh(complaint)
    return detail(complaint, latest_analysis(db, complaint.id))


@router.post("/complaints/{complaint_id}/work-order", response_model=ComplaintDetail)
def process_work_order(
    complaint_id: int,
    payload: WorkOrderActionRequest,
    village_id: int | None = Query(default=None, gt=0),
    district: str | None = Query(default=None, min_length=1),
    taluka: str | None = Query(default=None, min_length=1),
    all_villages: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_officer),
) -> ComplaintDetail:
    """Accept, reject, or reassign work orders with recorded reasons (SRS Module 4)."""
    complaint = get_complaint_in_scope(
        db,
        current_user,
        complaint_id,
        village_id=village_id,
        district=district,
        all_villages=all_villages,
        taluka=taluka,
    )

    now_iso = datetime.now(UTC).strftime("%Y-%m-%d %H:%M UTC")
    officer_name = current_user.full_name or f"Officer #{current_user.id}"

    if payload.action == "accept":
        complaint.status = "In Progress"
        entry = f"[{now_iso}] Work Order ACCEPTED by {officer_name}: {payload.reason}"
    elif payload.action == "reject":
        complaint.status = "Pending"
        entry = f"[{now_iso}] Work Order REJECTED by {officer_name}: {payload.reason}"
    elif payload.action == "reassign":
        old_dept = complaint.assigned_department or "Unassigned"
        if payload.reassigned_department:
            complaint.assigned_department = payload.reassigned_department
        if payload.reassigned_officer_id:
            complaint.assigned_officer_id = payload.reassigned_officer_id
        entry = f"[{now_iso}] Work Order REASSIGNED from '{old_dept}' to '{complaint.assigned_department}' by {officer_name}: {payload.reason}"
    else:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Invalid work order action",
        )

    if complaint.action_notes:
        complaint.action_notes = f"{complaint.action_notes}\n{entry}"
    else:
        complaint.action_notes = entry

    recipients = {u for u in (complaint.user_id, complaint.assigned_officer_id) if u}
    for uid in recipients:
        notification_service.notify(
            db,
            user_id=uid,
            complaint_id=complaint.id,
            notification_type=NotificationEvent.STATUS_CHANGED,
            message=f"Work Order update on #{complaint.id}: {payload.action.upper()} - {payload.reason}",
        )

    db.commit()
    db.refresh(complaint)
    return detail(complaint, latest_analysis(db, complaint.id))


@router.post("/complaints/{complaint_id}/ai-override", response_model=ComplaintDetail)
def override_ai_prediction(
    complaint_id: int,
    payload: AIOverrideRequest,
    village_id: int | None = Query(default=None, gt=0),
    district: str | None = Query(default=None, min_length=1),
    taluka: str | None = Query(default=None, min_length=1),
    all_villages: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_officer),
) -> ComplaintDetail:
    """Allow officer to override and correct AI predictions (SRS Module 2)."""
    complaint = get_complaint_in_scope(
        db,
        current_user,
        complaint_id,
        village_id=village_id,
        district=district,
        all_villages=all_villages,
        taluka=taluka,
    )

    analysis = latest_analysis(db, complaint_id)
    now_iso = datetime.now(UTC).strftime("%Y-%m-%d %H:%M UTC")
    officer_name = current_user.full_name or f"Officer #{current_user.id}"

    changes = []
    if analysis:
        if payload.corrected_category and payload.corrected_category != analysis.category:
            changes.append(f"Category: '{analysis.category}' -> '{payload.corrected_category}'")
            analysis.category = payload.corrected_category
            if payload.corrected_category in CATEGORY_DEPARTMENTS:
                analysis.recommended_department = CATEGORY_DEPARTMENTS[payload.corrected_category]
        if payload.corrected_severity and payload.corrected_severity != analysis.severity:
            changes.append(f"Severity: '{analysis.severity}' -> '{payload.corrected_severity}'")
            analysis.severity = payload.corrected_severity
    else:
        analysis = AIAnalysis(
            complaint_id=complaint.id,
            category=payload.corrected_category or "Other",
            confidence=1.0,
            severity=payload.corrected_severity or "Medium",
            severity_explanation=f"Manual officer override: {payload.override_reason}",
            priority_score=50.0,
            priority_level="Medium",
            priority_explanation="Officer override assigned",
            recommended_department=CATEGORY_DEPARTMENTS.get(payload.corrected_category or "Other", "Gram Panchayat General"),
            evidence_status="not_provided",
        )
        db.add(analysis)
        changes.append(f"Initial Classification: Category={analysis.category}, Severity={analysis.severity}")

    log_entry = f"[{now_iso}] AI Override by {officer_name}: {', '.join(changes)}. Reason: {payload.override_reason}"
    if complaint.action_notes:
        complaint.action_notes = f"{complaint.action_notes}\n{log_entry}"
    else:
        complaint.action_notes = log_entry

    db.commit()
    db.refresh(complaint)
    return detail(complaint, analysis)


@router.get("/reports/export-complaints-csv")
def export_complaints_csv(
    village_id: int | None = Query(default=None, gt=0),
    district: str | None = Query(default=None, min_length=1),
    taluka: str | None = Query(default=None, min_length=1),
    all_villages: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_officer),
) -> Response:
    """Export complete complaint ledger as CSV (SRS Module 7)."""
    rows = complaint_rows(db, current_user, village_id, district, all_villages, taluka)
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow([
        "Complaint ID",
        "Title / Text",
        "Status",
        "Village",
        "Category",
        "Severity",
        "Priority Level",
        "Priority Score",
        "Assigned Department",
        "Assigned Officer",
        "Created At",
        "Expected Resolution Date",
        "Is Overdue",
        "Location / Landmark",
        "Action Notes",
    ])
    for complaint, analysis in rows:
        writer.writerow([
            complaint.id,
            (complaint.text or "").replace("\n", " ").strip()[:150],
            complaint.status,
            complaint.village.name if complaint.village else "",
            analysis.category if analysis else "",
            analysis.severity if analysis else "",
            analysis.priority_level if analysis else "",
            analysis.priority_score if analysis else "",
            complaint.assigned_department or "Unassigned",
            complaint.assigned_officer.full_name if complaint.assigned_officer else "",
            complaint.created_at.isoformat() if complaint.created_at else "",
            complaint.expected_resolution_date.isoformat() if complaint.expected_resolution_date else "",
            "Yes" if is_complaint_overdue(complaint) else "No",
            complaint.exact_location or complaint.lane or "",
            (complaint.action_notes or "").replace("\n", " | ").strip()[:200],
        ])

    csv_data = output.getvalue()
    filename = f"village_complaints_{datetime.now(UTC).strftime('%Y%m%d')}.csv"
    return Response(
        content=csv_data,
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


@router.get("/reports/export-governance-csv")
def export_governance_csv(
    village_id: int | None = Query(default=None, gt=0),
    district: str | None = Query(default=None, min_length=1),
    taluka: str | None = Query(default=None, min_length=1),
    all_villages: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_officer),
) -> Response:
    """Export Gram Panchayat governance summary KPIs as CSV (SRS Module 7)."""
    rows = complaint_rows(db, current_user, village_id, district, all_villages, taluka)
    total = len(rows)
    resolved = sum(complaint.status == "Resolved" for complaint, _ in rows)
    pending = sum(complaint.status == "Pending" for complaint, _ in rows)
    in_progress = sum(complaint.status == "In Progress" for complaint, _ in rows)
    overdue = sum(is_complaint_overdue(complaint) for complaint, _ in rows)
    critical = sum(analysis.severity == "Critical" for _, analysis in rows if analysis)
    rate = round((resolved / total) * 100, 2) if total else 0.0

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["Metric", "Value", "Description"])
    writer.writerow(["Total Complaints", total, "Total grievances received to date"])
    writer.writerow(["Pending Complaints", pending, "Complaints waiting for department triage"])
    writer.writerow(["In Progress", in_progress, "Complaints currently undergoing ground repair"])
    writer.writerow(["Resolved Complaints", resolved, "Total complaints marked resolved"])
    writer.writerow(["Resolution Rate (%)", f"{rate}%", "Percentage of resolved vs total complaints"])
    writer.writerow(["Overdue Breaches", overdue, "Cases exceeding citizen service charter SLA"])
    writer.writerow(["Critical Severity", critical, "Life-safety / high-impact village emergency cases"])
    writer.writerow(["Generated At", datetime.now(UTC).isoformat(), "Automated audit timestamp"])

    csv_data = output.getvalue()
    filename = f"governance_summary_{datetime.now(UTC).strftime('%Y%m%d')}.csv"
    return Response(
        content=csv_data,
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


@router.get("/insights", response_model=InsightResponse)
def insights(
    village_id: int | None = Query(default=None, gt=0),
    district: str | None = Query(default=None, min_length=1),
    taluka: str | None = Query(default=None, min_length=1),
    all_villages: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_officer),
) -> InsightResponse:
    rows = complaint_rows(db, current_user, village_id, district, all_villages, taluka)

    status_counts = Counter(
        complaint.status for complaint, _ in rows
    )
    category_counts = Counter(
        analysis.category for _, analysis in rows if analysis and analysis.category
    )
    severity_counts = Counter(
        analysis.severity for _, analysis in rows if analysis and analysis.severity
    )
    priority_counts = Counter(
        analysis.priority_level for _, analysis in rows if analysis and analysis.priority_level
    )
    department_workload = Counter(
        complaint.assigned_department or "Unassigned"
        for complaint, _ in rows
    )

    time_counts: Counter[str] = Counter()
    for complaint, _ in rows:
        if complaint.created_at is not None:
            time_counts[complaint.created_at.date().isoformat()] += 1

    complaints_over_time = [
        {"date": date, "count": count}
        for date, count in sorted(time_counts.items())
    ]

    total = len(rows)
    resolved = sum(complaint.status == "Resolved" for complaint, _ in rows)
    resolution_rate = {
        "rate": round((resolved / total) * 100, 2) if total else 0.0,
        "resolved": resolved,
        "total": total,
        "rule": "resolved / total complaints * 100",
    }

    overdue_complaints: list[dict[str, int | str | bool | None]] = []
    for complaint, _ in rows:
        if not is_complaint_overdue(complaint):
            continue
        overdue_complaints.append(
            {
                "complaint_id": complaint.id,
                "title": complaint.text.strip()[:80] if complaint.text else "Complaint",
                "status": complaint.status,
                "days_overdue": max(
                    0,
                    (datetime.now(UTC) - as_utc(complaint.expected_resolution_date)).days
                    if complaint.expected_resolution_date is not None
                    else 0,
                ),
            }
        )

    repeated: list[dict[str, int | str | None]] = [
        {
            "complaint_id": complaint.id,
            "village_id": complaint.village_id,
            "repeated_complaints": complaint.repeated_complaints,
        }
        for complaint, _ in rows
        if complaint.repeated_complaints > 0
    ]
    repeated.sort(
        key=lambda item: int(item["repeated_complaints"]) if item["repeated_complaints"] is not None else 0,
        reverse=True,
    )

    ai_insights: list[dict[str, int | str | float | None]] = []
    for complaint, analysis in rows:
        if analysis is None:
            continue
        ai_insights.append(
            {
                "complaint_id": complaint.id,
                "category": analysis.category,
                "priority_level": analysis.priority_level,
                "severity": analysis.severity,
                "confidence": round((analysis.confidence or 0.0) * 100, 1) if analysis.confidence is not None else None,
                "recommended_department": analysis.recommended_department,
            }
        )

    return InsightResponse(
        status_counts=dict(sorted(status_counts.items())),
        category_counts=dict(sorted(category_counts.items())),
        severity_counts=dict(sorted(severity_counts.items())),
        priority_counts=dict(sorted(priority_counts.items())),
        complaints_over_time=complaints_over_time,
        resolution_rate=resolution_rate,
        overdue_complaints=overdue_complaints,
        repeated_complaints=repeated,
        department_workload=dict(sorted(department_workload.items())),
        ai_insights=ai_insights,
    )


@router.get("/analytics/advanced", response_model=AdvancedAnalyticsResponse)
def advanced_analytics(
    start_date: str | None = Query(default=None),
    end_date: str | None = Query(default=None),
    category: str | None = Query(default=None),
    status: str | None = Query(default=None),
    department: str | None = Query(default=None),
    area: str | None = Query(default=None),
    interval: str = Query(default="day", pattern="^(day|week|month)$"),
    village_id: int | None = Query(default=None, gt=0),
    district: str | None = Query(default=None, min_length=1),
    taluka: str | None = Query(default=None, min_length=1),
    all_villages: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_officer),
) -> AdvancedAnalyticsResponse:
    """Multi-dimensional Village Intelligence & Analytics (Data Science Core)."""
    all_rows = complaint_rows(db, current_user, village_id, district, all_villages, taluka)

    available_areas = sorted(list({
        (c.area or c.lane or "General Ward").strip()
        for c, _ in all_rows
        if (c.area or c.lane or "General Ward").strip()
    }))
    available_categories = sorted(list({
        a.category.strip()
        for _, a in all_rows
        if a and a.category
    }))
    available_departments = sorted(list({
        c.assigned_department.strip()
        for c, _ in all_rows
        if c.assigned_department and c.assigned_department.strip()
    }))

    cat_norm = normalize_filter(category)
    stat_norm = normalize_filter(status)
    dept_norm = normalize_filter(department)
    area_norm = normalize_filter(area)

    filtered_rows = []
    for complaint, analysis in all_rows:
        if cat_norm and (not analysis or normalize_filter(analysis.category) != cat_norm):
            continue
        if stat_norm and normalize_filter(complaint.status) != stat_norm:
            continue
        if dept_norm and normalize_filter(complaint.assigned_department) != dept_norm:
            continue
        comp_area = (complaint.area or complaint.lane or "General Ward").strip()
        if area_norm and normalize_filter(comp_area) != area_norm:
            continue

        c_date = complaint.created_at.date() if complaint.created_at else None
        if start_date:
            try:
                s_dt = datetime.strptime(start_date, "%Y-%m-%d").date()
                if c_date and c_date < s_dt:
                    continue
            except ValueError:
                pass
        if end_date:
            try:
                e_dt = datetime.strptime(end_date, "%Y-%m-%d").date()
                if c_date and c_date > e_dt:
                    continue
            except ValueError:
                pass

        filtered_rows.append((complaint, analysis))

    total_count = len(filtered_rows)
    pending_count = sum(c.status == "Pending" for c, _ in filtered_rows)
    in_progress_count = sum(c.status == "In Progress" for c, _ in filtered_rows)
    resolved_count = sum(c.status in {"Resolved", "Closed"} for c, _ in filtered_rows)
    critical_count = sum(a.severity == "Critical" for _, a in filtered_rows if a)
    overdue_count = sum(is_complaint_overdue(c) for c, _ in filtered_rows)
    resolution_rate = round((resolved_count / total_count * 100), 2) if total_count else 0.0

    kpi_summary = {
        "total": total_count,
        "pending": pending_count,
        "in_progress": in_progress_count,
        "resolved": resolved_count,
        "critical": critical_count,
        "overdue": overdue_count,
        "resolution_rate": resolution_rate,
    }

    category_distribution = Counter(a.category for _, a in filtered_rows if a and a.category)
    status_distribution = Counter(c.status for c, _ in filtered_rows if c.status)
    department_workload = dict(sorted(Counter(
        (c.assigned_department or "Unassigned").strip()
        for c, _ in filtered_rows
    ).items()))

    trend_counts: Counter[str] = Counter()
    for c, _ in filtered_rows:
        if c.created_at:
            if interval == "month":
                bucket = c.created_at.strftime("%Y-%m")
            elif interval == "week":
                bucket = f"{c.created_at.year}-W{c.created_at.isocalendar()[1]:02d}"
            else:
                bucket = c.created_at.strftime("%Y-%m-%d")
            trend_counts[bucket] += 1

    trend_timeline = [
        {"date": bucket, "count": count}
        for bucket, count in sorted(trend_counts.items())
    ]

    area_groups: dict[str, list[tuple[Complaint, AIAnalysis | None]]] = defaultdict(list)
    cat_groups: dict[str, list[tuple[Complaint, AIAnalysis | None]]] = defaultdict(list)
    for c, a in filtered_rows:
        a_name = (c.area or c.lane or "General Ward").strip()
        area_groups[a_name].append((c, a))
        c_name = (a.category if a and a.category else "Other").strip()
        cat_groups[c_name].append((c, a))

    sev_scores = {"Low": 1, "Medium": 2, "High": 3, "Critical": 4}
    area_bubbles: list[AreaBubblePoint] = []
    for a_name, c_list in sorted(area_groups.items()):
        cnt = len(c_list)
        p_scores = [a.priority_score for _, a in c_list if a and a.priority_score is not None]
        avg_pri = round(sum(p_scores) / len(p_scores), 1) if p_scores else 40.0
        tot_impact = sum(max(1, c.affected_people, (c.repeated_complaints or 0) * 2) for c, _ in c_list)
        s_vals = [sev_scores.get(a.severity, 2) for _, a in c_list if a and a.severity]
        avg_sev = round(sum(s_vals) / len(s_vals), 1) if s_vals else 2.0
        dom_cat = Counter(a.category for _, a in c_list if a and a.category).most_common(1)
        dominant_category = dom_cat[0][0] if dom_cat else "General"

        area_bubbles.append(AreaBubblePoint(
            area_name=a_name,
            complaint_count=cnt,
            avg_priority_score=avg_pri,
            total_affected_or_repeated=tot_impact,
            avg_severity_score=avg_sev,
            dominant_category=dominant_category,
        ))

    category_bubbles: list[CategoryBubblePoint] = []
    for c_name, c_list in sorted(cat_groups.items()):
        cnt = len(c_list)
        unres = sum(c.status not in {"Resolved", "Closed"} for c, _ in c_list)
        s_vals = [sev_scores.get(a.severity, 2) for _, a in c_list if a and a.severity]
        avg_sev = round(sum(s_vals) / len(s_vals), 1) if s_vals else 2.0
        p_scores = [a.priority_score for _, a in c_list if a and a.priority_score is not None]
        avg_pri = round(sum(p_scores) / len(p_scores), 1) if p_scores else 40.0
        category_bubbles.append(CategoryBubblePoint(
            category=c_name,
            total_count=cnt,
            unresolved_count=unres,
            avg_severity_score=avg_sev,
            avg_priority_score=avg_pri,
        ))

    res_hours: list[float] = []
    cat_res_times: dict[str, list[float]] = defaultdict(list)
    dept_res_times: dict[str, list[float]] = defaultdict(list)
    for c, a in filtered_rows:
        if c.status in {"Resolved", "Closed"} and c.created_at and c.completion_date:
            hours = (c.completion_date - c.created_at).total_seconds() / 3600
            if hours >= 0:
                res_hours.append(hours)
                if a and a.category:
                    cat_res_times[a.category].append(hours)
                if c.assigned_department:
                    dept_res_times[c.assigned_department].append(hours)

    histogram_bins = {
        "< 12 hrs": 0,
        "12-24 hrs": 0,
        "24-48 hrs": 0,
        "48-72 hrs": 0,
        "3-7 days": 0,
        "> 7 days": 0,
    }
    for h in res_hours:
        if h < 12:
            histogram_bins["< 12 hrs"] += 1
        elif h < 24:
            histogram_bins["12-24 hrs"] += 1
        elif h < 48:
            histogram_bins["24-48 hrs"] += 1
        elif h < 72:
            histogram_bins["48-72 hrs"] += 1
        elif h <= 168:
            histogram_bins["3-7 days"] += 1
        else:
            histogram_bins["> 7 days"] += 1

    resolution_analytics = ResolutionAnalytics(
        average_hours=round(sum(res_hours) / len(res_hours), 1) if res_hours else None,
        min_hours=round(min(res_hours), 1) if res_hours else None,
        max_hours=round(max(res_hours), 1) if res_hours else None,
        resolved_count=len(res_hours),
        histogram_bins=histogram_bins,
        by_category={k: round(sum(v) / len(v), 1) for k, v in cat_res_times.items()},
        by_department={k: round(sum(v) / len(v), 1) for k, v in dept_res_times.items()},
    )

    cluster_counts: Counter[tuple[str, str]] = Counter()
    cluster_unresolved: Counter[tuple[str, str]] = Counter()
    for c, a in filtered_rows:
        loc = (c.exact_location or c.lane or c.area or "General Area").strip()
        cat = (a.category if a and a.category else "Other").strip()
        key = (loc, cat)
        cluster_counts[key] += (1 + (c.repeated_complaints or 0))
        if c.status not in {"Resolved", "Closed"}:
            cluster_unresolved[key] += 1

    frequent_problems = [
        FrequentIssueItem(
            location=loc,
            category=cat,
            count=count,
            unresolved_count=cluster_unresolved.get((loc, cat), 0),
        )
        for (loc, cat), count in cluster_counts.most_common(10)
    ]

    heatmap_points: list[HeatmapPoint] = []
    sev_weights = {"Low": 0.3, "Medium": 0.6, "High": 0.85, "Critical": 1.0}
    for c, a in filtered_rows:
        if is_valid_coordinate(c.latitude, c.longitude):
            sev = a.severity if a else "Medium"
            w = sev_weights.get(sev, 0.5)
            heatmap_points.append(HeatmapPoint(
                complaint_id=c.id,
                latitude=float(c.latitude),
                longitude=float(c.longitude),
                weight=w,
                category=a.category if a else None,
                severity=sev,
            ))

    return AdvancedAnalyticsResponse(
        kpi_summary=kpi_summary,
        category_distribution=dict(sorted(category_distribution.items())),
        status_distribution=dict(sorted(status_distribution.items())),
        trend_timeline=trend_timeline,
        area_bubble_metrics=area_bubbles,
        category_bubble_metrics=category_bubbles,
        resolution_analytics=resolution_analytics,
        frequent_problems=frequent_problems,
        heatmap_points=heatmap_points,
        department_workload=department_workload,
        available_areas=available_areas,
        available_categories=available_categories,
        available_departments=available_departments,
    )


@router.get("/digital-twin", response_model=DigitalTwinResponse)
def digital_twin(
    category: str | None = Query(default=None),
    status: str | None = Query(default=None),
    village_id: int | None = Query(default=None, gt=0),
    district: str | None = Query(default=None, min_length=1),
    taluka: str | None = Query(default=None, min_length=1),
    all_villages: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_officer),
) -> DigitalTwinResponse:
    """Village Digital Twin: GIS coordinates, boundary tracking, and 9-domain asset registry (SRS Module 6)."""
    rows = complaint_rows(db, current_user, village_id, district, all_villages, taluka)
    category_value = normalize_filter(category)
    status_value = normalize_filter(status)

    if category_value is not None:
        rows = [
            (complaint, analysis)
            for complaint, analysis in rows
            if analysis is not None and normalize_filter(analysis.category) == category_value
        ]

    if status_value is not None:
        rows = [
            (complaint, analysis)
            for complaint, analysis in rows
            if normalize_filter(complaint.status) == status_value
        ]

    village_ids = selected_village_ids(
        db, current_user, village_id, district, all_villages, taluka
    )
    if village_ids is None or len(village_ids) != 1:
        village = None
        village_data: dict[str, int | str | float | None] = {
            "id": village_ids[0] if village_ids else None,
            "name": (
                "All villages"
                if village_ids is None
                else taluka or district or "Selected area"
            ),
            "district": district,
            "taluka": taluka,
            "state": None,
            "latitude": None,
            "longitude": None,
            "boundary_radius_km": None,
            "complaint_count": len(rows),
        }
    else:
        village = db.get(Village, village_ids[0])
        village_data = {
            "id": village.id if village else None,
            "name": village.name if village else "No village assigned",
            "district": village.district if village else None,
            "taluka": village.taluka if village else None,
            "state": village.state if village else None,
            "latitude": village.latitude if village else None,
            "longitude": village.longitude if village else None,
            "boundary_radius_km": village.boundary_radius_km if village else None,
            "complaint_count": len(rows),
        }

    category_counts = Counter(
        analysis.category for _, analysis in rows if analysis and analysis.category
    )

    resource_rows: list[dict[str, int | str]] = []
    for category_name in CATEGORY_DEPARTMENTS:
        resource_name = (
            "Documents"
            if category_name == "Government Documents"
            else category_name
        )
        active_issues = category_counts.get(category_name, 0)
        resource_rows.append({
            "resource": resource_name,
            "department": CATEGORY_DEPARTMENTS[category_name],
            "active_issues": active_issues,
            "status": "Issues reported" if active_issues else "No current complaints",
        })

    # SRS Module 6: 9-Domain Village Digital Twin Asset Registry
    nine_domains_registry = [
        ("WTR-01", "Water", "Community Borewell & Overhead Tank", "Ward 2 Water Station", "Water"),
        ("RDS-01", "Roads", "Main Village Approach Road & Arterial Lanes", "Village North Highway Link", "Roads"),
        ("DOC-01", "Documents", "Seva Kendra Citizen Portal & Kiosk", "Gram Panchayat Office Bhavan", "Government Documents"),
        ("STD-01", "Study room", "Village E-Library & Solar Study Room", "Community Hall East Wing", "Education"),
        ("ELC-01", "Electricity", "100 kVA Feeder Transformer & LED Lights", "East Ward Substation", "Electricity"),
        ("CTV-01", "CCTV", "Chowk Security & Traffic Camera Array", "Central Bazaar Chowk", "Internet"),
        ("SAN-01", "Sanitation", "Solid Waste Segregation & Community Toilet Complex", "South Village Perimeter", "Sanitation"),
        ("AGR-01", "Agriculture", "Soil & Water Testing Center & Sluice Gate", "Canal Junction Gate #2", "Agriculture"),
        ("MED-01", "Medical", "Primary Health Sub-Center Dispensary", "Health Center Road", "Medical"),
    ]

    assets: list[VillageAsset] = []
    for asset_id, domain, name, location, cat_key in nine_domains_registry:
        c_count = category_counts.get(cat_key, 0)
        if domain == "Documents":
            c_count += category_counts.get("Documents", 0)
        elif domain == "Sanitation":
            c_count += category_counts.get("Drainage", 0)
        elif domain == "Electricity":
            c_count += category_counts.get("Street Light", 0)

        if c_count == 0:
            cond = 96
            asset_status = "Operational"
            notes = "Nominal operating status; routine monthly inspection verified."
        elif c_count == 1:
            cond = 74
            asset_status = "Maintenance Required"
            notes = "1 active complaint logged; field maintenance crew alerted."
        else:
            cond = max(35, 95 - (c_count * 15))
            asset_status = "Under Repair"
            notes = f"{c_count} active complaints logged; work order and repairs active."

        assets.append(VillageAsset(
            asset_id=asset_id,
            domain=domain,
            name=name,
            location=location,
            condition_index=cond,
            status=asset_status,
            active_complaints_count=c_count,
            last_inspected="October 2026",
            maintenance_notes=notes,
        ))

    map_points: list[dict[str, int | float | str | bool | None]] = []
    boundary_alerts: list[dict[str, int | float | str | bool | None]] = []

    for complaint, analysis in rows:
        complaint_village = complaint.village
        boundary_village = (
            complaint_village
            if complaint_village is not None
            else village
        )
        boundary_status = complaint_boundary_status(complaint, boundary_village)
        point = {
            "complaint_id": complaint.id,
            "village_id": complaint.village_id,
            "village": complaint_village.name if complaint_village else None,
            "lane": complaint.lane,
            "lane_number": complaint.lane_number,
            "exact_location": complaint.exact_location,
            "area": complaint.area,
            "latitude": complaint.latitude,
            "longitude": complaint.longitude,
            "status": complaint.status,
            "category": analysis.category if analysis else None,
            "priority_level": analysis.priority_level if analysis else None,
            "repeated_complaints": complaint.repeated_complaints,
            "is_valid_coordinate": boundary_status["is_valid_coordinate"],
            "is_outside_boundary": boundary_status["is_outside_boundary"],
            "distance_from_village_km": boundary_status["distance_from_village_km"],
            "boundary_radius_km": boundary_status["boundary_radius_km"],
        }
        map_points.append(point)

        if boundary_status["is_outside_boundary"]:
            boundary_alerts.append({
                "complaint_id": complaint.id,
                "village_id": complaint.village_id,
                "village": complaint_village.name if complaint_village else None,
                "status": complaint.status,
                "distance_from_village_km": boundary_status["distance_from_village_km"],
                "boundary_radius_km": boundary_status["boundary_radius_km"],
                "message": "Complaint lies outside the assigned village boundary radius.",
            })

    map_message = None
    valid_points = [point for point in map_points if point["is_valid_coordinate"]]
    if not valid_points:
        map_message = "No valid complaint coordinates are available for this village."
    elif village is not None and village.boundary_radius_km is not None:
        map_message = (
            "Map displays valid complaint coordinates; outside-boundary issues are flagged for review."
        )

    return DigitalTwinResponse(
        village=village_data,
        resources=resource_rows,
        assets=assets,
        map_points=map_points,
        boundary_alerts=boundary_alerts,
        map_message=map_message,
    )


@router.get("/complaints/{complaint_id}/evidence/{filename}")
def get_officer_complaint_evidence_file(
    complaint_id: int,
    filename: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_officer),
) -> FileResponse:
    complaint = get_complaint_in_scope(db, current_user, complaint_id)
    safe_name = Path(filename).name
    if not complaint.evidence_url or Path(complaint.evidence_url).name != safe_name:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Evidence file not found",
        )
    file_path = UPLOAD_DIR / safe_name
    if not file_path.is_file():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Evidence file not found",
        )
    content_type, _ = mimetypes.guess_type(str(file_path))
    return FileResponse(
        path=file_path,
        media_type=content_type or "application/octet-stream",
        headers={"Content-Disposition": "inline"},
    )
