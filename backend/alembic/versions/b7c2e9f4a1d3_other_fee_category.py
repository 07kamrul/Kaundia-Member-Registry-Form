"""fee_category flag on fee_settings for the Other Fees page

Revision ID: b7c2e9f4a1d3
Revises: a8c3f5d7b2e9
Create Date: 2026-10-11

Adds `fee_settings.fee_category` ('other' | 'installment'), so the member
"Other Fees" page decides which fee types are payable there from
configuration instead of a hard-coded name list. Every existing row is
'other' except the installment suggested amount, and new fee setting
versions default to 'other' unless the committee marks them 'installment'.
"""

from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "b7c2e9f4a1d3"
down_revision: Union[str, Sequence[str], None] = "a8c3f5d7b2e9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    with op.batch_alter_table("fee_settings") as batch:
        batch.add_column(
            sa.Column("fee_category", sa.String(32), nullable=False, server_default="other")
        )
    op.execute(
        "UPDATE fee_settings SET fee_category = 'installment' WHERE key = 'fee_installment_amount'"
    )


def downgrade() -> None:
    with op.batch_alter_table("fee_settings") as batch:
        batch.drop_column("fee_category")
