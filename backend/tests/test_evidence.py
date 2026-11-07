import base64
import os
import sys
import uuid
from pathlib import Path

import pytest

# Use isolated test SQLite database
os.environ["DATABASE_URL"] = "sqlite:///./test_evidence.db"
if os.path.exists("test_evidence.db"):
    try:
        os.remove("test_evidence.db")
    except Exception:
        pass

backend_dir = str(Path(__file__).resolve().parents[1])
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

from fastapi.testclient import TestClient

from app.core.security import hash_password
from app.db.session import SessionLocal
from app.main import app
from app.models import Complaint, User, Village
from app.api.routes import citizen as citizen_routes
from app.ai.evidence import MAX_EVIDENCE_BYTES

UPLOAD_DIR = Path(__file__).resolve().parents[1] / "uploads" / "evidence"


def seed_evidence_test_data() -> tuple[str, str, int]:
    suffix = uuid.uuid4().hex[:6]
    cit_email = f"citizen_ev_{suffix}@test.example"
    off_email = f"officer_ev_{suffix}@test.example"
    pwd = "password123"

    with SessionLocal() as db:
        village = Village(name=f"Evidence Village {suffix}", district="Pune")
        db.add(village)
        db.flush()

        citizen = User(
            full_name="Evidence Citizen",
            email=cit_email,
            password_hash=hash_password(pwd),
            role="villager",
            village_id=village.id,
        )
        officer = User(
            full_name="Evidence Officer",
            email=off_email,
            password_hash=hash_password(pwd),
            role="village_officer",
            village_id=village.id,
        )
        db.add_all([citizen, officer])
        db.flush()

        complaint = Complaint(
            text="Water pipeline burst with heavy road flooding",
            language="english",
            user_id=citizen.id,
            village_id=village.id,
            status="Pending",
        )
        db.add(complaint)
        db.commit()
        return cit_email, off_email, complaint.id


@pytest.fixture
def cleanup_evidence_uploads():
    existing_files = set(UPLOAD_DIR.glob("evidence_*"))
    yield
    for file_path in set(UPLOAD_DIR.glob("evidence_*")) - existing_files:
        file_path.unlink(missing_ok=True)


def test_evidence_upload_and_streaming(
    cleanup_evidence_uploads: None,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    with TestClient(app) as client:
        cit_email, off_email, complaint_id = seed_evidence_test_data()
        pwd = "password123"

        # Login as citizen
        cit_res = client.post("/auth/login", json={"email": cit_email, "password": pwd})
        assert cit_res.status_code == 200
        cit_token = cit_res.json()["access_token"]
        cit_headers = {"Authorization": f"Bearer {cit_token}"}

        # 1. Reject empty upload
        bad_empty = client.post(
            f"/complaints/{complaint_id}/evidence",
            headers=cit_headers,
            json={"filename": "test.jpg", "media_type": "image/jpeg", "content_base64": ""},
        )
        assert bad_empty.status_code == 422

        # 2. Reject unsupported media format
        bad_format = client.post(
            f"/complaints/{complaint_id}/evidence",
            headers=cit_headers,
            json={"filename": "doc.pdf", "media_type": "application/pdf", "content_base64": "JVBERi0xLjQK..."},
        )
        assert bad_format.status_code == 422
        assert "Unsupported media type" in bad_format.text

        # 3. Successful upload of JPEG image via JSON base64
        fake_jpg_bytes = b"\xFF\xD8\xFF\xE0\x00\x10JFIF" + b"A" * 512
        fake_b64 = base64.b64encode(fake_jpg_bytes).decode("ascii")

        up_res = client.post(
            f"/complaints/{complaint_id}/evidence",
            headers=cit_headers,
            json={
                "filename": "pothole_photo.jpg",
                "media_type": "image/jpeg",
                "content_base64": fake_b64,
            },
        )
        assert up_res.status_code == 200
        data = up_res.json()
        assert data["complaint_id"] == complaint_id
        assert data["media_type"] == "image/jpeg"
        assert data["size_bytes"] == len(fake_jpg_bytes)
        filename = data["filename"]
        evidence_url = data["evidence_url"]
        assert filename in evidence_url

        # Verify file exists on disk
        saved_file = UPLOAD_DIR / filename
        assert saved_file.is_file()

        # 4. Stream evidence as authenticated officer
        off_res = client.post("/auth/login", json={"email": off_email, "password": pwd})
        assert off_res.status_code == 200
        off_token = off_res.json()["access_token"]
        off_headers = {"Authorization": f"Bearer {off_token}"}

        stream_res = client.get(evidence_url, headers=off_headers)
        assert stream_res.status_code == 200
        assert stream_res.content == fake_jpg_bytes
        assert "image/jpeg" in stream_res.headers["content-type"]
        assert stream_res.headers["content-disposition"] == "inline"

        # 6. Upload video as multipart/form-data
        fake_mp4_bytes = b"\x00\x00\x00\x18ftypmp42" + b"video-data"
        video_res = client.post(
            f"/complaints/{complaint_id}/evidence",
            headers=cit_headers,
            files={"file": ("road_damage.mp4", fake_mp4_bytes, "video/mp4")},
        )
        assert video_res.status_code == 200
        video_data = video_res.json()
        assert video_data["media_type"] == "video/mp4"
        assert video_data["size_bytes"] == len(fake_mp4_bytes)

        video_stream = client.get(video_data["evidence_url"], headers=off_headers)
        assert video_stream.status_code == 200
        assert video_stream.content == fake_mp4_bytes
        assert "video/mp4" in video_stream.headers["content-type"]

        # Use a small test threshold while asserting the production limit.
        assert MAX_EVIDENCE_BYTES == 50 * 1024 * 1024
        with monkeypatch.context() as evidence_limit:
            evidence_limit.setattr(citizen_routes, "MAX_EVIDENCE_BYTES", 64)
            too_large = client.post(
                f"/complaints/{complaint_id}/evidence",
                headers=cit_headers,
                files={"file": ("large.jpg", b"x" * 65, "image/jpeg")},
            )
        assert too_large.status_code == 422
        assert "50 MB" in too_large.text

        # 8. Citizen streaming their own current file
        cit_stream = client.get(
            video_data["evidence_url"].replace("/officer/complaints/", "/complaints/"),
            headers=cit_headers,
        )
        assert cit_stream.status_code == 200
        assert cit_stream.content == fake_mp4_bytes

        # 9. Unauthenticated request blocked
        unauth_stream = client.get(video_data["evidence_url"])
        assert unauth_stream.status_code in [401, 403]
