from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models import User, Village


def selected_village_ids(
    db: Session,
    current_user: User,
    village_id: int | None,
    district: str | None,
    all_villages: bool,
    taluka: str | None = None,
) -> list[int] | None:
    # 1. Admin users have global unrestricted access across Maharashtra
    if current_user.role == "admin":
        if village_id is not None:
            village = db.get(Village, village_id)
            if village is None:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Village not found",
                )
            if district and village.district.casefold() != district.strip().casefold():
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail="Selected village does not belong to the selected district",
                )
            if taluka and (village.taluka or "").casefold() != taluka.strip().casefold():
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail="Selected village does not belong to the selected taluka",
                )
            return [village.id]

        if district or taluka:
            query = select(Village.id)
            if district:
                query = query.where(func.lower(Village.district) == district.strip().lower())
            if taluka:
                query = query.where(func.lower(Village.taluka) == taluka.strip().lower())
            return list(db.scalars(query.order_by(Village.name, Village.id)).all())

        # By default (or with all_villages=True), admin views all villages
        return None

    # 2. Regular Village Officers are strictly locked to their assigned village
    if current_user.village_id is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: You are not assigned to any village",
        )

    assigned_village = db.get(Village, current_user.village_id)
    if assigned_village is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Assigned village does not exist",
        )

    # Check for unauthorized cross-village tampering attempts
    if all_villages:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Only administrators can view all villages",
        )

    if village_id is not None and village_id != current_user.village_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: You are not authorized to view or manage data for another village",
        )

    if district and district.strip().casefold() != assigned_village.district.casefold():
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: You are not authorized to access data outside your assigned district",
        )

    if taluka and (assigned_village.taluka or "").casefold() != taluka.strip().casefold():
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: You are not authorized to access data outside your assigned taluka",
        )

    return [current_user.village_id]
