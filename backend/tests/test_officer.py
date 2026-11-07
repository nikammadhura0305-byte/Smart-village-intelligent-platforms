import os
from datetime import datetime

import sys
from pathlib import Path

os.environ.setdefault("DATABASE_URL", "sqlite:///./test_officer.db")
if os.environ["DATABASE_URL"].endswith("test_officer.db") and os.path.exists("test_officer.db"):
    os.remove("test_officer.db")

backend_dir = str(Path(__file__).resolve().parents[1])
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from sqlalchemy import select
from fastapi.testclient import TestClient

from app.core.security import hash_password
from app.db.session import SessionLocal
from app.main import app
from app.models import AIAnalysis, Complaint, User, Village


def seed_officer_data(email_suffix: str = "") -> tuple[int, int]:
    with SessionLocal() as db:
        village = Village(
            name="Officer Test Village",
            district="Pune",
            latitude=18.5204,
            longitude=73.8567,
            boundary_radius_km=2.0,
        )
        db.add(village)
        db.flush()
        officer = User(
            full_name="Village Officer",
            email=f"officer{email_suffix}@test.example",
            password_hash=hash_password("officer-password"),
            role="village_officer",
            village_id=village.id,
        )
        villager = User(
            full_name="Village Resident",
            email=f"villager{email_suffix}@test.example",
            password_hash=hash_password("villager-password"),
            role="villager",
            village_id=village.id,
        )
        db.add_all([officer, villager])
        db.flush()
        complaint = Complaint(
            text="The road near the school is damaged",
            language="english",
            village_id=village.id,
            status="Pending",
            exact_location="Lane 2, opposite the school, near the market",
            latitude=18.5204,
            longitude=73.8567,
            repeated_complaints=2,
        )
        outside_complaint = Complaint(
            text="Water line issue in a distant location",
            language="english",
            village_id=village.id,
            status="In Progress",
            exact_location="Distant outskirts",
            latitude=19.4334,
            longitude=75.1234,
            repeated_complaints=1,
        )
        db.add_all([complaint, outside_complaint])
        db.flush()
        db.add_all([
            AIAnalysis(
                complaint_id=complaint.id,
                category="Roads",
                confidence=0.82,
                severity="High",
                severity_explanation="School access is affected.",
                priority_score=72,
                priority_level="High",
                priority_explanation="High severity and repeated reports.",
                possible_duplicate=False,
                recommended_department="Public Works/Road Department",
            ),
            AIAnalysis(
                complaint_id=outside_complaint.id,
                category="Water",
                confidence=0.71,
                severity="Medium",
                severity_explanation="Service quality issue in the outskirts.",
                priority_score=52,
                priority_level="Medium",
                priority_explanation="Moderate severity and a single report.",
                possible_duplicate=False,
                recommended_department="Water Department",
            ),
        ])
        db.commit()
        return officer.id, villager.id


def login(client: TestClient, email: str, password: str) -> dict[str, str]:
    response = client.post("/auth/login", json={"email": email, "password": password})
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


def test_officer_management_and_role_restriction() -> None:
    with TestClient(app) as client:
        officer_id, _ = seed_officer_data()
        officer_headers = login(client, "officer@test.example", "officer-password")
        villager_headers = login(client, "villager@test.example", "villager-password")

        dashboard = client.get("/officer/dashboard", headers=officer_headers)
        assert dashboard.status_code == 200
        assert dashboard.json()["total_complaints"] == 2
        assert dashboard.json()["pending_complaints"] == 1
        assert dashboard.json()["in_progress_complaints"] == 1
        assert dashboard.json()["resolved_complaints"] == 0
        assert dashboard.json()["high_priority_complaints"] >= 1
        with SessionLocal() as db:
            other_village = Village(name="Other Village", district="Nashik")
            db.add(other_village)
            db.flush()
            other_village_id = other_village.id
            other_officer = User(
                full_name="Other Village Officer",
                email="other-officer@test.example",
                password_hash=hash_password("officer-password"),
                role="village_officer",
                village_id=other_village.id,
            )
            admin_user = User(
                full_name="System Admin",
                email="admin-scope@test.example",
                password_hash=hash_password("admin-password"),
                role="admin",
            )
            db.add_all([other_officer, admin_user])
            db.add(
                Complaint(
                    text="A complaint from another village",
                    language="english",
                    village_id=other_village.id,
                    status="Pending",
                )
            )
            db.commit()

        admin_headers = login(client, "admin-scope@test.example", "admin-password")

        villages = client.get("/officer/villages", headers=officer_headers)
        assert villages.status_code == 200
        assert "Other Village" in {
            village["name"]
            for village in villages.json()
            if village["district"] == "Nashik"
        }

        officer_directory = client.get("/officer/officers", headers=officer_headers)
        assert officer_directory.status_code == 200
        assert officer_id in [item["id"] for item in officer_directory.json()]

        # Phase 5: Regular officer is strictly locked out with 403 on cross-village tampering
        tamper_village = client.get(
            f"/officer/dashboard?village_id={other_village_id}&district=Nashik",
            headers=officer_headers,
        )
        assert tamper_village.status_code == 403

        tamper_district = client.get(
            "/officer/dashboard?district=Nashik",
            headers=officer_headers,
        )
        assert tamper_district.status_code == 403

        tamper_all = client.get(
            "/officer/dashboard?all_villages=true",
            headers=officer_headers,
        )
        assert tamper_all.status_code == 403

        # Admin CAN access cross-village dashboards and all villages (200 OK)
        other_village_dashboard = client.get(
            f"/officer/dashboard?village_id={other_village_id}&district=Nashik",
            headers=admin_headers,
        )
        assert other_village_dashboard.status_code == 200
        assert other_village_dashboard.json()["total_complaints"] == 1

        all_villages_dashboard = client.get(
            "/officer/dashboard?all_villages=true",
            headers=admin_headers,
        )
        assert all_villages_dashboard.status_code == 200
        assert all_villages_dashboard.json()["total_complaints"] >= 3

        other_village_complaints = client.get(
            f"/officer/complaints?village_id={other_village_id}&district=Nashik",
            headers=admin_headers,
        )
        assert other_village_complaints.status_code == 200
        assert len(other_village_complaints.json()) == 1
        other_complaint_id = other_village_complaints.json()[0]["id"]

        # Regular officer attempting to update other village's complaint gets 403
        blocked_cross_village_update = client.patch(
            f"/officer/complaints/{other_complaint_id}/status",
            headers=officer_headers,
            json={"status": "In Progress", "action_notes": "Officer started work."},
        )
        assert blocked_cross_village_update.status_code == 403

        # Admin CAN update cross-village complaint
        allowed_cross_village_update = client.patch(
            f"/officer/complaints/{other_complaint_id}/status?village_id={other_village_id}&district=Nashik",
            headers=admin_headers,
            json={"status": "In Progress", "action_notes": "Admin verified work."},
        )
        assert allowed_cross_village_update.status_code == 200
        assert allowed_cross_village_update.json()["status"] == "In Progress"

        dashboard_after_other_village = client.get("/officer/dashboard", headers=officer_headers)
        assert dashboard_after_other_village.json()["total_complaints"] == 2

        filtered = client.get("/officer/complaints?category=Roads&status=Pending", headers=officer_headers)
        assert filtered.status_code == 200
        complaint_id = filtered.json()[0]["id"]

        detail = client.get(f"/officer/complaints/{complaint_id}", headers=officer_headers)
        assert detail.status_code == 200
        assert detail.json()["recommended_department"] == "Public Works/Road Department"

        assignment = client.patch(
            f"/officer/complaints/{complaint_id}/assignment",
            headers=officer_headers,
            json={
                "assigned_department": "Public Works/Road Department",
                "assigned_officer_id": officer_id,
                "expected_resolution_date": "2026-10-15T00:00:00Z",
            },
        )
        assert assignment.status_code == 200
        assert assignment.json()["status"] == "Assigned"

        updated = client.patch(
            f"/officer/complaints/{complaint_id}/status",
            headers=officer_headers,
            json={
                "status": "Resolved",
                "action_notes": "Pothole repaired and inspected.",
                "repair_evidence_url": "https://example.test/repairs/road.jpg",
                "completion_date": "2026-10-14T12:30:00Z",
            },
        )
        assert updated.status_code == 200
        assert updated.json()["status"] == "Resolved"
        assert updated.json()["action_notes"] == "Pothole repaired and inspected."
        assert updated.json()["repair_evidence_url"] == "https://example.test/repairs/road.jpg"
        assert updated.json()["completion_date"].startswith("2026-10-14T12:30:00")

        updated_detail = client.get(f"/officer/complaints/{complaint_id}", headers=officer_headers)
        assert updated_detail.status_code == 200
        assert updated_detail.json()["assigned_officer_name"] == "Village Officer"
        assert updated_detail.json()["expected_resolution_date"].startswith("2026-10-15T00:00:00")
        assert updated_detail.json()["completion_date"].startswith("2026-10-14T12:30:00")
        assert updated_detail.json()["repair_evidence_url"] == "https://example.test/repairs/road.jpg"

        with SessionLocal() as db:
            officer = db.get(User, officer_id)
            assert officer is not None
            overdue_complaint = db.scalar(
                select(Complaint).where(
                    Complaint.village_id == officer.village_id,
                    Complaint.status == "In Progress",
                )
            )
            assert overdue_complaint is not None
            overdue_complaint.expected_resolution_date = datetime(2020, 1, 1)
            db.commit()

        insights = client.get("/officer/insights", headers=officer_headers)
        assert insights.status_code == 200
        payload = insights.json()
        assert payload["status_counts"] == {"In Progress": 1, "Resolved": 1}
        assert payload["category_counts"].get("Roads", 0) >= 1
        assert payload["priority_counts"].get("High", 0) >= 1
        assert payload["department_workload"].get("Public Works/Road Department", 0) >= 1
        assert payload["complaints_over_time"]
        assert payload["resolution_rate"]["rule"] == "resolved / total complaints * 100"
        assert payload["ai_insights"]
        assert len(payload["overdue_complaints"]) == 1
        assert payload["overdue_complaints"][0]["days_overdue"] > 0

        twin = client.get("/officer/digital-twin", headers=officer_headers)
        assert twin.status_code == 200
        payload = twin.json()
        assert payload["map_points"]
        assert payload["boundary_alerts"]
        assert any(point["is_outside_boundary"] for point in payload["map_points"])
        road_point = next(point for point in payload["map_points"] if point["category"] == "Roads")
        assert road_point["village"] == "Officer Test Village"
        assert road_point["village_id"] is not None
        assert road_point["latitude"] == 18.5204
        assert road_point["longitude"] == 73.8567
        assert road_point["repeated_complaints"] == 2
        outside_alert = next(
            alert for alert in payload["boundary_alerts"]
            if alert["complaint_id"] == next(
                point["complaint_id"] for point in payload["map_points"]
                if point["is_outside_boundary"]
            )
        )
        assert outside_alert["village"] == "Officer Test Village"

        forbidden = client.get("/officer/dashboard", headers=villager_headers)
        assert forbidden.status_code == 403

        dashboard_without_token = client.get("/officer/dashboard")
        assert dashboard_without_token.status_code == 401

        static_dashboard = client.get("/dashboard/")
        assert static_dashboard.status_code == 200
        assert "Officer Desk" in static_dashboard.text
        assert 'id="map-points"' in static_dashboard.text
        assert "app.js?v=25" in static_dashboard.text
        static_dashboard_script = client.get("/dashboard/app.js?v=25")
        assert static_dashboard_script.status_code == 200
        assert "data-open-complaint-id" in static_dashboard_script.text
        assert "marker.on('click', () => openDetail(point.complaint_id))" in static_dashboard_script.text


def test_karvir_village_and_taluka_scope_filters_dashboard_data() -> None:
    with TestClient(app) as client:
        seed_officer_data(email_suffix="-karvir-scope")
        with SessionLocal() as db:
            karvir_village = Village(name="Adur", district="Kolhapur", taluka="Karvir")
            other_taluka_village = Village(name="Other Area", district="Kolhapur", taluka="Panhala")
            db.add_all([karvir_village, other_taluka_village])
            db.flush()
            karvir_village_id = karvir_village.id
            officer = db.scalar(select(User).where(User.email == "officer-karvir-scope@test.example"))
            if officer:
                officer.village_id = karvir_village.id
            db.add_all(
                [
                    Complaint(
                        text="Road issue in Adur",
                        language="english",
                        village_id=karvir_village.id,
                        status="Pending",
                    ),
                    Complaint(
                        text="Water issue outside Karvir",
                        language="english",
                        village_id=other_taluka_village.id,
                        status="Pending",
                    ),
                ]
            )
            db.commit()

        headers = login(client, "officer-karvir-scope@test.example", "officer-password")
        village_options = client.get("/officer/villages", headers=headers)
        assert village_options.status_code == 200
        adur = next(village for village in village_options.json() if village["name"] == "Adur")
        assert adur == {
            "id": karvir_village_id,
            "name": "Adur",
            "district": "Kolhapur",
            "taluka": "Karvir",
        }

        dashboard = client.get(
            "/officer/dashboard?district=Kolhapur&taluka=Karvir",
            headers=headers,
        )
        assert dashboard.status_code == 200
        assert dashboard.json()["total_complaints"] == 1

        mismatch = client.get(
            f"/officer/complaints?village_id={karvir_village_id}&taluka=Panhala",
            headers=headers,
        )
        assert mismatch.status_code == 403


def test_admin_digital_twin_uses_each_complaints_own_village() -> None:
    with TestClient(app) as client:
        officer_id, _ = seed_officer_data(email_suffix="-admin-twin")
        with SessionLocal() as db:
            first_village_officer = db.get(User, officer_id)
            first_village = db.get(Village, first_village_officer.village_id)
            first_village_latitude = first_village.latitude
            second_village = Village(
                name="Second Twin Village",
                district="Nashik",
                latitude=19.9975,
                longitude=73.7898,
                boundary_radius_km=3.0,
            )
            db.add(second_village)
            db.flush()
            second_complaint = Complaint(
                text="The water pump in the second village is broken",
                language="english",
                village_id=second_village.id,
                status="Pending",
                latitude=second_village.latitude,
                longitude=second_village.longitude,
                exact_location="Near the village square",
                repeated_complaints=4,
            )
            db.add(second_complaint)
            db.flush()
            db.add(
                AIAnalysis(
                    complaint_id=second_complaint.id,
                    category="Water",
                    confidence=0.8,
                    severity="High",
                    severity_explanation="Water access is affected.",
                    priority_score=70,
                    priority_level="High",
                    priority_explanation="Repeated service report.",
                    possible_duplicate=False,
                    recommended_department="Water Department",
                )
            )
            unassigned_village_complaint = Complaint(
                text="A complaint has coordinates but no village association",
                language="english",
                status="Pending",
                latitude=first_village_latitude,
                longitude=first_village.longitude,
            )
            db.add(unassigned_village_complaint)
            admin = User(
                full_name="System Admin",
                email="admin@test.example",
                password_hash=hash_password("admin-password"),
                role="admin",
                village_id=first_village.id,
            )
            db.add(admin)
            db.commit()

        admin_headers = login(client, "admin@test.example", "admin-password")
        twin = client.get("/officer/digital-twin", headers=admin_headers)
        assert twin.status_code == 200
        points = twin.json()["map_points"]
        second_village_point = next(
            point for point in points if point["village"] == "Second Twin Village"
        )
        assert second_village_point["latitude"] == 19.9975
        assert second_village_point["longitude"] == 73.7898
        assert second_village_point["distance_from_village_km"] == 0
        assert second_village_point["is_outside_boundary"] is False
        assert second_village_point["repeated_complaints"] == 4
        unassigned_point = next(
            point for point in points
            if point["village"] is None and point["latitude"] == first_village_latitude
        )
        assert unassigned_point["distance_from_village_km"] is None
        assert unassigned_point["is_outside_boundary"] is False


def test_citizen_submission_appears_in_officer_complaint_queue() -> None:
    with TestClient(app) as client:
        seed_officer_data(email_suffix="-live")
        villager_headers = login(
            client,
            "villager-live@test.example",
            "villager-password",
        )
        officer_headers = login(
            client,
            "officer-live@test.example",
            "officer-password",
        )

        submitted = client.post(
            "/api/v1/complaints",
            headers=villager_headers,
            json={
                "complaint_text": "The village road near the school is damaged",
                "language": "english",
                "affected_people": 12,
                "area": "School Ward",
            },
        )

        assert submitted.status_code == 201
        complaint_id = submitted.json()["complaint_id"]
        officer_queue = client.get("/officer/complaints", headers=officer_headers)

        assert officer_queue.status_code == 200
        visible_ids = {item["id"] for item in officer_queue.json()}
        assert complaint_id in visible_ids



def test_work_order_workflow_and_ai_override() -> None:
    with TestClient(app) as client:
        officer_id, _ = seed_officer_data(email_suffix="_wo")
        officer_headers = login(client, "officer_wo@test.example", "officer-password")

        complaints_res = client.get("/officer/complaints", headers=officer_headers)
        assert complaints_res.status_code == 200
        complaints = complaints_res.json()
        assert len(complaints) > 0
        cid = complaints[0]["id"]

        # Accept Work Order
        accept_res = client.post(
            f"/officer/complaints/{cid}/work-order",
            headers=officer_headers,
            json={"action": "accept", "reason": "Dispatched maintenance crew to site."},
        )
        assert accept_res.status_code == 200
        detail = accept_res.json()
        assert detail["status"] == "In Progress"
        assert "Work Order ACCEPTED" in detail["action_notes"]

        # Reassign Work Order
        reassign_res = client.post(
            f"/officer/complaints/{cid}/work-order",
            headers=officer_headers,
            json={
                "action": "reassign",
                "reason": "Requires civil engineering team.",
                "reassigned_department": "Public Works/Road Department",
                "reassigned_officer_id": officer_id,
            },
        )
        assert reassign_res.status_code == 200
        assert "REASSIGNED" in reassign_res.json()["action_notes"]

        # AI Prediction Override
        override_res = client.post(
            f"/officer/complaints/{cid}/ai-override",
            headers=officer_headers,
            json={
                "corrected_category": "Roads",
                "corrected_severity": "Critical",
                "override_reason": "Direct visual inspection revealed major road cave-in.",
            },
        )
        assert override_res.status_code == 200
        override_detail = override_res.json()
        assert override_detail["category"] == "Roads"
        assert override_detail["severity"] == "Critical"
        assert "AI Override" in override_detail["action_notes"]


def test_digital_twin_assets_and_csv_exports() -> None:
    with TestClient(app) as client:
        seed_officer_data(email_suffix="_dt")
        officer_headers = login(client, "officer_dt@test.example", "officer-password")

        # 9-Domain Village Digital Twin
        twin_res = client.get("/officer/digital-twin", headers=officer_headers)
        assert twin_res.status_code == 200
        twin_data = twin_res.json()
        assert "assets" in twin_data
        assets = twin_data["assets"]
        assert len(assets) == 9
        domains = {a["domain"] for a in assets}
        assert domains == {
            "Water", "Roads", "Documents", "Study room",
            "Electricity", "CCTV", "Sanitation", "Agriculture", "Medical"
        }

        # Complaints CSV Export
        csv_res = client.get("/officer/reports/export-complaints-csv", headers=officer_headers)
        assert csv_res.status_code == 200
        assert "text/csv" in csv_res.headers["content-type"]
        assert "Complaint ID,Title / Text,Status" in csv_res.text

        # Governance Summary CSV Export
        gov_csv = client.get("/officer/reports/export-governance-csv", headers=officer_headers)
        assert gov_csv.status_code == 200
        assert "text/csv" in gov_csv.headers["content-type"]
        assert "Total Complaints" in gov_csv.text



def test_advanced_analytics_endpoint() -> None:
    with TestClient(app) as client:
        seed_officer_data(email_suffix="_adv")
        officer_headers = login(client, "officer_adv@test.example", "officer-password")

        # Test baseline call
        res = client.get("/officer/analytics/advanced", headers=officer_headers)
        assert res.status_code == 200
        data = res.json()
        assert "kpi_summary" in data
        assert "total" in data["kpi_summary"]
        assert "category_distribution" in data
        assert "status_distribution" in data
        assert "trend_timeline" in data
        assert "area_bubble_metrics" in data
        assert "resolution_analytics" in data
        assert "frequent_problems" in data
        assert "heatmap_points" in data
        assert isinstance(data["area_bubble_metrics"], list)

        # Test with interval=month and category filter
        filter_res = client.get(
            "/officer/analytics/advanced?interval=month&category=Roads",
            headers=officer_headers,
        )
        assert filter_res.status_code == 200
        f_data = filter_res.json()
        assert f_data["kpi_summary"]["total"] >= 1
        assert "Roads" in f_data["category_distribution"]
        assert "category_bubble_metrics" in f_data
        assert "histogram_bins" in f_data["resolution_analytics"]
        assert "department_workload" in f_data


def test_complaint_rejection_and_department_filters() -> None:
    with TestClient(app) as client:
        seed_officer_data(email_suffix="_wf")
        officer_headers = login(client, "officer_wf@test.example", "officer-password")

        complaints_res = client.get("/officer/complaints", headers=officer_headers)
        assert complaints_res.status_code == 200
        items = complaints_res.json()
        assert len(items) >= 1
        target_id = items[0]["id"]

        # Reject without reason must fail with 422
        bad_reject = client.patch(
            f"/officer/complaints/{target_id}/status",
            headers=officer_headers,
            json={"status": "Rejected", "action_notes": "   "},
        )
        assert bad_reject.status_code == 422
        assert "Rejection reason is required" in bad_reject.text

        # Reject with valid reason must succeed
        good_reject = client.patch(
            f"/officer/complaints/{target_id}/status",
            headers=officer_headers,
            json={"status": "Rejected", "action_notes": "Duplicate issue reported in ward 4."},
        )
        assert good_reject.status_code == 200
        assert good_reject.json()["status"] == "Rejected"
        assert "Duplicate issue" in good_reject.json()["action_notes"]

        # Filter complaints by status=Rejected
        rej_res = client.get("/officer/complaints?status=Rejected", headers=officer_headers)
        assert rej_res.status_code == 200
        assert any(c["id"] == target_id for c in rej_res.json())

        # Test department and date filters on complaints endpoint
        dept_res = client.get("/officer/complaints?department=Water", headers=officer_headers)
        assert dept_res.status_code == 200


def test_complaint_location_and_details() -> None:
    with TestClient(app) as client:
        seed_officer_data(email_suffix="_loc")
        officer_headers = login(client, "officer_loc@test.example", "officer-password")

        complaints_res = client.get("/officer/complaints", headers=officer_headers)
        assert complaints_res.status_code == 200
        items = complaints_res.json()
        assert len(items) >= 1
        first_item = items[0]

        # Verify summary fields
        assert "district" in first_item
        assert "taluka" in first_item
        assert "has_coordinates" in first_item

        # Verify detail fields
        detail_res = client.get(f"/officer/complaints/{first_item['id']}", headers=officer_headers)
        assert detail_res.status_code == 200
        detail_data = detail_res.json()
        assert "district" in detail_data
        assert "taluka" in detail_data
        assert "has_coordinates" in detail_data
        assert "is_valid_coordinate" in detail_data
        assert "latitude" in detail_data
        assert "longitude" in detail_data
        if detail_data["latitude"] is not None and detail_data["longitude"] is not None:
            assert -90 <= detail_data["latitude"] <= 90
            assert -180 <= detail_data["longitude"] <= 180
            assert detail_data["has_coordinates"] is True
            assert detail_data["is_valid_coordinate"] is True
