import os
import sys
import uuid
from pathlib import Path

# Set up test database environment before app imports
os.environ["DATABASE_URL"] = "sqlite:///./test_directory.db"
if os.path.exists("test_directory.db"):
    try:
        os.remove("test_directory.db")
    except Exception:
        pass

backend_dir = str(Path(__file__).resolve().parents[1])
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from fastapi.testclient import TestClient

from app.core.security import hash_password
from app.db.init_db import init_db
from app.db.session import SessionLocal
from app.main import app
from app.models import User, Village
from app.services.directory import (
    add_directory_village,
    list_directory_districts,
    list_directory_talukas,
    list_directory_villages,
    seed_maharashtra_directory,
)


def seed_test_users():
    suffix = uuid.uuid4().hex[:6]
    admin_email = f"admin_{suffix}@test.example"
    officer_email = f"officer_{suffix}@test.example"
    citizen_email = f"citizen_{suffix}@test.example"
    pwd = "password123"

    with SessionLocal() as db:
        # Get or create a village for the officer
        village = db.query(Village).first()
        village_id = village.id if village else None

        admin = User(
            full_name="Admin Officer",
            email=admin_email,
            password_hash=hash_password(pwd),
            role="admin",
            village_id=village_id,
        )
        officer = User(
            full_name="Regular Village Officer",
            email=officer_email,
            password_hash=hash_password(pwd),
            role="village_officer",
            village_id=village_id,
        )
        citizen = User(
            full_name="Citizen User",
            email=citizen_email,
            password_hash=hash_password(pwd),
            role="villager",
            village_id=village_id,
        )
        db.add_all([admin, officer, citizen])
        db.commit()

    return {
        "admin": (admin_email, pwd),
        "officer": (officer_email, pwd),
        "citizen": (citizen_email, pwd),
    }


def login_token(client: TestClient, email: str, pwd: str) -> str:
    res = client.post("/auth/login", json={"email": email, "password": pwd})
    assert res.status_code == 200, res.text
    return res.json()["access_token"]


def test_directory_seeding_and_hierarchy():
    init_db()
    with SessionLocal() as db:
        # Re-seeding must be idempotent (0 new villages added)
        reseed_stats = seed_maharashtra_directory(db)
        assert reseed_stats["districts"] >= 5
        assert reseed_stats["talukas"] >= 25
        assert reseed_stats["villages_added"] == 0

        # Check districts
        districts = list_directory_districts(db)
        for expected in ["Pune", "Kolhapur", "Satara", "Sangli", "Nashik"]:
            assert expected in districts

        # Check talukas for Pune
        pune_talukas = list_directory_talukas(db, "Pune")
        for expected_taluka in ["Haveli", "Baramati", "Maval", "Shirur", "Khed"]:
            assert expected_taluka in pune_talukas

        # Check villages under Haveli taluka
        haveli_villages = list_directory_villages(db, district="Pune", taluka="Haveli")
        assert len(haveli_villages) >= 4
        village_names = [v.name for v in haveli_villages]
        assert "Wagholi" in village_names or "Manjari Khurd" in village_names

        # Check coordinates and boundary radius
        v = haveli_villages[0]
        assert v.latitude is not None and 15.0 < v.latitude < 22.0
        assert v.longitude is not None and 72.0 < v.longitude < 81.0
        assert v.boundary_radius_km > 0.0


def test_public_auth_directory_endpoints():
    with TestClient(app) as client:
        # 1. GET /auth/districts
        r = client.get("/auth/districts")
        assert r.status_code == 200
        districts = r.json()
        assert "Pune" in districts
        assert "Kolhapur" in districts

        # 2. GET /auth/talukas?district=Kolhapur
        r = client.get("/auth/talukas?district=Kolhapur")
        assert r.status_code == 200
        talukas = r.json()
        assert "Karvir" in talukas
        assert "Panhala" in talukas

        # Missing district returns 422 or empty
        r = client.get("/auth/talukas")
        assert r.status_code == 422

        # 3. GET /auth/villages with cascading filters
        r = client.get("/auth/villages?district=Kolhapur&taluka=Karvir")
        assert r.status_code == 200
        villages = r.json()
        assert len(villages) >= 3
        for v in villages:
            assert v["district"] == "Kolhapur"
            assert v["taluka"] == "Karvir"
            assert "id" in v
            assert "name" in v


def test_officer_directory_endpoints_and_rbac():
    users = seed_test_users()

    with TestClient(app) as client:
        admin_token = login_token(client, users["admin"][0], users["admin"][1])
        officer_token = login_token(client, users["officer"][0], users["officer"][1])
        citizen_token = login_token(client, users["citizen"][0], users["citizen"][1])

        # 1. District listing via officer endpoint
        r = client.get(
            "/officer/districts",
            headers={"Authorization": f"Bearer {officer_token}"},
        )
        assert r.status_code == 200
        assert "Pune" in r.json()

        # 2. Taluka listing via officer endpoint
        r = client.get(
            "/officer/talukas?district=Satara",
            headers={"Authorization": f"Bearer {officer_token}"},
        )
        assert r.status_code == 200
        talukas = r.json()
        assert "Karad" in talukas or "Wai" in talukas

        # 3. Village listing via officer endpoint
        r = client.get(
            "/officer/villages?district=Satara",
            headers={"Authorization": f"Bearer {officer_token}"},
        )
        assert r.status_code == 200
        satara_villages = r.json()
        assert len(satara_villages) >= 1

        # 4. Adding a new village to the directory: Admin only
        new_village_payload = {
            "name": "Chincholi Budruk",
            "district": "Pune",
            "taluka": "Haveli",
            "latitude": 18.5912,
            "longitude": 73.9104,
            "boundary_radius_km": 3.5,
        }

        # Citizen forbidden (403)
        r = client.post(
            "/officer/directory/villages",
            json=new_village_payload,
            headers={"Authorization": f"Bearer {citizen_token}"},
        )
        assert r.status_code == 403

        # Regular officer forbidden (403)
        r = client.post(
            "/officer/directory/villages",
            json=new_village_payload,
            headers={"Authorization": f"Bearer {officer_token}"},
        )
        assert r.status_code == 403

        # Admin authorized (201 Created)
        r = client.post(
            "/officer/directory/villages",
            json=new_village_payload,
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert r.status_code == 201
        created = r.json()
        assert created["name"] == "Chincholi Budruk"
        assert created["district"] == "Pune"
        assert created["taluka"] == "Haveli"

        # 5. Admin directory reseed endpoint
        r = client.post(
            "/officer/directory/seed",
            headers={"Authorization": f"Bearer {officer_token}"},
        )
        assert r.status_code == 403

        r = client.post(
            "/officer/directory/seed",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert r.status_code == 200
        assert "districts" in r.json()
