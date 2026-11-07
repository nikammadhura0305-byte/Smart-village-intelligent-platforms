from sqlalchemy import select, text

from app.core.config import settings
from app.core.security import hash_password
from app.db.session import Base, SessionLocal, engine
from app.models import User, Village
from app.services.directory import seed_maharashtra_directory


def init_db() -> None:
    with engine.begin() as connection:
        Base.metadata.create_all(bind=connection)
        if connection.dialect.name == "sqlite":
            columns = connection.execute(text("PRAGMA table_info(complaints)")).fetchall()
            names = {column[1] for column in columns}
            for column_name in ("exact_location", "lane", "lane_number", "area"):
                if column_name not in names:
                    connection.execute(text(f"ALTER TABLE complaints ADD COLUMN {column_name} TEXT"))

            village_columns = connection.execute(text("PRAGMA table_info(villages)")).fetchall()
            v_names = {column[1] for column in village_columns}
            for column_name in ("latitude", "longitude", "boundary_radius_km"):
                if column_name not in v_names:
                    connection.execute(text(f"ALTER TABLE villages ADD COLUMN {column_name} FLOAT"))
            if "taluka" not in v_names:
                connection.execute(text("ALTER TABLE villages ADD COLUMN taluka VARCHAR(100)"))
            if "state" not in v_names:
                connection.execute(text("ALTER TABLE villages ADD COLUMN state VARCHAR(100) DEFAULT 'Maharashtra'"))
            connection.execute(
                text("CREATE INDEX IF NOT EXISTS ix_villages_taluka ON villages (taluka)")
            )

    with SessionLocal() as db:
        # Seed verified Maharashtra administrative hierarchy
        seed_maharashtra_directory(db)

        if settings.environment.lower() == "production":
            return

        existing_officer = db.scalar(select(User).where(User.email == "officer@example.com"))
        if existing_officer is not None:
            return

        village = db.scalar(select(Village).where(Village.name == "Demo Village", Village.district == "Pune"))
        if village is None:
            village = Village(name="Demo Village", district="Pune", taluka="Haveli", state="Maharashtra", latitude=18.5204, longitude=73.8567, boundary_radius_km=3.0)
            db.add(village)
            db.flush()
        elif village.taluka is None:
            village.taluka = "Haveli"
            db.commit()

        db.add(
            User(
                full_name="Village Officer",
                email="officer@example.com",
                password_hash=hash_password("change-this-password"),
                role="village_officer",
                village_id=village.id,
            )
        )
        db.commit()
