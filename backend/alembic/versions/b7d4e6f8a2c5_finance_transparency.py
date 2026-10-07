"""fund transparency: financial_transactions + finance categories + manage_finance permission

Revision ID: b7d4e6f8a2c5
Revises: a3c5e7f9b1d2
Create Date: 2026-10-08 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b7d4e6f8a2c5'
down_revision: Union[str, None] = 'a3c5e7f9b1d2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

INCOME_CATEGORY_SEED = [
    ("finance_income_category", "চাঁদা", "চাঁদা", 0),
    ("finance_income_category", "ভর্তি ফি", "ভর্তি ফি", 1),
    ("finance_income_category", "পিকনিক ফি", "পিকনিক ফি", 2),
    ("finance_income_category", "অনুদান", "অনুদান", 3),
    ("finance_income_category", "অন্যান্য আয়", "অন্যান্য আয়", 4),
]

EXPENSE_CATEGORY_SEED = [
    ("finance_expense_category", "রক্ষণাবেক্ষণ", "রক্ষণাবেক্ষণ", 0),
    ("finance_expense_category", "নিরাপত্তা", "নিরাপত্তা", 1),
    ("finance_expense_category", "বিদ্যুৎ বিল", "বিদ্যুৎ বিল", 2),
    ("finance_expense_category", "অনুষ্ঠান", "অনুষ্ঠান", 3),
    ("finance_expense_category", "পিকনিক খরচ", "পিকনিক খরচ", 4),
    ("finance_expense_category", "অফিস খরচ", "অফিস খরচ", 5),
    ("finance_expense_category", "অন্যান্য ব্যয়", "অন্যান্য ব্যয়", 6),
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
        "financial_transactions",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("txn_date", sa.Date(), nullable=False),
        sa.Column("type", sa.String(length=8), nullable=False),
        sa.Column(
            "category_id",
            sa.Integer(),
            sa.ForeignKey("config_list_items.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("description", sa.String(length=2000), nullable=False),
        sa.Column("reference_no", sa.String(length=64), nullable=True),
        sa.Column("attachment_url", sa.String(length=512), nullable=True),
        sa.Column("status", sa.String(length=16), nullable=False, server_default="pending"),
        sa.Column("rejection_reason", sa.String(length=500), nullable=True),
        sa.Column("internal_notes", sa.String(length=2000), nullable=True),
        sa.Column("linked_payment_type", sa.String(length=24), nullable=True),
        sa.Column("linked_payment_id", sa.Integer(), nullable=True),
        sa.Column(
            "reversal_of_id",
            sa.Integer(),
            sa.ForeignKey("financial_transactions.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "created_by", sa.Integer(), sa.ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True
        ),
        sa.Column(
            "approved_by", sa.Integer(), sa.ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True
        ),
        sa.Column("approved_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("is_active", sa.SmallInteger(), nullable=False, server_default="1"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            onupdate=sa.func.now(),
        ),
    )
    op.create_index("ix_financial_transactions_txn_date", "financial_transactions", ["txn_date"])
    op.create_index("ix_financial_transactions_type", "financial_transactions", ["type"])
    op.create_index("ix_financial_transactions_category_id", "financial_transactions", ["category_id"])
    op.create_index("ix_financial_transactions_reference_no", "financial_transactions", ["reference_no"])
    op.create_index("ix_financial_transactions_status_active", "financial_transactions", ["status", "is_active"])
    # A payment record can back at most one live ledger row, and a reference
    # number is unique whenever set; NULLs must not collide (partial indexes).
    op.create_index(
        "uq_financial_transactions_payment_link",
        "financial_transactions",
        ["linked_payment_type", "linked_payment_id"],
        unique=True,
        postgresql_where=sa.text("linked_payment_type IS NOT NULL"),
        sqlite_where=sa.text("linked_payment_type IS NOT NULL"),
    )
    op.create_index(
        "uq_financial_transactions_reference_no",
        "financial_transactions",
        ["reference_no"],
        unique=True,
        postgresql_where=sa.text("reference_no IS NOT NULL"),
        sqlite_where=sa.text("reference_no IS NOT NULL"),
    )

    op.bulk_insert(
        config_list_items,
        [
            {"category": c, "value": v, "label": l, "sort_order": s, "is_active": 1}
            for seed in (INCOME_CATEGORY_SEED, EXPENSE_CATEGORY_SEED)
            for c, v, l, s in seed
        ],
    )

    # Same grant pattern as manage_costs: super_admin by convention, executive
    # committee manages society money; administrator joins because the fund
    # workflow mirrors the fee-manager role list (manage_fee_settings).
    conn = op.get_bind()
    perm_id = conn.execute(
        permissions_table.insert()
        .values(
            key="manage_finance",
            resource="finance",
            action="manage",
            description="Record, edit and approve fund transactions in the transparency ledger",
        )
        .returning(permissions_table.c.id)
    ).scalar_one()
    role_ids = conn.execute(
        sa.select(roles_table.c.id).where(
            roles_table.c.name.in_(["super_admin", "executive_committee", "administrator"])
        )
    ).scalars().all()
    if role_ids:
        conn.execute(
            role_permissions_table.insert(),
            [{"role_id": rid, "permission_id": perm_id} for rid in role_ids],
        )


def downgrade() -> None:
    conn = op.get_bind()
    perm_id = conn.execute(
        sa.select(permissions_table.c.id).where(permissions_table.c.key == "manage_finance")
    ).scalar_one_or_none()
    if perm_id is not None:
        conn.execute(role_permissions_table.delete().where(role_permissions_table.c.permission_id == perm_id))
        conn.execute(permissions_table.delete().where(permissions_table.c.id == perm_id))
    conn.execute(
        config_list_items.delete().where(
            config_list_items.c.category.in_(["finance_income_category", "finance_expense_category"])
        )
    )
    op.drop_index("uq_financial_transactions_reference_no", table_name="financial_transactions")
    op.drop_index("uq_financial_transactions_payment_link", table_name="financial_transactions")
    op.drop_index("ix_financial_transactions_status_active", table_name="financial_transactions")
    op.drop_index("ix_financial_transactions_reference_no", table_name="financial_transactions")
    op.drop_index("ix_financial_transactions_category_id", table_name="financial_transactions")
    op.drop_index("ix_financial_transactions_type", table_name="financial_transactions")
    op.drop_index("ix_financial_transactions_txn_date", table_name="financial_transactions")
    op.drop_table("financial_transactions")
