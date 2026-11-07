import os
import sys
import uuid
from pathlib import Path

os.environ["DATABASE_URL"] = "sqlite:///./test_village_auth.db"
if os.path.exists("test_village_auth.db"):
    try:
        os.remove("test_village_auth.db")
    except Exception:
        pass

backend_dir = str(Path(__file__).resolve().parents[1])
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from fastapi.testclient import TestClient
from sqlalchemy import select

from app.core.security import hash_password
from app.db.init_db import init_db
from app.db.session import SessionLocal
from app.main import app
from app.models import AIAnalysis, Complaint, User, Village

UPLOAD_DIR = Path(__file__).resolve().parents[1] / "uploads" / "evidence"


def seed_two_villages_data():
    init_db()
    suffix = uuid.uuid4().hex[:6]
    pwd = "password123"

    with SessionLocal() as db:
        # Village 1: Wagholi in Haveli, Pune
        v1 = db.scalar(
            select(Village).where(
                Village.name == "Wagholi",
                Village.district == "Pune",
            )
        )
        if not v1:
            v1 = Village(
                name=f"Wagholi_{suffix}",
                district="Pune",
                taluka="Haveli",
                latitude=18.5793,
                longitude=73.9822,
                boundary_radius_km=4.5,
            )
            db.add(v1)
            db.flush()

        # Village 2: Malegaon Budruk in Baramati, Pune (or Ghoti in Nashik)
        v2 = db.scalar(
            select(Village).where(
                Village.name == "Ghoti",
                Village.district == "Nashik",
            )
        )
        if not v2:
            v2 = Village(
                name=f"Ghoti_{suffix}",
                district="Nashik",
                taluka="Igatpuri",
                latitude=19.7214,
                longitude=73.6667,
                boundary_radius_km=3.5,
            )
            db.add(v2)
            db.flush()

        # Officer 1 for Village 1
        off1_email = f"off1_{suffix}@test.example"
        officer1 = User(
            full_name="Officer Wagholi",
            email=off1_email,
            password_hash=hash_password(pwd),
            role="village_officer",
            village_id=v1.id,
        )

        # Officer 2 for Village 2
        off2_email = f"off2_{suffix}@test.example"
        officer2 = User(
            full_name="Officer Ghoti",
            email=off2_email,
            password_hash=hash_password(pwd),
            role="village_officer",
            village_id=v2.id,
        )

        # Citizen 1 in Village 1
        cit1_email = f"cit1_{suffix}@test.example"
        citizen1 = User(
            full_name="Citizen Wagholi",
            email=cit1_email,
            password_hash=hash_password(pwd),
            role="villager",
            village_id=v1.id,
        )

        # Citizen 2 in Village 2
        cit2_email = f"cit2_{suffix}@test.example"
        citizen2 = User(
            full_name="Citizen Ghoti",
            email=cit2_email,
            password_hash=hash_password(pwd),
            role="villager",
            village_id=v2.id,
        )

        # Admin
        admin_email = f"admin_{suffix}@test.example"
        admin = User(
            full_name="Zilla Admin",
            email=admin_email,
            password_hash=hash_password(pwd),
            role="admin",
        )

        db.add_all([officer1, officer2, citizen1, citizen2, admin])
        db.flush()

        # Complaint 1 in Village 1 (owned by citizen 1)
        c1 = Complaint(
            text="Wagholi water pipeline damaged",
            language="marathi",
            village_id=v1.id,
            user_id=citizen1.id,
            status="Pending",
            assigned_department="Water Supply",
            assigned_officer_id=officer1.id,
        )
        # Complaint 2 in Village 2 (owned by citizen 2)
        c2 = Complaint(
            text="Ghoti street light broken",
            language="marathi",
            village_id=v2.id,
            user_id=citizen2.id,
            status="Pending",
            assigned_department="Electricity",
            assigned_officer_id=officer2.id,
        )
        db.add_all([c1, c2])
        db.flush()

        db.add_all([
            AIAnalysis(
                complaint_id=c1.id,
                category="Water",
                confidence=0.88,
                severity="High",
                severity_explanation="Water pipeline leak reported.",
                priority_score=75,
                priority_level="High",
                priority_explanation="Direct impact on village households.",
                recommended_department="Water Supply",
            ),
            AIAnalysis(
                complaint_id=c2.id,
                category="Electricity",
                confidence=0.82,
                severity="Medium",
                severity_explanation="Streetlight failure.",
                priority_score=50,
                priority_level="Medium",
                priority_explanation="Local area lighting issue.",
                recommended_department="Electricity",
            ),
        ])
        db.commit()

        v1_id, v2_id = v1.id, v2.id
        c1_id, c2_id = c1.id, c2.id

    return {
        "v1_id": v1_id,
        "v2_id": v2_id,
        "c1_id": c1_id,
        "c2_id": c2_id,
        "off1": (off1_email, pwd),
        "off2": (off2_email, pwd),
        "cit1": (cit1_email, pwd),
        "cit2": (cit2_email, pwd),
        "admin": (admin_email, pwd),
    }


def login_hdr(client: TestClient, email: str, pwd: str) -> dict[str, str]:
    r = client.post("/auth/login", json={"email": email, "password": pwd})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def test_cross_village_complaint_access_blocked_with_403():
    data = seed_two_villages_data()
    with TestClient(app) as client:
        off1_hdr = login_hdr(client, *data["off1"])
        off2_hdr = login_hdr(client, *data["off2"])
        admin_hdr = login_hdr(client, *data["admin"])

        c1_id = data["c1_id"]
        c2_id = data["c2_id"]

        # Officer 1 views Complaint 1 in their own village -> 200 OK
        r1 = client.get(f"/officer/complaints/{c1_id}", headers=off1_hdr)
        assert r1.status_code == 200
        assert r1.json()["id"] == c1_id

        # Officer 1 attempts to inspect Complaint 2 in Village 2 -> 403 Forbidden!
        r_cross = client.get(f"/officer/complaints/{c2_id}", headers=off1_hdr)
        assert r_cross.status_code == 403
        assert "Forbidden" in r_cross.json()["detail"]

        # Officer 2 views Complaint 2 in their own village -> 200 OK
        r2 = client.get(f"/officer/complaints/{c2_id}", headers=off2_hdr)
        assert r2.status_code == 200

        # Officer 2 attempts to inspect Complaint 1 in Village 1 -> 403 Forbidden!
        r2_cross = client.get(f"/officer/complaints/{c1_id}", headers=off2_hdr)
        assert r2_cross.status_code == 403

        # Admin can inspect both complaints globally -> 200 OK
        assert client.get(f"/officer/complaints/{c1_id}", headers=admin_hdr).status_code == 200
        assert client.get(f"/officer/complaints/{c2_id}", headers=admin_hdr).status_code == 200


def test_cross_village_mutations_blocked_with_403():
    data = seed_two_villages_data()
    with TestClient(app) as client:
        off1_hdr = login_hdr(client, *data["off1"])
        admin_hdr = login_hdr(client, *data["admin"])
        c2_id = data["c2_id"]

        # 1. Status update lockout
        res = client.patch(
            f"/officer/complaints/{c2_id}/status",
            headers=off1_hdr,
            json={"status": "In Progress", "action_notes": "Unauthorized modification attempt."},
        )
        assert res.status_code == 403

        # 2. Assignment lockout
        res = client.patch(
            f"/officer/complaints/{c2_id}/assignment",
            headers=off1_hdr,
            json={"assigned_department": "Water Supply"},
        )
        assert res.status_code == 403

        # 3. Work order lockout
        res = client.post(
            f"/officer/complaints/{c2_id}/work-order",
            headers=off1_hdr,
            json={"action": "accept", "reason": "Unauthorized WO accept."},
        )
        assert res.status_code == 403

        # 4. AI override lockout
        res = client.post(
            f"/officer/complaints/{c2_id}/ai-override",
            headers=off1_hdr,
            json={"corrected_category": "Roads", "corrected_severity": "Critical", "override_reason": "Hack"},
        )
        assert res.status_code == 403

        # 5. Admin can update complaint 2 legitimately -> 200 OK
        admin_res = client.patch(
            f"/officer/complaints/{c2_id}/status",
            headers=admin_hdr,
            json={"status": "In Progress", "action_notes": "Zilla admin legitimate update."},
        )
        assert admin_res.status_code == 200
        assert admin_res.json()["status"] == "In Progress"


def test_cross_village_evidence_streaming_blocked_with_403():
    data = seed_two_villages_data()
    c1_id = data["c1_id"]
    c2_id = data["c2_id"]

    # Create dummy evidence files
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    f1_name = f"evidence_{c1_id}_test1.jpg"
    f2_name = f"evidence_{c2_id}_test2.jpg"
    (UPLOAD_DIR / f1_name).write_bytes(b"\xFF\xD8\xFF\xE0\x00\x10JFIFdummy1")
    (UPLOAD_DIR / f2_name).write_bytes(b"\xFF\xD8\xFF\xE0\x00\x10JFIFdummy2")

    with SessionLocal() as db:
        c1 = db.get(Complaint, c1_id)
        c2 = db.get(Complaint, c2_id)
        c1.evidence_url = f"/officer/complaints/{c1_id}/evidence/{f1_name}"
        c2.evidence_url = f"/officer/complaints/{c2_id}/evidence/{f2_name}"
        db.commit()

    with TestClient(app) as client:
        off1_hdr = login_hdr(client, *data["off1"])
        off2_hdr = login_hdr(client, *data["off2"])
        cit1_hdr = login_hdr(client, *data["cit1"])
        cit2_hdr = login_hdr(client, *data["cit2"])
        admin_hdr = login_hdr(client, *data["admin"])

        # 1. Officer 1 streaming evidence for own village complaint -> 200 OK
        r = client.get(f"/officer/complaints/{c1_id}/evidence/{f1_name}", headers=off1_hdr)
        assert r.status_code == 200

        # 2. Officer 1 streaming evidence for other village complaint -> 403 Forbidden!
        r_cross = client.get(f"/officer/complaints/{c2_id}/evidence/{f2_name}", headers=off1_hdr)
        assert r_cross.status_code == 403

        # 3. Citizen 1 streaming evidence for own complaint -> 200 OK
        r = client.get(f"/complaints/{c1_id}/evidence/{f1_name}", headers=cit1_hdr)
        assert r.status_code == 200

        # 4. Citizen 2 streaming evidence for citizen 1's complaint -> 403 Forbidden!
        r_cit_cross = client.get(f"/complaints/{c1_id}/evidence/{f1_name}", headers=cit2_hdr)
        assert r_cit_cross.status_code == 403

        # 5. Citizen 2 attempting to upload evidence to citizen 1's complaint -> 403 Forbidden!
        r_cit_upload = client.post(
            f"/complaints/{c1_id}/evidence",
            headers={**cit2_hdr, "Content-Type": "application/json"},
            json={"filename": "hacked.jpg", "media_type": "image/jpeg", "data": "dGVzdA=="},
        )
        assert r_cit_upload.status_code == 403

        # 6. Admin can stream any evidence -> 200 OK
        assert client.get(f"/officer/complaints/{c1_id}/evidence/{f1_name}", headers=admin_hdr).status_code == 200
        assert client.get(f"/officer/complaints/{c2_id}/evidence/{f2_name}", headers=admin_hdr).status_code == 200


def test_officer_parameter_tampering_blocked_with_403():
    data = seed_two_villages_data()
    v2_id = data["v2_id"]

    with TestClient(app) as client:
        off1_hdr = login_hdr(client, *data["off1"])
        admin_hdr = login_hdr(client, *data["admin"])

        # Officer 1 attempting to tamper with village_id param
        assert client.get(f"/officer/dashboard?village_id={v2_id}", headers=off1_hdr).status_code == 403
        assert client.get(f"/officer/complaints?village_id={v2_id}", headers=off1_hdr).status_code == 403
        assert client.get(f"/officer/analytics?village_id={v2_id}", headers=off1_hdr).status_code == 403
        assert client.get(f"/officer/reports/summary?village_id={v2_id}", headers=off1_hdr).status_code == 403
        assert client.get(f"/officer/reports/export-complaints-csv?village_id={v2_id}", headers=off1_hdr).status_code == 403

        # Officer 1 attempting to view all villages
        assert client.get("/officer/dashboard?all_villages=true", headers=off1_hdr).status_code == 403
        assert client.get("/officer/analytics?all_villages=true", headers=off1_hdr).status_code == 403

        # Officer 1 attempting to view another district
        assert client.get("/officer/dashboard?district=Nashik", headers=off1_hdr).status_code == 403

        # Admin CAN use all these query parameters legally
        assert client.get(f"/officer/dashboard?village_id={v2_id}", headers=admin_hdr).status_code == 200
        assert client.get("/officer/dashboard?all_villages=true", headers=admin_hdr).status_code == 200
        assert client.get("/officer/dashboard?district=Nashik", headers=admin_hdr).status_code == 200
        assert client.get("/officer/reports/summary?all_villages=true", headers=admin_hdr).status_code == 200
