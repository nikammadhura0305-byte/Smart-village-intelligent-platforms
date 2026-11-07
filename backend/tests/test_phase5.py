from datetime import UTC, datetime, timedelta
import os

os.environ["DATABASE_URL"] = "sqlite:///./test_phase5.db"
if os.path.exists("test_phase5.db"):
    os.remove("test_phase5.db")

from fastapi.testclient import TestClient
from sqlalchemy import select

from app.core.security import hash_password
from app.db.session import SessionLocal
from app.main import app
from app.models import AIAnalysis, Complaint, Escalation, Notification, User, Village


def seed_data() -> tuple[int, int, int, int]:
    with SessionLocal() as db:
        village = Village(name="Verification Village", district="Pune")
        db.add(village)
        db.flush()
        officer = User(
            full_name="Verification Officer",
            email="phase5-officer@example.com",
            password_hash=hash_password("officer-password"),
            role="village_officer",
            village_id=village.id,
        )
        citizen = User(
            full_name="Verification Citizen",
            email="phase5-citizen@example.com",
            password_hash=hash_password("citizen-password"),
            role="villager",
            village_id=village.id,
        )
        db.add_all([officer, citizen])
        db.flush()
        complaints = [
            Complaint(text="Water supply is still unavailable", language="english", village_id=village.id, user_id=citizen.id, assigned_officer_id=officer.id, status="In Progress", latitude=18.5204, longitude=73.8567),
            Complaint(text="The repaired road is usable", language="english", village_id=village.id, user_id=citizen.id, assigned_officer_id=officer.id, status="In Progress"),
        ]
        db.add_all(complaints)
        db.flush()
        for complaint in complaints:
            db.add(
                AIAnalysis(
                    complaint_id=complaint.id,
                    category="Water" if complaint.id == complaints[0].id else "Roads",
                    confidence=0.8,
                    severity="High",
                    severity_explanation="Test severity",
                    priority_score=70,
                    priority_level="High",
                    priority_explanation="Test priority",
                    recommended_department="Water Department",
                )
            )
        db.commit()
        return officer.id, citizen.id, complaints[0].id, complaints[1].id


def token(client: TestClient, email: str, password: str) -> dict[str, str]:
    response = client.post("/auth/login", json={"email": email, "password": password})
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def test_verification_reopen_escalation_and_intelligence() -> None:
    with TestClient(app) as client:
        officer_id, citizen_id, reopen_id, close_id = seed_data()
        officer_headers = token(client, "phase5-officer@example.com", "officer-password")
        citizen_headers = token(client, "phase5-citizen@example.com", "citizen-password")

        with SessionLocal() as db:
            other_village = Village(name="Other Intelligence Village", district="Nashik")
            db.add(other_village)
            db.flush()
            other_officer = User(
                full_name="Other Intelligence Officer",
                email="other-phase5-officer@example.com",
                password_hash=hash_password("officer-password"),
                role="village_officer",
                village_id=other_village.id,
            )
            admin = User(
                full_name="Intelligence Admin",
                email="phase5-admin@example.com",
                password_hash=hash_password("admin-password"),
                role="admin",
            )
            db.add_all([other_officer, admin])
            db.flush()
            other_complaint = Complaint(
                text="A stale complaint belonging to another village",
                language="english",
                village_id=other_village.id,
                assigned_officer_id=other_officer.id,
                assigned_department="Other Village Department",
                status="Pending",
                latitude=19.0,
                longitude=74.0,
                created_at=datetime.now(UTC) - timedelta(days=10),
                repeated_complaints=8,
            )
            db.add(other_complaint)
            db.flush()
            other_complaint_id = other_complaint.id
            db.add(
                AIAnalysis(
                    complaint_id=other_complaint.id,
                    category="Other Village Category",
                    confidence=0.9,
                    severity="Critical",
                    severity_explanation="Other village data",
                    priority_score=90,
                    priority_level="Critical",
                    priority_explanation="Other village data",
                    recommended_department="Other Village Department",
                )
            )
            db.commit()

        submitted = client.post(
            "/complaints",
            headers=citizen_headers,
            json={
                "complaint_text": "The road near the village school is damaged",
                "language": "english",
                "affected_people": 10,
            },
        )
        assert submitted.status_code == 201
        assert submitted.json()["analysis_id"]
        submitted_complaint_id = submitted.json()["complaint_id"]
        submitted_detail = client.get(
            f"/officer/complaints/{submitted_complaint_id}",
            headers=officer_headers,
        )
        assert submitted_detail.status_code == 200
        submitted_fields = submitted_detail.json()
        assert submitted_fields["category"] == "Roads"
        assert submitted_fields["severity"] in {"Low", "Medium", "High", "Critical"}
        assert submitted_fields["priority_level"] in {"Low", "Medium", "High", "Critical"}
        assert submitted_fields["assigned_department"] == "Public Works/Road Department"
        assert submitted_fields["status"] == "Pending"
        assert submitted_fields["assigned_at"] is None

        submission_notifications = client.get("/notifications", headers=citizen_headers)
        assert any(
            item["notification_type"] == "complaint_submitted"
            and item["complaint_id"] == submitted_complaint_id
            for item in submission_notifications.json()
        )
        assert all(
            item["complaint_id"] != submitted_complaint_id
            for item in client.get("/notifications", headers=officer_headers).json()
        )
        assert client.get("/notifications").status_code == 401

        assignment = client.patch(
            f"/officer/complaints/{reopen_id}/assignment",
            headers=officer_headers,
            json={
                "assigned_department": "Water Department",
                "assigned_officer_id": officer_id,
            },
        )
        assert assignment.status_code == 200

        resolved = client.patch(
            f"/officer/complaints/{reopen_id}/status",
            headers=officer_headers,
            json={"status": "Resolved", "action_notes": "Water line repaired."},
        )
        assert resolved.status_code == 200

        verification = client.get(f"/complaints/{reopen_id}/verification", headers=citizen_headers)
        assert verification.status_code == 200
        assert verification.json()["response"] is None

        citizen_notifications = client.get("/notifications", headers=citizen_headers)
        officer_notifications = client.get("/notifications", headers=officer_headers)
        assert citizen_notifications.status_code == 200
        assert officer_notifications.status_code == 200
        assert any(
            item["notification_type"] == "status_changed"
            and item["complaint_id"] == reopen_id
            for item in citizen_notifications.json()
        )
        assert any(
            item["notification_type"] == "complaint_assigned"
            and item["complaint_id"] == reopen_id
            for item in officer_notifications.json()
        )
        assert any(
            item["notification_type"] == "status_changed"
            and item["complaint_id"] == reopen_id
            for item in officer_notifications.json()
        )

        rejected = client.post(
            f"/complaints/{reopen_id}/verification",
            headers=citizen_headers,
            json={"solved": False, "reason": "Water is still unavailable."},
        )
        assert rejected.status_code == 200
        with SessionLocal() as db:
            complaint = db.get(Complaint, reopen_id)
            assert complaint.status == "Reopened"
            assert db.scalar(select(Notification).where(Notification.complaint_id == reopen_id)) is not None

        resolved_again = client.patch(
            f"/officer/complaints/{close_id}/status",
            headers=officer_headers,
            json={"status": "Resolved"},
        )
        assert resolved_again.status_code == 200
        accepted = client.post(
            f"/complaints/{close_id}/verification",
            headers=citizen_headers,
            json={"solved": True},
        )
        assert accepted.status_code == 200
        with SessionLocal() as db:
            assert db.get(Complaint, close_id).status == "Closed"

        notifications = client.get("/notifications", headers=citizen_headers)
        assert notifications.status_code == 200
        assert any(item["notification_type"] == "verification_requested" for item in notifications.json())

        analytics = client.get("/officer/analytics", headers=officer_headers)
        assert analytics.status_code == 200
        assert analytics.json()["pending_complaints"] == 2
        assert any(point["complaint_id"] in {reopen_id, close_id} for point in analytics.json()["heat_map"])
        assert all(point["complaint_id"] != other_complaint_id for point in analytics.json()["heat_map"])
        assert "Other Village Department" not in analytics.json()["department_workload"]

        prediction = client.get("/officer/predictions/repeated-issues", headers=officer_headers)
        assert prediction.status_code == 200
        assert prediction.json()["status"] == "insufficient_data"
        assert prediction.json()["sample_count"] == 3

        report = client.get("/officer/reports/summary", headers=officer_headers)
        assert report.status_code == 200
        assert report.json()["summary"]["total"] == 3
        assert "Other Village Category" not in report.json()["complaints_by_category"]

        escalation_check = client.post("/officer/escalations/check", headers=officer_headers)
        assert escalation_check.status_code == 200
        assert escalation_check.json()["escalated_count"] == 0
        with SessionLocal() as db:
            assert db.scalar(
                select(Escalation).where(Escalation.complaint_id == other_complaint_id)
            ) is None

        admin_headers = token(client, "phase5-admin@example.com", "admin-password")
        admin_report = client.get("/officer/reports/summary", headers=admin_headers)
        assert admin_report.status_code == 200
        assert admin_report.json()["summary"]["total"] >= 4
        assert "Other Village Category" in admin_report.json()["complaints_by_category"]

        admin_escalation_check = client.post(
            "/officer/escalations/check",
            headers=admin_headers,
        )
        assert admin_escalation_check.status_code == 200
        assert admin_escalation_check.json()["escalated_count"] >= 1
        with SessionLocal() as db:
            assert db.scalar(
                select(Escalation).where(Escalation.complaint_id == other_complaint_id)
            ) is not None

        forbidden = client.get("/officer/analytics", headers=citizen_headers)
        assert forbidden.status_code == 403
