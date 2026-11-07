from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.ai.classifier import ClassifierUnavailable
from app.ai.service import ComplaintAnalysisService
from app.db.session import get_db
from app.models import Complaint
from app.schemas.ai import AIAnalysisResponse, AnalyzeComplaintRequest

router = APIRouter(prefix="/ai", tags=["ai-intelligence"])
analysis_service = ComplaintAnalysisService()


@router.post("/analyze-complaint", response_model=AIAnalysisResponse, status_code=status.HTTP_201_CREATED)
def analyze_complaint(
    payload: AnalyzeComplaintRequest,
    db: Session = Depends(get_db),
) -> AIAnalysisResponse:
    complaint = None
    if payload.complaint_id is not None:
        complaint = db.get(Complaint, payload.complaint_id)
        if complaint is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Complaint not found")

    text = payload.complaint_text or (complaint.text if complaint else None)
    if text is None:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Complaint text is unavailable")

    try:
        outcome = analysis_service.analyze(
            db=db,
            text=text,
            language=payload.language if payload.complaint_text else complaint.language,
            complaint_id=payload.complaint_id,
            affected_people=payload.affected_people if payload.complaint_text else complaint.affected_people,
            complaint_age_hours=payload.complaint_age_hours,
            repeated_complaints=payload.repeated_complaints if payload.complaint_text else complaint.repeated_complaints,
            location_importance=payload.location_importance if payload.complaint_text else complaint.location_importance,
            evidence_media_type=payload.evidence_media_type,
            evidence_size_bytes=payload.evidence_size_bytes,
        )
    except ClassifierUnavailable as error:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(error)) from error
    analysis_response = AIAnalysisResponse.model_validate(outcome.analysis)
    return analysis_response.model_copy(update={"model_status": outcome.model_status})
