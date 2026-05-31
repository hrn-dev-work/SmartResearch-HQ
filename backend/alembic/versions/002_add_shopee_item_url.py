"""Add shopee_item_url to job_items."""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "002_shopee_item_url"
down_revision: str | None = "001_initial"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        "job_items",
        sa.Column("shopee_item_url", sa.Text(), nullable=False, server_default=""),
    )
    op.alter_column("job_items", "shopee_item_url", server_default=None)


def downgrade() -> None:
    op.drop_column("job_items", "shopee_item_url")
