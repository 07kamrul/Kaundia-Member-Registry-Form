"""config_list_items table - admin-editable option lists, seeded from
previously hard-coded frontend constants (property types, document types)

Revision ID: f6a7b8c9d0e1
Revises: e5f6a7b8c9d0
Create Date: 2026-09-27 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f6a7b8c9d0e1'
down_revision: Union[str, None] = 'e5f6a7b8c9d0'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# (category, value, label, sort_order) - value/label kept identical to the
# exact Bangla strings previously hard-coded in
# frontend/src/app/core/models/registration.model.ts so existing submitted
# Property.property_type / ApplicableDoc.doc_type free-text values keep matching.
SEED_ITEMS = [
    ("property_type", "জমি", "জমি", 0),
    ("property_type", "বাড়ি", "বাড়ি", 1),
    ("property_type", "ফ্ল্যাট", "ফ্ল্যাট", 2),
    ("property_type", "প্লট", "প্লট", 3),
    ("property_type", "অন্যান্য", "অন্যান্য", 4),
    ("document_type", "খতিয়ান/পর্চা", "খতিয়ান/পর্চা", 0),
    ("document_type", "নামজারি/মিউটেশন", "নামজারি/মিউটেশন", 1),
    ("document_type", "খাজনা/কর রশিদ", "খাজনা/কর রশিদ", 2),
    ("document_type", "উত্তরাধিকার সনদ", "উত্তরাধিকার সনদ", 3),
]

config_list_items = sa.table(
    "config_list_items",
    sa.column("category", sa.String),
    sa.column("value", sa.String),
    sa.column("label", sa.String),
    sa.column("sort_order", sa.Integer),
    sa.column("is_active", sa.SmallInteger),
)


def upgrade() -> None:
    op.create_table(
        "config_list_items",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("category", sa.String(length=64), nullable=False),
        sa.Column("value", sa.String(length=255), nullable=False),
        sa.Column("label", sa.String(length=255), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_active", sa.SmallInteger(), nullable=False, server_default="1"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint("category", "value", name="uq_config_list_items_category_value"),
    )
    op.create_index("ix_config_list_items_category", "config_list_items", ["category"])
    op.create_index(
        "ix_config_list_items_category_active", "config_list_items", ["category", "is_active"]
    )

    op.bulk_insert(
        config_list_items,
        [
            {"category": c, "value": v, "label": l, "sort_order": s, "is_active": 1}
            for c, v, l, s in SEED_ITEMS
        ],
    )


def downgrade() -> None:
    op.drop_index("ix_config_list_items_category_active", table_name="config_list_items")
    op.drop_index("ix_config_list_items_category", table_name="config_list_items")
    op.drop_table("config_list_items")
