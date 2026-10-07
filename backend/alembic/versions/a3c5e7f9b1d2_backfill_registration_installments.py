"""backfill registration চাঁদা into installments

Revision ID: a3c5e7f9b1d2
Revises: d8f2b4c6a1e9
Create Date: 2026-10-08 00:00:00.000000

Already-approved members paid their first চাঁদা with the registration form,
but it was never recorded as an installment, so their চাঁদার ইতিহাস was
empty. Insert one PAID installment per such member unless that month is
already recorded.
"""
from types import SimpleNamespace
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

from app.services.registration_installment import build_registration_installment


# revision identifiers, used by Alembic.
revision: str = 'a3c5e7f9b1d2'
down_revision: Union[str, None] = 'd8f2b4c6a1e9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    members = conn.execute(
        sa.text(
            "SELECT id, subscription, submission_date, reviewed_at FROM members "
            "WHERE status = 'APPROVED'"
        )
    ).mappings().all()
    existing = {
        (row.member_id, row.year, row.month)
        for row in conn.execute(sa.text("SELECT member_id, year, month FROM installments"))
    }

    rows = []
    for member in members:
        installment = build_registration_installment(SimpleNamespace(**member))
        if installment is None:
            continue
        key = (installment.member_id, installment.year, installment.month)
        if key in existing:
            continue
        rows.append(
            {
                "member_id": installment.member_id,
                "year": installment.year,
                "month": installment.month,
                "amount": installment.amount,
                "paid_at": installment.paid_at,
            }
        )

    if rows:
        conn.execute(
            sa.text(
                "INSERT INTO installments (member_id, year, month, amount, status, paid_at) "
                "VALUES (:member_id, :year, :month, :amount, 'PAID', :paid_at)"
            ),
            rows,
        )


def downgrade() -> None:
    # Backfilled rows are indistinguishable from manually entered ones.
    pass
