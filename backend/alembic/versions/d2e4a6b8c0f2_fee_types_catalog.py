"""fee_types catalog table for the generic Fee Settings screen

Revision ID: d2e4a6b8c0f2
Revises: b7c2e9f4a1d3
Create Date: 2026-10-11

Creates the admin-managed `fee_types` table (open-ended fee definitions with
label, calculation type, unit, recurring/pay-once flags, installment/other
grouping and an active flag) and seeds the fees that were previously
hard-coded in the Fee Settings UI. The rates themselves stay in the existing
versioned `fee_settings` rows, so all history is preserved untouched:

- monthly_subscription -> tiered (monthly_subscription_base_amount /
  _additional_rate / _base_threshold)
- admission_fee        -> fixed (admission_fee)
- picnic_fee           -> head+additional (picnic_head_fee /
  picnic_additional_head_fee via the explicit setting-key columns)
"""

from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "d2e4a6b8c0f2"
down_revision: Union[str, Sequence[str], None] = "b7c2e9f4a1d3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

SEED_ROWS = [
    {
        "key": "monthly_subscription",
        "label_bn": "মাসিক সাবস্ক্রিপশন ফি",
        "label_en": "Monthly Subscription Rate",
        "calculation_type": "tiered",
        "is_recurring": True,
        "is_pay_once": False,
        "fee_category": "installment",
        "sort_order": 0,
    },
    {
        "key": "admission_fee",
        "label_bn": "ভর্তি ফি",
        "label_en": "Admission Fee",
        "calculation_type": "fixed",
        "is_recurring": False,
        "is_pay_once": True,
        "fee_category": "other",
        "sort_order": 1,
    },
    {
        "key": "picnic_fee",
        "label_bn": "পিকনিক ফি",
        "label_en": "Picnic Fee",
        "calculation_type": "head_additional",
        "is_recurring": False,
        "is_pay_once": True,
        "fee_category": "other",
        "head_setting_key": "picnic_head_fee",
        "additional_setting_key": "picnic_additional_head_fee",
        "sort_order": 2,
    },
]


def upgrade() -> None:
    op.create_table(
        "fee_types",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("key", sa.String(64), nullable=False),
        sa.Column("label_bn", sa.String(128), nullable=False),
        sa.Column("label_en", sa.String(128), nullable=False),
        sa.Column("calculation_type", sa.String(32), nullable=False, server_default="fixed"),
        sa.Column("unit", sa.String(32), nullable=False, server_default="taka"),
        sa.Column("is_recurring", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("is_pay_once", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("fee_category", sa.String(32), nullable=False, server_default="other"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("head_setting_key", sa.String(64), nullable=True),
        sa.Column("additional_setting_key", sa.String(64), nullable=True),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column(
            "created_by",
            sa.Integer(),
            sa.ForeignKey("admin_users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
    )
    op.create_index("ix_fee_types_key", "fee_types", ["key"], unique=True)

    insert_stmt = sa.text(
        "INSERT INTO fee_types (key, label_bn, label_en, calculation_type, unit,"
        " is_recurring, is_pay_once, fee_category, is_active, head_setting_key,"
        " additional_setting_key, sort_order)"
        " VALUES (:key, :label_bn, :label_en, :calculation_type, 'taka',"
        " :is_recurring, :is_pay_once, :fee_category, true, :head_setting_key,"
        " :additional_setting_key, :sort_order)"
    )
    bind = op.get_bind()
    for row in SEED_ROWS:
        bind.execute(
            insert_stmt,
            {
                **row,
                "head_setting_key": row.get("head_setting_key"),
                "additional_setting_key": row.get("additional_setting_key"),
            },
        )


def downgrade() -> None:
    op.drop_index("ix_fee_types_key", table_name="fee_types")
    op.drop_table("fee_types")
