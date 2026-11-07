import os

os.environ["DATABASE_URL"] = "sqlite:///./test_smart_village.db"
if os.path.exists("test_smart_village.db"):
    os.remove("test_smart_village.db")

from fastapi.testclient import TestClient

from app.core.security import hash_password
from app.db.session import SessionLocal
from app.main import app
from app.models import User, Village
from app.schemas.phase5 import ComplaintCreateRequest


def test_health_check() -> None:
    with TestClient(app) as client:
        response = client.get("/api/v1/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok", "database": "connected"}


def test_cors_allows_flutter_web_dev_server_port() -> None:
    origin = "http://localhost:61377"
    lan_origin = "http://192.168.1.25:61377"
    with TestClient(app) as client:
        response = client.options(
            "/api/v1/auth/login",
            headers={
                "Origin": origin,
                "Access-Control-Request-Method": "POST",
                "Access-Control-Request-Headers": "content-type",
            },
        )
        external_response = client.options(
            "/api/v1/auth/login",
            headers={
                "Origin": "https://example.com",
                "Access-Control-Request-Method": "POST",
                "Access-Control-Request-Headers": "content-type",
            },
        )
        lan_response = client.options(
            "/api/v1/auth/login",
            headers={
                "Origin": lan_origin,
                "Access-Control-Request-Method": "POST",
                "Access-Control-Request-Headers": "content-type",
            },
        )

    assert response.status_code == 200
    assert response.headers["access-control-allow-origin"] == origin
    assert lan_response.status_code == 200
    assert lan_response.headers["access-control-allow-origin"] == lan_origin
    assert external_response.status_code == 400


def test_register_and_login() -> None:
    email = "test@example.com"
    with TestClient(app) as client:
        with SessionLocal() as db:
            db.add(Village(name="Demo Village", district="Pune"))
            db.commit()

        register_response = client.post(
            "/api/v1/auth/register",
            json={
                "full_name": "Test Villager",
                "email": email,
                "password": "strong-password",
                "village": {"name": "Demo Village", "district": "Pune"},
            },
        )
        assert register_response.status_code == 201
        assert register_response.json()["token_type"] == "bearer"
        assert register_response.json()["user"]["role"] == "villager"

        second_register_response = client.post(
            "/api/v1/auth/register",
            json={
                "full_name": "Second Test Villager",
                "email": "second-test@example.com",
                "password": "strong-password",
                "village": {"name": " demo village ", "district": "pUNE"},
            },
        )
        assert second_register_response.status_code == 201
        assert (
            second_register_response.json()["user"]["village_id"]
            == register_response.json()["user"]["village_id"]
        )

        unknown_village_response = client.post(
            "/api/v1/auth/register",
            json={
                "full_name": "Villager with Typo",
                "email": "unknown-village@example.com",
                "password": "strong-password",
                "village": {"name": "Demo Villag", "district": "Pune"},
            },
        )
        assert unknown_village_response.status_code == 422

        login_response = client.post(
            "/api/v1/auth/login",
            json={"email": email, "password": "strong-password"},
        )
        assert login_response.status_code == 200
        token = login_response.json()["access_token"]
        assert token

        profile_response = client.get(
            "/users/me",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert profile_response.status_code == 200
        assert profile_response.json()["email"] == email

        unauthorized_response = client.get("/users/me")
        assert unauthorized_response.status_code == 401


def test_officer_registration_requires_admin_approval() -> None:
    with TestClient(app) as client:
        with SessionLocal() as db:
            village = Village(name="Officer Signup Village", district="Satara")
            admin = User(
                full_name="Signup Admin",
                email="signup-admin@example.com",
                password_hash=hash_password("admin-password"),
                role="admin",
                is_active=True,
            )
            db.add_all([village, admin])
            db.flush()
            village_id = village.id
            db.commit()

        assert "Satara" in client.get("/auth/districts").json()
        villages = client.get("/auth/villages?district=Satara")
        assert villages.status_code == 200
        assert any(
            village["id"] == village_id
            and village["name"] == "Officer Signup Village"
            and village["district"] == "Satara"
            and village["taluka"] is None
            for village in villages.json()
        )

        registration = client.post(
            "/auth/register-officer",
            json={
                "full_name": "New Officer",
                "email": "new-officer@example.com",
                "password": "officer-password",
                "village_id": village_id,
            },
        )
        assert registration.status_code == 202
        assert "approve" in registration.json()["message"]

        pending_login = client.post(
            "/auth/login",
            json={"email": "new-officer@example.com", "password": "officer-password"},
        )
        assert pending_login.status_code == 403
        assert "pending" in pending_login.json()["detail"].lower()

        pending_unauthenticated = client.get("/auth/pending-officers")
        assert pending_unauthenticated.status_code == 401

        admin_login = client.post(
            "/auth/login",
            json={"email": "signup-admin@example.com", "password": "admin-password"},
        )
        admin_headers = {
            "Authorization": f"Bearer {admin_login.json()['access_token']}"
        }
        pending = client.get("/auth/pending-officers", headers=admin_headers)
        assert pending.status_code == 200
        assert len(pending.json()) == 1
        assert pending.json()[0]["village"] == "Officer Signup Village"

        approval = client.post(
            f"/auth/officers/{pending.json()[0]['id']}/approve",
            headers=admin_headers,
        )
        assert approval.status_code == 200
        assert approval.json()["role"] == "village_officer"

        active_login = client.post(
            "/auth/login",
            json={"email": "new-officer@example.com", "password": "officer-password"},
        )
        assert active_login.status_code == 200


def test_complaint_create_request_accepts_location_details() -> None:
    payload = ComplaintCreateRequest(
        complaint_text="Road repair needed near lane 2",
        language="marathi",
        lane="Main road",
        lane_number="2",
        exact_location="Opposite Ganesh Temple, near market",
        area="Central village",
    )

    assert payload.lane == "Main road"
    assert payload.lane_number == "2"
    assert payload.exact_location == "Opposite Ganesh Temple, near market"
    assert payload.area == "Central village"
