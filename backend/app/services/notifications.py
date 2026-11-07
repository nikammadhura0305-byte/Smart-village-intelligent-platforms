from datetime import UTC, datetime
from typing import Protocol

from sqlalchemy.orm import Session

from app.models import Notification


class NotificationEvent:
    COMPLAINT_SUBMITTED = "complaint_submitted"
    COMPLAINT_ASSIGNED = "complaint_assigned"
    STATUS_CHANGED = "status_changed"
    COMPLAINT_RESOLVED = "complaint_resolved"
    VERIFICATION_REQUESTED = "verification_requested"
    COMPLAINT_REOPENED = "complaint_reopened"
    ESCALATION = "escalation"


class NotificationProvider(Protocol):
    channel: str

    def deliver(self, notification: Notification) -> None:
        """Deliver through a concrete provider such as SMS, WhatsApp, or push."""


class DatabaseNotificationProvider:
    channel = "database"

    def deliver(self, notification: Notification) -> None:
        notification.status = "recorded"
        notification.sent_at = datetime.now(UTC)


class NotificationService:
    def __init__(self, provider: NotificationProvider | None = None) -> None:
        self.provider = provider or DatabaseNotificationProvider()

    def notify(
        self,
        db: Session,
        user_id: int,
        notification_type: str,
        message: str,
        complaint_id: int | None = None,
    ) -> Notification:
        notification = Notification(
            user_id=user_id,
            complaint_id=complaint_id,
            notification_type=notification_type,
            channel=self.provider.channel,
            message=message,
        )
        db.add(notification)
        self.provider.deliver(notification)
        db.flush()
        return notification
