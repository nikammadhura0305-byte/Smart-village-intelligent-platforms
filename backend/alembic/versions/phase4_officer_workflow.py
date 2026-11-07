"""Add officer workflow fields and AI complaint tables.

Revision ID: phase4_officer_workflow
Revises:
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "phase4_officer_workflow"
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    if not inspector.has_table("complaints"):
        op.create_table(
            "complaints",
            sa.Column("id", sa.Integer(), primary_key=True),
            sa.Column("text", sa.Text(), nullable=False),
            sa.Column("language", sa.Text(), nullable=False, server_default="english"),
            sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
            sa.Column("village_id", sa.Integer(), sa.ForeignKey("villages.id"), nullable=True),
            sa.Column("affected_people", sa.Integer(), nullable=False, server_default="1"),
            sa.Column("repeated_complaints", sa.Integer(), nullable=False, server_default="0"),
            sa.Column("location_importance", sa.Integer(), nullable=False, server_default="0"),
            sa.Column("latitude", sa.Float(), nullable=True),
            sa.Column("longitude", sa.Float(), nullable=True),
            sa.Column("evidence_url", sa.Text(), nullable=True),
            sa.Column("status", sa.String(length=30), nullable=False, server_default="Pending"),
            sa.Column("assigned_department", sa.String(length=150), nullable=True),
            sa.Column("assigned_officer_id", sa.Integer(), sa.ForeignKey("users.id"), nullable=True),
            sa.Column("assigned_at", sa.DateTime(timezone=True), nullable=True),
            sa.Column("expected_resolution_date", sa.DateTime(timezone=True), nullable=True),
            sa.Column("action_notes", sa.Text(), nullable=True),
            sa.Column("repair_evidence_url", sa.Text(), nullable=True),
            sa.Column("completion_date", sa.DateTime(timezone=True), nullable=True),
            sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        )
        op.create_index("ix_complaints_language", "complaints", ["language"])
        op.create_index("ix_complaints_user_id", "complaints", ["user_id"])
        op.create_index("ix_complaints_village_id", "complaints", ["village_id"])
        op.create_index("ix_complaints_status", "complaints", ["status"])
        op.create_index("ix_complaints_assigned_officer_id", "complaints", ["assigned_officer_id"])
        op.create_index("ix_complaints_created_at", "complaints", ["created_at"])
    else:
        existing_columns = {column["name"] for column in inspector.get_columns("complaints")}
        additions = {
            "village_id": sa.Column(
                "village_id",
                sa.Integer(),
                sa.ForeignKey("villages.id", name="fk_complaints_village_id_villages"),
                nullable=True,
            ),
            "latitude": sa.Column("latitude", sa.Float(), nullable=True),
            "longitude": sa.Column("longitude", sa.Float(), nullable=True),
            "evidence_url": sa.Column("evidence_url", sa.Text(), nullable=True),
            "status": sa.Column("status", sa.String(length=30), nullable=False, server_default="Pending"),
            "assigned_department": sa.Column("assigned_department", sa.String(length=150), nullable=True),
            "assigned_officer_id": sa.Column(
                "assigned_officer_id",
                sa.Integer(),
                sa.ForeignKey("users.id", name="fk_complaints_assigned_officer_id_users"),
                nullable=True,
            ),
            "assigned_at": sa.Column("assigned_at", sa.DateTime(timezone=True), nullable=True),
            "expected_resolution_date": sa.Column("expected_resolution_date", sa.DateTime(timezone=True), nullable=True),
            "action_notes": sa.Column("action_notes", sa.Text(), nullable=True),
            "repair_evidence_url": sa.Column("repair_evidence_url", sa.Text(), nullable=True),
            "completion_date": sa.Column("completion_date", sa.DateTime(timezone=True), nullable=True),
        }
        missing_columns = [column for name, column in additions.items() if name not in existing_columns]
        if missing_columns:
            with op.batch_alter_table("complaints", recreate="always") as batch_op:
                for column in missing_columns:
                    batch_op.add_column(column)

    if not inspector.has_table("ai_analyses"):
        op.create_table(
            "ai_analyses",
            sa.Column("id", sa.Integer(), primary_key=True),
            sa.Column("complaint_id", sa.Integer(), sa.ForeignKey("complaints.id"), nullable=True),
            sa.Column("category", sa.Text(), nullable=False),
            sa.Column("confidence", sa.Float(), nullable=False),
            sa.Column("severity", sa.Text(), nullable=False),
            sa.Column("severity_explanation", sa.Text(), nullable=False),
            sa.Column("priority_score", sa.Float(), nullable=False),
            sa.Column("priority_level", sa.Text(), nullable=False),
            sa.Column("priority_explanation", sa.Text(), nullable=False),
            sa.Column("possible_duplicate", sa.Boolean(), nullable=False, server_default=sa.false()),
            sa.Column("matching_complaint_id", sa.Integer(), sa.ForeignKey("complaints.id"), nullable=True),
            sa.Column("similarity_score", sa.Float(), nullable=True),
            sa.Column("recommended_department", sa.Text(), nullable=False),
            sa.Column("evidence_status", sa.Text(), nullable=False, server_default="not_provided"),
            sa.Column("analysis_timestamp", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        )
        op.create_index("ix_ai_analyses_complaint_id", "ai_analyses", ["complaint_id"])
        op.create_index("ix_ai_analyses_analysis_timestamp", "ai_analyses", ["analysis_timestamp"])


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if inspector.has_table("ai_analyses"):
        op.drop_table("ai_analyses")
    if inspector.has_table("complaints"):
        op.drop_table("complaints")
