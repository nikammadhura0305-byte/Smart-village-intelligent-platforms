from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.dependencies import require_admin
from app.core.security import create_access_token, hash_password, verify_password
from app.db.session import get_db
from app.models import User, Village
from app.schemas.auth import (
    LoginRequest,
    OfficerRegisterRequest,
    PendingOfficerResponse,
    RegisterRequest,
    TokenResponse,
    UserResponse,
    VillageOption,
)

router = APIRouter(prefix="/auth", tags=["authentication"])


@router.get("/districts", response_model=list[str])
def list_districts(db: Session = Depends(get_db)) -> list[str]:
    from app.services.directory import list_directory_districts
    return list_directory_districts(db)


@router.get("/talukas", response_model=list[str])
def list_talukas(
    district: str = Query(min_length=1),
    db: Session = Depends(get_db),
) -> list[str]:
    from app.services.directory import list_directory_talukas
    return list_directory_talukas(db, district)


@router.get("/villages", response_model=list[VillageOption])
def list_registration_villages(
    district: str = Query(min_length=1),
    taluka: str | None = Query(default=None),
    db: Session = Depends(get_db),
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


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, db: Session = Depends(get_db)) -> TokenResponse:
    existing_user = db.scalar(select(User).where(User.email == payload.email.lower()))
    if existing_user:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email is already registered")

    village_name = payload.village.name.strip()
    district = payload.village.district.strip()
    village = db.scalar(
        select(Village).where(
            func.lower(Village.name) == village_name.lower(),
            func.lower(Village.district) == district.lower(),
        )
    )
    if village is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Select a village registered by the Gram Panchayat",
        )

    user = User(
        full_name=payload.full_name,
        email=payload.email.lower(),
        password_hash=hash_password(payload.password),
        village=village,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    return TokenResponse(access_token=create_access_token(str(user.id)), user=UserResponse.model_validate(user))


@router.post("/register-officer", status_code=status.HTTP_202_ACCEPTED)
def register_officer(
    payload: OfficerRegisterRequest,
    db: Session = Depends(get_db),
) -> dict[str, str]:
    email = str(payload.email).strip().lower()
    if db.scalar(select(User).where(User.email == email)):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email is already registered",
        )

    village = db.get(Village, payload.village_id)
    if village is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Selected village was not found",
        )

    user = User(
        full_name=payload.full_name.strip(),
        email=email,
        password_hash=hash_password(payload.password),
        role="village_officer",
        is_active=False,
        village_id=village.id,
    )
    db.add(user)
    db.commit()
    return {"message": "Registration submitted. An administrator must approve your account."}


@router.get(
    "/pending-officers",
    response_model=list[PendingOfficerResponse],
    dependencies=[Depends(require_admin)],
)
def list_pending_officers(db: Session = Depends(get_db)) -> list[PendingOfficerResponse]:
    users = db.scalars(
        select(User)
        .where(User.role == "village_officer", User.is_active.is_(False))
        .order_by(User.created_at, User.id)
    ).all()
    return [
        PendingOfficerResponse(
            id=user.id,
            full_name=user.full_name,
            email=user.email,
            village=user.village.name if user.village else "Unknown village",
            district=user.village.district if user.village else "Unknown district",
        )
        for user in users
    ]


@router.post(
    "/officers/{officer_id}/approve",
    response_model=UserResponse,
    dependencies=[Depends(require_admin)],
)
def approve_officer(
    officer_id: int,
    db: Session = Depends(get_db),
) -> UserResponse:
    user = db.get(User, officer_id)
    if user is None or user.role != "village_officer":
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Pending officer was not found",
        )
    if user.is_active:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Officer account is already active",
        )
    user.is_active = True
    db.commit()
    db.refresh(user)
    return UserResponse.model_validate(user)


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> TokenResponse:
    user = db.scalar(select(User).where(User.email == payload.email.lower()))
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
    if not user.is_active:
        detail = (
            "Officer registration is pending administrator approval"
            if user.role == "village_officer"
            else "User account is inactive"
        )
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=detail)

    return TokenResponse(access_token=create_access_token(str(user.id)), user=UserResponse.model_validate(user))
