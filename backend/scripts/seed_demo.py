from datetime import UTC, datetime, timedelta

from sqlalchemy import select

from app.ai.classifier import ClassifierUnavailable
from app.ai.service import ComplaintAnalysisService
from app.core.security import hash_password
from app.db.init_db import init_db
from app.db.session import SessionLocal
from app.models import AIAnalysis, Complaint, User, Village

analysis_service = ComplaintAnalysisService()


def main() -> None:
    init_db()
    with SessionLocal() as db:
        village = db.scalar(select(Village).where(Village.name == "Demo Village", Village.district == "Pune"))
        if village is None:
            village = Village(name="Demo Village", district="Pune")
            db.add(village)
            db.flush()

        officer = db.scalar(select(User).where(User.email == "officer@example.com"))
        if officer is None:
            officer = User(
                full_name="Village Officer",
                email="officer@example.com",
                password_hash=hash_password("change-this-password"),
                role="village_officer",
                village=village,
            )
            db.add(officer)
            db.flush()
        else:
            officer.role = "village_officer"
            officer.village_id = village.id
            officer.password_hash = hash_password("change-this-password")

        villager = db.scalar(select(User).where(User.email == "villager@example.com"))
        if villager is None:
            villager = User(
                full_name="Demo Villager",
                email="villager@example.com",
                password_hash=hash_password("demo-password"),
                role="villager",
                village=village,
            )
            db.add(villager)
            db.flush()

        samples = [
            {
                "text": "Water has not reached the north-side homes for two days; families are collecting water from a distant hand pump.",
                "status": "Assigned",
                "affected_people": 35,
                "location_importance": 7,
                "lane": "North settlement",
                "lane_number": "1",
                "exact_location": "Near the community hand pump",
                "area": "North Ward",
            },
            {
                "text": "A deep pothole has opened on the road used by school children and two-wheelers near the primary school.",
                "status": "In Progress",
                "affected_people": 45,
                "location_importance": 8,
                "lane": "School road",
                "lane_number": "2",
                "exact_location": "Outside the primary school entrance",
                "area": "Central Ward",
            },
            {
                "text": "The transformer beside the residential lane is sparking and there is an immediate risk of electric shock.",
                "status": "Assigned",
                "affected_people": 20,
                "location_importance": 10,
                "lane": "Shivaji Lane",
                "lane_number": "3",
                "exact_location": "Beside the residential transformer",
                "area": "East Ward",
            },
            {
                "text": "The primary health center needs urgent attention because no doctor is available and patients are being turned away.",
                "status": "Assigned",
                "affected_people": 30,
                "location_importance": 9,
                "lane": None,
                "lane_number": None,
                "exact_location": "Village primary health centre",
                "area": "Central Ward",
            },
            {
                "text": "Household garbage has not been collected from the market lane for a week and waste is attracting stray animals.",
                "status": "In Progress",
                "affected_people": 55,
                "location_importance": 6,
                "lane": "Market lane",
                "lane_number": "4",
                "exact_location": "Behind the weekly market",
                "area": "Market Ward",
            },
            {
                "text": "The open drain is blocked and overflowing beside the bus stop, leaving dirty water across the footpath.",
                "status": "Assigned",
                "affected_people": 40,
                "location_importance": 8,
                "lane": "Bus stop road",
                "lane_number": "5",
                "exact_location": "Main bus stop footpath",
                "area": "South Ward",
            },
            {
                "text": "Street lights on the road between the bus stop and the school have been off for three nights.",
                "status": "Resolved",
                "affected_people": 60,
                "location_importance": 7,
                "lane": "Bus stop road",
                "lane_number": "6",
                "exact_location": "Between the bus stop and primary school",
                "area": "South Ward",
            },
            {
                "text": "The drinking water tap near the anganwadi has muddy water and several families are avoiding it.",
                "status": "Pending",
                "affected_people": 28,
                "location_importance": 8,
                "lane": "Anganwadi lane",
                "lane_number": "7",
                "exact_location": "Public tap outside the anganwadi",
                "area": "East Ward",
                "days_ago": 3,
            },
            {
                "text": "Rainwater is flooding the vegetable market because the roadside drainage channel is blocked.",
                "status": "In Progress",
                "affected_people": 42,
                "location_importance": 7,
                "lane": "Market road",
                "lane_number": "8",
                "exact_location": "Drain beside the vegetable market entrance",
                "area": "Market Ward",
                "days_ago": 8,
            },
            {
                "text": "The hand pump in the south settlement is not working and nearby households have no alternative water source.",
                "status": "Resolved",
                "affected_people": 18,
                "location_importance": 6,
                "lane": "South settlement",
                "lane_number": "9",
                "exact_location": "Community hand pump near the south bus stop",
                "area": "South Ward",
                "days_ago": 15,
            },
        ]

        for sample in samples:
            existing = db.scalar(select(Complaint).where(Complaint.text == sample["text"]))
            if existing:
                continue

            complaint = Complaint(
                text=sample["text"],
                language="english",
                user_id=villager.id,
                village_id=village.id,
                affected_people=sample["affected_people"],
                location_importance=sample["location_importance"],
                created_at=datetime.now(UTC) - timedelta(days=sample.get("days_ago", 0)),
                status=sample["status"],
                assigned_officer_id=(
                    officer.id if sample["status"] != "Pending" else None
                ),
                assigned_at=(
                    datetime.now(UTC) if sample["status"] != "Pending" else None
                ),
                expected_resolution_date=(
                    datetime.now(UTC) + timedelta(days=2)
                    if sample["status"] not in {"Resolved", "Closed"}
                    else None
                ),
                lane=sample["lane"],
                lane_number=sample["lane_number"],
                exact_location=sample["exact_location"],
                area=sample["area"],
                action_notes=(
                    "Demo record: repair marked complete for dashboard workflow."
                    if sample["status"] == "Resolved"
                    else None
                ),
                completion_date=(
                    datetime.now(UTC)
                    if sample["status"] == "Resolved"
                    else None
                ),
            )
            db.add(complaint)
            db.flush()
            try:
                outcome = analysis_service.analyze(
                    db=db,
                    text=complaint.text,
                    language=complaint.language,
                    complaint_id=complaint.id,
                    affected_people=complaint.affected_people,
                    location_importance=complaint.location_importance,
                )
            except ClassifierUnavailable:
                db.rollback()
                raise

            complaint.assigned_department = outcome.analysis.recommended_department
            db.add(complaint)

        db.commit()
        print("Officer login: officer@example.com / change-this-password")
        print("Villager login: villager@example.com / demo-password")
        demo_complaints = db.scalars(
            select(Complaint)
            .where(
                Complaint.village_id == village.id,
                Complaint.user_id == villager.id,
                Complaint.text.in_([sample["text"] for sample in samples]),
            )
            .order_by(Complaint.id)
        ).all()
        print(f"Demo complaints available: {len(demo_complaints)}")
        for complaint in demo_complaints:
            analysis = db.scalar(
                select(AIAnalysis)
                .where(AIAnalysis.complaint_id == complaint.id)
                .order_by(AIAnalysis.analysis_timestamp.desc())
                .limit(1)
            )
            if analysis is not None:
                print(
                    f"#{complaint.id}: {analysis.category} / {analysis.severity} / "
                    f"{analysis.priority_level} / {complaint.status} / "
                    f"{complaint.assigned_department}"
                )


if __name__ == "__main__":
    main()
