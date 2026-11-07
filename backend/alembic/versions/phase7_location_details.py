"""Add structured complaint location fields.

Revision ID: phase7_location_details
Revises: phase6_exact_location
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "phase7_location_details"
down_revision: Union[str, Sequence[str], None] = "phase6_exact_location"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if not inspector.has_table("complaints"):
        return
    existing_columns = {column["name"] for column in inspector.get_columns("complaints")}
    with op.batch_alter_table("complaints", recreate="always") as batch_op:
        for column_name, column_type in (
            ("lane", sa.Text()),
            ("lane_number", sa.Text()),
            ("area", sa.Text()),
        ):
            if column_name not in existing_columns:
                batch_op.add_column(sa.Column(column_name, column_type, nullable=True))


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if not inspector.has_table("complaints"):
        return
    existing_columns = {column["name"] for column in inspector.get_columns("complaints")}
    with op.batch_alter_table("complaints", recreate="always") as batch_op:
        for column_name in ("lane", "lane_number", "area"):
            if column_name in existing_columns:
                batch_op.drop_column(column_name)
