import json
from pathlib import Path
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models import Village

DIRECTORY_JSON_PATH = Path(__file__).resolve().parents[1] / "db" / "maharashtra_directory.json"


def seed_maharashtra_directory(db: Session) -> dict[str, int]:
    """
    Seeds verified Maharashtra administrative hierarchy into the villages table.
    Preserves existing records and guarantees zero duplication.
    """
    if not DIRECTORY_JSON_PATH.is_file():
        return {"districts": 0, "talukas": 0, "villages_added": 0}

    with open(DIRECTORY_JSON_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    state_name = data.get("state", "Maharashtra")
    districts = data.get("districts", [])

    existing_villages = db.scalars(select(Village)).all()
    # Map (lower(name), lower(district)) -> Village
    lookup = {
        (v.name.strip().lower(), v.district.strip().lower()): v
        for v in existing_villages
    }

    added_count = 0
    updated_count = 0
    taluka_set = set()
    district_set = set()

    for d in districts:
        district_name = d["name"].strip()
        district_set.add(district_name)
        for t in d.get("talukas", []):
            taluka_name = t["name"].strip()
            taluka_set.add(f"{district_name}:{taluka_name}")
            for v_data in t.get("villages", []):
                v_name = v_data["name"].strip()
                key = (v_name.lower(), district_name.lower())

                if key in lookup:
                    # Update taluka / coordinates if missing
                    existing = lookup[key]
                    modified = False
                    if not existing.taluka or existing.taluka != taluka_name:
                        existing.taluka = taluka_name
                        modified = True
                    if existing.latitude is None and v_data.get("latitude"):
                        existing.latitude = v_data["latitude"]
                        modified = True
                    if existing.longitude is None and v_data.get("longitude"):
                        existing.longitude = v_data["longitude"]
                        modified = True
                    if existing.boundary_radius_km is None and v_data.get("boundary_radius_km"):
                        existing.boundary_radius_km = v_data["boundary_radius_km"]
                        modified = True
                    if modified:
                        updated_count += 1
                else:
                    new_village = Village(
                        name=v_name,
                        district=district_name,
                        taluka=taluka_name,
                        state=state_name,
                        latitude=v_data.get("latitude"),
                        longitude=v_data.get("longitude"),
                        boundary_radius_km=v_data.get("boundary_radius_km", 3.0),
                    )
                    db.add(new_village)
                    lookup[key] = new_village
                    added_count += 1

    db.commit()
    return {
        "districts": len(district_set),
        "talukas": len(taluka_set),
        "villages_added": added_count,
        "villages_updated": updated_count,
    }


def list_directory_districts(db: Session) -> list[str]:
    """Returns sorted unique district names."""
    rows = db.scalars(
        select(Village.district).distinct().order_by(Village.district)
    ).all()
    return [r for r in rows if r]


def list_directory_talukas(db: Session, district: str) -> list[str]:
    """Returns sorted unique talukas belonging to the given district."""
    rows = db.scalars(
        select(Village.taluka)
        .where(func.lower(Village.district) == district.strip().lower())
        .distinct()
        .order_by(Village.taluka)
    ).all()
    return [r for r in rows if r]


def list_directory_villages(
    db: Session,
    district: str | None = None,
    taluka: str | None = None,
) -> list[Village]:
    """Returns villages filtered by district and optionally taluka."""
    query = select(Village)
    if district:
        query = query.where(func.lower(Village.district) == district.strip().lower())
    if taluka:
        query = query.where(func.lower(Village.taluka) == taluka.strip().lower())
    return list(db.scalars(query.order_by(Village.name, Village.id)).all())


def add_directory_village(
    db: Session,
    name: str,
    district: str,
    taluka: str,
    latitude: float | None = None,
    longitude: float | None = None,
    boundary_radius_km: float = 3.0,
    state: str = "Maharashtra",
) -> Village:
    """Adds a new village record into the administrative directory."""
    existing = db.scalar(
        select(Village).where(
            func.lower(Village.name) == name.strip().lower(),
            func.lower(Village.district) == district.strip().lower(),
            func.lower(Village.taluka) == taluka.strip().lower(),
        )
    )
    if existing:
        return existing

    new_v = Village(
        name=name.strip(),
        district=district.strip(),
        taluka=taluka.strip(),
        state=state.strip(),
        latitude=latitude,
        longitude=longitude,
        boundary_radius_km=boundary_radius_km,
    )
    db.add(new_v)
    db.commit()
    db.refresh(new_v)
    return new_v
