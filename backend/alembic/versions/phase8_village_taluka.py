"""Add taluka to village records.

Revision ID: phase8_village_taluka
Revises: phase7_location_details
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "phase8_village_taluka"
down_revision: Union[str, Sequence[str], None] = "phase7_location_details"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if inspector.has_table("villages"):
        columns = {column["name"] for column in inspector.get_columns("villages")}
        if "taluka" not in columns:
            with op.batch_alter_table("villages") as batch_op:
                batch_op.add_column(sa.Column("taluka", sa.String(length=100), nullable=True))
                batch_op.create_index("ix_villages_taluka", ["taluka"])


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if inspector.has_table("villages"):
        columns = {column["name"] for column in inspector.get_columns("villages")}
        if "taluka" in columns:
            with op.batch_alter_table("villages") as batch_op:
                batch_op.drop_index("ix_villages_taluka")
                batch_op.drop_column("taluka")
