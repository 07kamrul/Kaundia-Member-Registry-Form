"""society costs + member cost splits

Revision ID: d8f2b4c6a1e9
Revises: a9c3e5f1b7d2
Create Date: 2026-10-07 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd8f2b4c6a1e9'
down_revision: Union[str, None] = 'a9c3e5f1b7d2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

COST_CATEGORY_SEED = [
    ("cost_category", "সংরক্ষণ/মেরামত", "সংরক্ষণ/মেরামত", 0),
    ("cost_category", "ইউটিলিটি বিল", "ইউটিলিটি বিল", 1),
    ("cost_category", "বেতন/সম্মানী", "বেতন/সম্মানী", 2),
    ("cost_category", "ইভেন্ট খরচ", "ইভেন্ট খরচ", 3),
    ("cost_category", "আইনি/রেজিস্ট্রেশন ফি", "আইনি/রেজিস্ট্রেশন ফি", 4),
    ("cost_category", "অফিস/প্রশাসনিক", "অফিস/প্রশাসনিক", 5),
    ("cost_category", "বীমা", "বীমা", 6),
    ("cost_category", "জরুরি খরচ", "জরুরি খরচ", 7),
    ("cost_category", "অন্যান্য", "অন্যান্য", 8),
]

config_list_items = sa.table(
    "config_list_items",
    sa.column("category", sa.String),
    sa.column("value", sa.String),
    sa.column("label", sa.String),
    sa.column("sort_order", sa.Integer),
    sa.column("is_active", sa.SmallInteger),
)

permissions_table = sa.table(
    "permissions",
    sa.column("id", sa.Integer),
    sa.column("key", sa.String),
    sa.column("resource", sa.String),
    sa.column("action", sa.String),
    sa.column("description", sa.String),
)

role_permissions_table = sa.table(
    "role_permissions", sa.column("role_id", sa.Integer), sa.column("permission_id", sa.Integer)
)

roles_table = sa.table("roles", sa.column("id", sa.Integer), sa.column("name", sa.String))


def upgrade() -> None:
    op.create_table(
        "society_costs",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("description", sa.String(length=2000), nullable=True),
        sa.Column(
            "category_id",
            sa.Integer(),
            sa.ForeignKey("config_list_items.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("total_amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("incurred_date", sa.Date(), nullable=False),
        sa.Column("payment_source", sa.String(length=32), nullable=False, server_default="society_fund"),
        sa.Column("receipt_file_url", sa.String(length=512), nullable=True),
        sa.Column("notes", sa.String(length=2000), nullable=True),
        sa.Column(
            "created_by", sa.Integer(), sa.ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            onupdate=sa.func.now(),
        ),
    )
    op.create_index("ix_society_costs_category_id", "society_costs", ["category_id"])
    op.create_index("ix_society_costs_incurred_date", "society_costs", ["incurred_date"])

    op.create_table(
        "cost_splits",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column(
            "society_cost_id",
            sa.Integer(),
            sa.ForeignKey("society_costs.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("split_method", sa.String(length=32), nullable=False),
        sa.Column(
            "created_by", sa.Integer(), sa.ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_index("ix_cost_splits_society_cost_id", "cost_splits", ["society_cost_id"])

    op.create_table(
        "cost_split_shares",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column(
            "cost_split_id",
            sa.Integer(),
            sa.ForeignKey("cost_splits.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "member_id", sa.Integer(), sa.ForeignKey("members.id", ondelete="CASCADE"), nullable=False
        ),
        sa.Column("amount_due", sa.Numeric(12, 2), nullable=False),
        sa.Column("amount_paid", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("status", sa.String(length=16), nullable=False, server_default="unpaid"),
        sa.Column("paid_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "payment_method_id",
            sa.Integer(),
            sa.ForeignKey("config_list_items.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("receipt_no", sa.String(length=64), nullable=True),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            onupdate=sa.func.now(),
        ),
    )
    op.create_index("ix_cost_split_shares_cost_split_id", "cost_split_shares", ["cost_split_id"])
    op.create_index("ix_cost_split_shares_member_id", "cost_split_shares", ["member_id"])

    op.bulk_insert(
        config_list_items,
        [
            {"category": c, "value": v, "label": l, "sort_order": s, "is_active": 1}
            for c, v, l, s in COST_CATEGORY_SEED
        ],
    )

    # Grant the new manage_costs permission to every role that already holds
    # manage_notices' siblings: super_admin gets everything by convention, the
    # executive committee manages society money (same tier as manage_fee_settings).
    conn = op.get_bind()
    perm_id = conn.execute(
        permissions_table.insert()
        .values(
            key="manage_costs",
            resource="cost",
            action="manage",
            description="Record society costs, split them among members and collect payments",
        )
        .returning(permissions_table.c.id)
    ).scalar_one()
    role_ids = conn.execute(
        sa.select(roles_table.c.id).where(roles_table.c.name.in_(["super_admin", "executive_committee"]))
    ).scalars().all()
    if role_ids:
        conn.execute(
            role_permissions_table.insert(),
            [{"role_id": rid, "permission_id": perm_id} for rid in role_ids],
        )


def downgrade() -> None:
    conn = op.get_bind()
    perm_id = conn.execute(
        sa.select(permissions_table.c.id).where(permissions_table.c.key == "manage_costs")
    ).scalar_one_or_none()
    if perm_id is not None:
        conn.execute(role_permissions_table.delete().where(role_permissions_table.c.permission_id == perm_id))
        conn.execute(permissions_table.delete().where(permissions_table.c.id == perm_id))
    conn.execute(
        config_list_items.delete().where(config_list_items.c.category == "cost_category")
    )
    op.drop_index("ix_cost_split_shares_member_id", table_name="cost_split_shares")
    op.drop_index("ix_cost_split_shares_cost_split_id", table_name="cost_split_shares")
    op.drop_table("cost_split_shares")
    op.drop_index("ix_cost_splits_society_cost_id", table_name="cost_splits")
    op.drop_table("cost_splits")
    op.drop_index("ix_society_costs_incurred_date", table_name="society_costs")
    op.drop_index("ix_society_costs_category_id", table_name="society_costs")
    op.drop_table("society_costs")
