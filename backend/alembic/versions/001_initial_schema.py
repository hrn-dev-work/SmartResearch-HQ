"""Initial schema — Phase 2."""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "001_initial"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "sellers",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("shopee_shop_url", sa.Text(), nullable=False),
        sa.Column("display_name", sa.String(length=255), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("shopee_shop_url"),
    )
    op.create_table(
        "research_jobs",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("seller_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("status", sa.String(length=32), nullable=False),
        sa.Column("progress_pct", sa.SmallInteger(), nullable=False),
        sa.Column("error_code", sa.String(length=64), nullable=True),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.Column("retry_count", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["seller_id"], ["sellers.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_research_jobs_status", "research_jobs", ["status"])
    op.create_index("idx_research_jobs_seller", "research_jobs", ["seller_id"])
    op.create_table(
        "job_items",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("job_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("shopee_item_id", sa.String(length=64), nullable=False),
        sa.Column("title", sa.Text(), nullable=False),
        sa.Column("image_url", sa.Text(), nullable=False),
        sa.Column("sold_count", sa.Integer(), nullable=True),
        sa.Column("price_display", sa.String(length=64), nullable=True),
        sa.Column("scrape_metadata", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["job_id"], ["research_jobs.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_job_items_job", "job_items", ["job_id"])
    op.create_table(
        "amazon_candidates",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("job_item_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("rank", sa.SmallInteger(), nullable=False),
        sa.Column("asin", sa.String(length=16), nullable=False),
        sa.Column("amazon_url", sa.Text(), nullable=False),
        sa.Column("title", sa.Text(), nullable=False),
        sa.Column("confidence", sa.Numeric(precision=4, scale=3), nullable=False),
        sa.Column("reasoning", sa.Text(), nullable=True),
        sa.Column("source", sa.String(length=32), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["job_item_id"], ["job_items.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_amazon_candidates_item", "amazon_candidates", ["job_item_id"])
    op.create_table(
        "review_decisions",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("job_item_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("chosen_candidate_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("manual_asin", sa.String(length=16), nullable=True),
        sa.Column("rejected", sa.Boolean(), nullable=False),
        sa.Column("decided_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("exported_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["chosen_candidate_id"], ["amazon_candidates.id"]),
        sa.ForeignKeyConstraint(["job_item_id"], ["job_items.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("job_item_id", name="uq_review_decisions_job_item"),
    )


def downgrade() -> None:
    op.drop_table("review_decisions")
    op.drop_index("idx_amazon_candidates_item", table_name="amazon_candidates")
    op.drop_table("amazon_candidates")
    op.drop_index("idx_job_items_job", table_name="job_items")
    op.drop_table("job_items")
    op.drop_index("idx_research_jobs_seller", table_name="research_jobs")
    op.drop_index("idx_research_jobs_status", table_name="research_jobs")
    op.drop_table("research_jobs")
    op.drop_table("sellers")
