from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.dependencies import require_officer
from app.db.session import get_db
from app.models import User
from app.schemas.phase5 import AnalyticsResponse, EscalationRunResponse, PredictionResponse, ReportResponse
from app.services.analytics import build_analytics, build_prediction, build_report
from app.services.village_scope import selected_village_ids
from app.services.verification import VerificationService

router = APIRouter(prefix="/officer", tags=["village-intelligence"], dependencies=[Depends(require_officer)])
verification_service = VerificationService()


def village_scope(
    db: Session,
    current_user: User,
    village_id: int | None,
    district: str | None,
    all_villages: bool,
    taluka: str | None = None,
) -> tuple[int | None, bool, list[int] | None]:
    village_ids = selected_village_ids(
        db, current_user, village_id, district, all_villages, taluka
    )
    return (
        village_ids[0] if village_ids is not None and len(village_ids) == 1 else None,
        village_ids is None,
        village_ids,
    )


@router.get("/analytics", response_model=AnalyticsResponse)
def analytics(
    village_id: int | None = Query(default=None, gt=0),
    district: str | None = Query(default=None, min_length=1),
    taluka: str | None = Query(default=None, min_length=1),
    all_villages: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_officer),
) -> AnalyticsResponse:
    scoped_village_id, include_all_villages, village_ids = village_scope(
        db, current_user, village_id, district, all_villages, taluka
    )
    return AnalyticsResponse(
        **build_analytics(db, scoped_village_id, include_all_villages, village_ids)
    )


@router.get("/predictions/repeated-issues", response_model=PredictionResponse)
def repeated_issue_predictions(
    village_id: int | None = Query(default=None, gt=0),
    district: str | None = Query(default=None, min_length=1),
    taluka: str | None = Query(default=None, min_length=1),
    all_villages: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_officer),
) -> PredictionResponse:
    scoped_village_id, include_all_villages, village_ids = village_scope(
        db, current_user, village_id, district, all_villages, taluka
    )
    return PredictionResponse(
        **build_prediction(db, scoped_village_id, include_all_villages, village_ids)
    )


@router.get("/reports/summary", response_model=ReportResponse)
def summary_report(
    village_id: int | None = Query(default=None, gt=0),
    district: str | None = Query(default=None, min_length=1),
    taluka: str | None = Query(default=None, min_length=1),
    all_villages: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_officer),
) -> ReportResponse:
    scoped_village_id, include_all_villages, village_ids = village_scope(
        db, current_user, village_id, district, all_villages, taluka
    )
    return ReportResponse(
        **build_report(db, scoped_village_id, include_all_villages, village_ids)
    )


@router.post("/escalations/check", response_model=EscalationRunResponse)
def run_escalation_check(
    village_id: int | None = Query(default=None, gt=0),
    district: str | None = Query(default=None, min_length=1),
    taluka: str | None = Query(default=None, min_length=1),
    all_villages: bool = Query(default=False),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_officer),
) -> EscalationRunResponse:
    scoped_village_id, include_all_villages, village_ids = village_scope(
        db, current_user, village_id, district, all_villages, taluka
    )
    return EscalationRunResponse(
        escalated_count=verification_service.check_overdue(
            db, scoped_village_id, include_all_villages, village_ids
        ),
        threshold_hours=settings.escalation_after_hours,
    )
