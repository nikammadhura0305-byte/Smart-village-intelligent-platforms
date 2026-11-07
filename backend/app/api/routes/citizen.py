import base64
import binascii
import json
import mimetypes
import uuid
from pathlib import Path
from fastapi import Request
from fastapi.responses import FileResponse
from app.ai.evidence import SUPPORTED_MEDIA_TYPES, MAX_EVIDENCE_BYTES

UPLOAD_DIR = Path(__file__).resolve().parents[3] / "uploads" / "evidence"

from fastapi import APIRouter, Depends, HTTPException, status
from starlette.datastructures import UploadFile
from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from app.core.dependencies import get_current_user
from app.db.session import get_db
from app.ai.classifier import ClassifierUnavailable
from app.ai.service import ComplaintAnalysisService
from app.models import AIAnalysis, Complaint, User, Verification
from app.schemas.phase5 import (
    CitizenComplaintResponse,
    ComplaintCreateRequest,
    ComplaintCreateResponse,
    VerificationRequest,
    VerificationResponse,
)
from app.services.notifications import NotificationEvent, NotificationService
from app.services.verification import VerificationService

router = APIRouter(prefix="/complaints", tags=["citizen-verification"])
verification_service = VerificationService()
analysis_service = ComplaintAnalysisService()
notification_service = NotificationService()


def complaint_response(complaint: Complaint, analysis: AIAnalysis | None) -> CitizenComplaintResponse:
    return CitizenComplaintResponse(
        complaint_id=complaint.id,
        complaint_text=complaint.text,
        status=complaint.status,
        language=complaint.language,
        created_at=complaint.created_at,
        category=analysis.category if analysis else None,
        severity=analysis.severity if analysis else None,
        priority_level=analysis.priority_level if analysis else None,
        priority_score=analysis.priority_score if analysis else None,
        lane=complaint.lane,
        lane_number=complaint.lane_number,
        exact_location=complaint.exact_location,
        area=complaint.area,
    )


@router.get("", response_model=list[CitizenComplaintResponse])
def list_citizen_complaints(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list[CitizenComplaintResponse]:
    complaints = db.scalars(
        select(Complaint)
        .where(Complaint.user_id == current_user.id)
        .order_by(desc(Complaint.created_at), desc(Complaint.id))
    ).all()
    return [
        complaint_response(
            complaint,
            db.scalar(
                select(AIAnalysis)
                .where(AIAnalysis.complaint_id == complaint.id)
                .order_by(desc(AIAnalysis.analysis_timestamp))
                .limit(1)
            ),
        )
        for complaint in complaints
    ]


@router.get("/{complaint_id}", response_model=CitizenComplaintResponse)
def get_citizen_complaint(
    complaint_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> CitizenComplaintResponse:
    complaint = db.get(Complaint, complaint_id)
    if complaint is None or complaint.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Complaint not found")
    analysis = db.scalar(
        select(AIAnalysis)
        .where(AIAnalysis.complaint_id == complaint.id)
        .order_by(desc(AIAnalysis.analysis_timestamp))
        .limit(1)
    )
    return complaint_response(complaint, analysis)


@router.post("", response_model=ComplaintCreateResponse, status_code=status.HTTP_201_CREATED)
def submit_complaint(
    payload: ComplaintCreateRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ComplaintCreateResponse:
    if payload.evidence_media_type or payload.evidence_size_bytes:
        evidence = analysis_service.evidence.analyze(payload.evidence_media_type, payload.evidence_size_bytes)
        if evidence.status == "invalid":
            raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=evidence.message)
    complaint = Complaint(
        text=payload.complaint_text,
        language=payload.language.strip().lower(),
        user_id=current_user.id,
        village_id=current_user.village_id,
        affected_people=payload.affected_people,
        location_importance=payload.location_importance,
        lane=payload.lane,
        lane_number=payload.lane_number,
        exact_location=payload.exact_location,
        area=payload.area,
        latitude=payload.latitude,
        longitude=payload.longitude,
        evidence_url=payload.evidence_url,
    )
    db.add(complaint)
    db.flush()
    try:
        outcome = analysis_service.analyze(
            db=db,
            text=complaint.text,
            language=complaint.language,
            complaint_id=complaint.id,
            affected_people=complaint.affected_people,
            location_importance=complaint.location_importance,
            evidence_media_type=payload.evidence_media_type,
            evidence_size_bytes=payload.evidence_size_bytes,
        )
        analysis = outcome.analysis
        complaint.assigned_department = analysis.recommended_department
        notification_service.notify(
            db,
            user_id=current_user.id,
            complaint_id=complaint.id,
            notification_type=NotificationEvent.COMPLAINT_SUBMITTED,
            message=(
                f"Complaint #{complaint.id} was analyzed and routed to "
                f"{complaint.assigned_department}."
            ),
        )
        db.commit()
        return ComplaintCreateResponse(complaint_id=complaint.id, status=complaint.status, analysis_id=analysis.id)
    except ClassifierUnavailable as error:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=str(error)) from error


@router.get("/{complaint_id}/verification", response_model=VerificationResponse)
def get_verification(
    complaint_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> VerificationResponse:
    complaint = db.get(Complaint, complaint_id)
    if complaint is None or complaint.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Complaint not found")
    verification = db.scalar(
        select(Verification)
        .where(Verification.complaint_id == complaint_id, Verification.user_id == current_user.id)
        .order_by(desc(Verification.requested_at))
        .limit(1)
    )
    if verification is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Verification request not found")
    return verification


@router.post("/{complaint_id}/verification", response_model=VerificationResponse)
def verify_resolution(
    complaint_id: int,
    payload: VerificationRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> VerificationResponse:
    complaint = db.get(Complaint, complaint_id)
    if complaint is None or complaint.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Complaint not found")
    try:
        verification = verification_service.respond(
            db=db,
            complaint=complaint,
            user=current_user,
            solved=payload.solved,
            reason=payload.reason,
        )
        db.commit()
        db.refresh(verification)
        return verification
    except ValueError as error:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(error)) from error
    except PermissionError as error:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=str(error)) from error


@router.post("/{complaint_id}/evidence")
async def upload_complaint_evidence(
    complaint_id: int,
    request: Request,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    complaint = db.get(Complaint, complaint_id)
    if complaint is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Complaint not found")
    if complaint.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: You are not authorized to upload evidence for another citizen's complaint",
        )

    content_type = (request.headers.get("content-type") or "").strip().lower()
    content_length = request.headers.get("content-length")
    if content_length == "0":
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Uploaded file is empty.")

    filename = None
    media_type = None
    file_bytes = None
    if "application/json" in content_type:
        try:
            body = await request.body()
            if not body:
                raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Uploaded file is empty.")
            data = json.loads(body.decode("utf-8"))
            filename = data.get("filename", "upload.jpg")
            media_type = (data.get("media_type") or data.get("content_type") or "").strip().lower()
            if media_type and media_type not in SUPPORTED_MEDIA_TYPES:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail=f"Unsupported media type '{media_type}'. Supported formats: JPEG, PNG, MP4, QuickTime (MOV).",
                )
            b64_data = data.get("data") or data.get("content_base64")
            if not b64_data:
                raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Uploaded file is empty.")
            if len(b64_data) > ((MAX_EVIDENCE_BYTES + 2) // 3) * 4:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail="File size exceeds the 50 MB limit.",
                )
            file_bytes = base64.b64decode(b64_data, validate=True)
        except HTTPException:
            raise
        except (
            binascii.Error,
            UnicodeDecodeError,
            json.JSONDecodeError,
            AttributeError,
            TypeError,
        ) as error:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Invalid JSON evidence payload.",
            ) from error
    elif "multipart/form-data" in content_type:
        form = await request.form()
        upload = form.get("file")
        if not isinstance(upload, UploadFile):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Multipart request must include a file field named 'file'.",
            )
        filename = upload.filename
        media_type = (upload.content_type or "").split(";")[0].strip().lower()
        file_bytes = await upload.read(MAX_EVIDENCE_BYTES + 1)
        await upload.close()
    else:
        chunks = bytearray()
        async for chunk in request.stream():
            chunks.extend(chunk)
            if len(chunks) > MAX_EVIDENCE_BYTES:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail="File size exceeds the 50 MB limit.",
                )
        file_bytes = bytes(chunks)
        filename = request.headers.get("x-filename") or "evidence.jpg"
        media_type = content_type.split(";")[0].strip()

    if not file_bytes:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Uploaded file is empty.")
    if len(file_bytes) > MAX_EVIDENCE_BYTES:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="File size exceeds the 50 MB limit.",
        )

    filename = Path(filename or "evidence.jpg").name
    if not media_type or media_type == "application/octet-stream":
        guessed, _ = mimetypes.guess_type(filename)
        media_type = (guessed or "").lower()

    if media_type not in SUPPORTED_MEDIA_TYPES:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Unsupported media type '{media_type}'. Supported formats: JPEG, PNG, MP4, QuickTime (MOV).",
        )

    extension_by_type = {
        "image/jpeg": ".jpg",
        "image/png": ".png",
        "video/mp4": ".mp4",
        "video/quicktime": ".mov",
    }
    safe_filename = f"evidence_{complaint_id}_{uuid.uuid4().hex}{extension_by_type[media_type]}"
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    file_path = UPLOAD_DIR / safe_filename
    file_path.write_bytes(file_bytes)

    previous_url = complaint.evidence_url
    complaint.evidence_url = f"/officer/complaints/{complaint_id}/evidence/{safe_filename}"

    analysis = db.scalar(
        select(AIAnalysis)
        .where(AIAnalysis.complaint_id == complaint_id)
        .order_by(desc(AIAnalysis.analysis_timestamp))
        .limit(1)
    )
    if analysis:
        analysis.evidence_status = "provided"

    try:
        db.commit()
        db.refresh(complaint)
    except Exception:
        db.rollback()
        file_path.unlink(missing_ok=True)
        raise

    if previous_url:
        previous_file = UPLOAD_DIR / Path(previous_url).name
        if previous_file != file_path:
            previous_file.unlink(missing_ok=True)

    return {
        "complaint_id": complaint.id,
        "evidence_url": complaint.evidence_url,
        "filename": safe_filename,
        "media_type": media_type,
        "size_bytes": len(file_bytes),
    }


@router.get("/{complaint_id}/evidence/{filename}")
def get_citizen_evidence_file(
    complaint_id: int,
    filename: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> FileResponse:
    complaint = db.get(Complaint, complaint_id)
    if complaint is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Evidence file not found")
    if complaint.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: You are not authorized to view evidence for another citizen's complaint",
        )
    safe_name = Path(filename).name
    if not complaint.evidence_url or Path(complaint.evidence_url).name != safe_name:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Evidence file not found")
    file_path = UPLOAD_DIR / safe_name
    if not file_path.is_file():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Evidence file not found")
    content_type, _ = mimetypes.guess_type(str(file_path))
    return FileResponse(
        path=file_path,
        media_type=content_type or "application/octet-stream",
        headers={"Content-Disposition": "inline"},
    )
