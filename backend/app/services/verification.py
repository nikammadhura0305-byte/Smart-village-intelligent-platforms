from datetime import UTC, datetime, timedelta

from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models import Complaint, Escalation, Notification, User, Verification
from app.services.notifications import NotificationEvent, NotificationService


class VerificationService:
    def __init__(self, notifications: NotificationService | None = None) -> None:
        self.notifications = notifications or NotificationService()

    def request_for_resolved_complaint(self, db: Session, complaint: Complaint) -> Verification | None:
        if complaint.user_id is None or complaint.status != "Resolved":
            return None
        existing = db.scalar(
            select(Verification)
            .where(Verification.complaint_id == complaint.id, Verification.response.is_(None))
            .order_by(desc(Verification.requested_at))
            .limit(1)
        )
        if existing:
            return existing
        verification = Verification(complaint_id=complaint.id, user_id=complaint.user_id)
        db.add(verification)
        self.notifications.notify(
            db,
            user_id=complaint.user_id,
            complaint_id=complaint.id,
            notification_type=NotificationEvent.VERIFICATION_REQUESTED,
            message="Is your problem solved? Please verify the completed work.",
        )
        db.flush()
        return verification

    def respond(
        self,
        db: Session,
        complaint: Complaint,
        user: User,
        solved: bool,
        reason: str | None,
    ) -> Verification:
        if complaint.user_id != user.id:
            raise PermissionError("Only the complaint owner can verify the resolution")
        if complaint.status != "Resolved":
            raise ValueError("Only resolved complaints can be verified")
        verification = db.scalar(
            select(Verification)
            .where(Verification.complaint_id == complaint.id, Verification.user_id == user.id, Verification.response.is_(None))
            .order_by(desc(Verification.requested_at))
            .limit(1)
        )
        if verification is None:
            raise ValueError("No pending verification request exists")
        if not solved and not reason:
            raise ValueError("A reason is required when reopening a complaint")

        verification.response = "yes" if solved else "no"
        verification.reason = reason
        verification.responded_at = datetime.now(UTC)
        if solved:
            complaint.status = "Closed"
        else:
            complaint.status = "Reopened"
            previous_level = db.scalar(
                select(Escalation.level)
                .where(Escalation.complaint_id == complaint.id)
                .order_by(desc(Escalation.level))
                .limit(1)
            ) or 0
            escalation = Escalation(
                complaint_id=complaint.id,
                level=previous_level + 1,
                reason=f"Citizen rejected resolution: {reason}",
                responsible_officer_id=complaint.assigned_officer_id,
            )
            db.add(escalation)
            if complaint.assigned_officer_id:
                self.notifications.notify(
                    db,
                    user_id=complaint.assigned_officer_id,
                    complaint_id=complaint.id,
                    notification_type=NotificationEvent.COMPLAINT_REOPENED,
                    message=f"Complaint #{complaint.id} was reopened by the citizen: {reason}",
                )
            self.notifications.notify(
                db,
                user_id=user.id,
                complaint_id=complaint.id,
                notification_type=NotificationEvent.ESCALATION,
                message=f"Complaint #{complaint.id} was reopened and escalated to level {previous_level + 1}.",
            )
        db.flush()
        return verification

    def check_overdue(
        self,
        db: Session,
        village_id: int | None,
        include_all_villages: bool,
        village_ids: list[int] | None = None,
    ) -> int:
        cutoff = datetime.now(UTC) - timedelta(hours=settings.escalation_after_hours)
        query = select(Complaint).where(
            Complaint.status.in_(["Pending", "Assigned", "In Progress", "Reopened"]),
            Complaint.created_at <= cutoff,
        )
        if village_ids is not None:
            if not village_ids:
                return 0
            query = query.where(Complaint.village_id.in_(village_ids))
        elif not include_all_villages:
            if village_id is None:
                return 0
            query = query.where(Complaint.village_id == village_id)
        complaints = db.scalars(query).all()
        escalated = 0
        for complaint in complaints:
            existing_open = db.scalar(
                select(Escalation).where(Escalation.complaint_id == complaint.id, Escalation.resolved_at.is_(None)).limit(1)
            )
            if existing_open:
                continue
            previous_level = db.scalar(
                select(Escalation.level)
                .where(Escalation.complaint_id == complaint.id)
                .order_by(desc(Escalation.level))
                .limit(1)
            ) or 0
            db.add(
                Escalation(
                    complaint_id=complaint.id,
                    level=previous_level + 1,
                    reason=f"No resolution within configured threshold of {settings.escalation_after_hours} hours.",
                    responsible_officer_id=complaint.assigned_officer_id,
                )
            )
            if complaint.assigned_officer_id:
                self.notifications.notify(
                    db,
                    user_id=complaint.assigned_officer_id,
                    complaint_id=complaint.id,
                    notification_type=NotificationEvent.ESCALATION,
                    message=f"Complaint #{complaint.id} requires escalation because it exceeded the configured response threshold.",
                )
            escalated += 1
        db.commit()
        return escalated
