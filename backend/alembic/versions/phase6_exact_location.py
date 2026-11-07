"""Add exact_location to complaint records.

Revision ID: phase6_exact_location
Revises: phase5_verification_intelligence
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "phase6_exact_location"
down_revision: Union[str, Sequence[str], None] = "phase5_verification_intelligence"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if inspector.has_table("complaints"):
        existing_columns = {column["name"] for column in inspector.get_columns("complaints")}
        if "exact_location" not in existing_columns:
            with op.batch_alter_table("complaints", recreate="always") as batch_op:
                batch_op.add_column(sa.Column("exact_location", sa.Text(), nullable=True))


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if inspector.has_table("complaints"):
        existing_columns = {column["name"] for column in inspector.get_columns("complaints")}
        if "exact_location" in existing_columns:
            with op.batch_alter_table("complaints", recreate="always") as batch_op:
                batch_op.drop_column("exact_location")
