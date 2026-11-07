"""Add verification, notification, and escalation records.

Revision ID: phase5_verification_intelligence
Revises: phase4_officer_workflow
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "phase5_verification_intelligence"
down_revision: Union[str, Sequence[str], None] = "phase4_officer_workflow"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if not inspector.has_table("verifications"):
        op.create_table(
            "verifications",
            sa.Column("id", sa.Integer(), primary_key=True),
            sa.Column("complaint_id", sa.Integer(), sa.ForeignKey("complaints.id"), nullable=False),
            sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
            sa.Column("response", sa.String(length=20), nullable=True),
            sa.Column("reason", sa.Text(), nullable=True),
            sa.Column("requested_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
            sa.Column("responded_at", sa.DateTime(timezone=True), nullable=True),
        )
        op.create_index("ix_verifications_complaint_id", "verifications", ["complaint_id"])
        op.create_index("ix_verifications_user_id", "verifications", ["user_id"])
        op.create_index("ix_verifications_requested_at", "verifications", ["requested_at"])

    if not inspector.has_table("notifications"):
        op.create_table(
            "notifications",
            sa.Column("id", sa.Integer(), primary_key=True),
            sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=False),
            sa.Column("complaint_id", sa.Integer(), sa.ForeignKey("complaints.id"), nullable=True),
            sa.Column("notification_type", sa.String(length=50), nullable=False),
            sa.Column("channel", sa.String(length=30), nullable=False, server_default="database"),
            sa.Column("status", sa.String(length=30), nullable=False, server_default="queued"),
            sa.Column("message", sa.Text(), nullable=False),
            sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
            sa.Column("sent_at", sa.DateTime(timezone=True), nullable=True),
        )
        op.create_index("ix_notifications_user_id", "notifications", ["user_id"])
        op.create_index("ix_notifications_complaint_id", "notifications", ["complaint_id"])
        op.create_index("ix_notifications_notification_type", "notifications", ["notification_type"])
        op.create_index("ix_notifications_created_at", "notifications", ["created_at"])

    if not inspector.has_table("escalations"):
        op.create_table(
            "escalations",
            sa.Column("id", sa.Integer(), primary_key=True),
            sa.Column("complaint_id", sa.Integer(), sa.ForeignKey("complaints.id"), nullable=False),
            sa.Column("level", sa.Integer(), nullable=False, server_default="1"),
            sa.Column("reason", sa.Text(), nullable=False),
            sa.Column("responsible_officer_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
            sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
            sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
        )
        op.create_index("ix_escalations_complaint_id", "escalations", ["complaint_id"])
        op.create_index("ix_escalations_responsible_officer_id", "escalations", ["responsible_officer_id"])
        op.create_index("ix_escalations_created_at", "escalations", ["created_at"])


def downgrade() -> None:
    for table in ("escalations", "notifications", "verifications"):
        if sa.inspect(op.get_bind()).has_table(table):
            op.drop_table(table)
