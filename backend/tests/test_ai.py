import os

os.environ["DATABASE_URL"] = "sqlite:///./test_ai.db"
if os.path.exists("test_ai.db"):
    os.remove("test_ai.db")

from fastapi.testclient import TestClient

from app.db.session import SessionLocal
from app.main import app
from app.models import Complaint


def test_analyze_sample_complaints() -> None:
    samples = [
        ("The road near the school is damaged", "Roads"),
        ("There has been no electricity in the village since last night", "Electricity"),
        ("The primary health center needs urgent attention", "Medical"),
    ]

    with TestClient(app) as client:
        for text, expected_category in samples:
            response = client.post(
                "/ai/analyze-complaint",
                json={"complaint_text": text, "language": "english", "affected_people": 20},
            )
            assert response.status_code == 201
            body = response.json()
            assert body["category"] == expected_category
            assert body["model_status"] == "development_baseline"
            assert 0 <= body["confidence"] <= 1
            assert body["severity"] in {"Low", "Medium", "High", "Critical"}
            assert body["priority_score"] >= 0
            assert body["recommended_department"]
            assert body["analysis_timestamp"]


def test_duplicate_and_evidence_status() -> None:
    with SessionLocal() as db:
        complaint = Complaint(
            text="The road beside the village school has a large pothole",
            language="english",
        )
        db.add(complaint)
        db.commit()
        complaint_id = complaint.id

    with TestClient(app) as client:
        response = client.post(
            "/ai/analyze-complaint",
            json={
                "complaint_text": "A large pothole is damaging the road beside our village school",
                "language": "english",
                "evidence_media_type": "image/jpeg",
                "evidence_size_bytes": 1024,
            },
        )
        assert response.status_code == 201
        body = response.json()
        assert body["possible_duplicate"] is True
        assert body["matching_complaint_id"] == complaint_id
        assert body["evidence_status"] == "pending_model_integration"

    with SessionLocal() as db:
        assert db.query(Complaint).count() == 1
        assert db.query(Complaint).first() is not None


def test_unrelated_complaint_is_not_flagged_as_duplicate() -> None:
    with SessionLocal() as db:
        db.add(
            Complaint(
                text="The drain is overflowing beside the village market",
                language="english",
            )
        )
        db.commit()

    with TestClient(app) as client:
        response = client.post(
            "/ai/analyze-complaint",
            json={
                "complaint_text": "The health center needs more medical staff",
                "language": "english",
            },
        )

    assert response.status_code == 201
    body = response.json()
    assert body["possible_duplicate"] is False
    assert body["matching_complaint_id"] is None


def test_multilingual_ai_analysis() -> None:
    cases = [
        ("आमच्या गावात तीन दिवसांपासून पाणी आले नाही", "marathi", "Water"),
        ("कल रात से गाँव में बिजली पूरी तरह से गुल है", "hindi", "Electricity"),
    ]
    with TestClient(app) as client:
        for text, lang, expected in cases:
            response = client.post(
                "/ai/analyze-complaint",
                json={"complaint_text": text, "language": lang, "affected_people": 25},
            )
            assert response.status_code == 201
            body = response.json()
            assert body["category"] == expected
            assert body["severity"] in {"Medium", "High", "Critical"}
            assert body["priority_score"] > 0
