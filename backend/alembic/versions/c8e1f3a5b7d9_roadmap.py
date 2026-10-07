"""society roadmap: roadmap_timeframes + roadmap_items + manage_roadmap permission

Revision ID: c8e1f3a5b7d9
Revises: b7d4e6f8a2c5
Create Date: 2026-10-08 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c8e1f3a5b7d9'
down_revision: Union[str, None] = 'b7d4e6f8a2c5'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

TIMEFRAME_SEED = [
    # (key, name_bn, name_en, window_bn, window_en, sort_order)
    ("short", "স্বল্পমেয়াদি পরিকল্পনা", "Short Term", "আগামী ১ মাস", "Next 1 month", 0),
    ("mid", "মধ্যমেয়াদি পরিকল্পনা", "Mid Term", "আগামী ৪ মাস", "Next 4 months", 1),
    ("long", "দীর্ঘমেয়াদি পরিকল্পনা", "Long Term", "আগামী ১ বছর", "Next 1 year", 2),
]

# Starting content from the committee brief. Everything enters as 'planned';
# the committee sets real progress from the admin screen.
ITEM_SEED = {
    "short": [
        "সদস্য নিবন্ধন কার্যক্রম সম্পন্ন করা",
        "গঠনতন্ত্র চূড়ান্ত করে সমাজসেবা অধিদপ্তরে জমা দেওয়া",
        "সংগঠনের নামের ক্লিয়ারেন্সের জন্য আবেদন করা",
        "ব্যাংক অ্যাকাউন্ট খোলার প্রক্রিয়া শুরু করা",
        "অফিসের জন্য জায়গা চূড়ান্ত করা",
        "মাসিক চাঁদা ও রেজিস্ট্রেশন ফি নির্ধারণে ভোটিং করা",
        "ওয়েবসাইটের প্রাথমিক কাজ সম্পন্ন করা",
    ],
    "mid": [
        "সরকারি অনুমোদন (রেজিস্ট্রেশন) প্রাপ্তি",
        "অফিস চালু করা ও স্টাফ নিয়োগ",
        "সদস্যদের জন্য ট্রান্সপারেন্সি ফিচারসহ ওয়েবসাইট চালু",
        "শীতের শুরুতে পিকনিক আয়োজন",
        "বালু ভরাট ও প্লট ডিমার্কেশন কার্যক্রম শুরু",
        "সাইনবোর্ড স্থাপন—সংগঠনের নাম ও মেম্বার আইডিসহ",
        "ওয়েস্টার্ন ভ্যালির বিরুদ্ধে আইনি পদক্ষেপের প্রস্তুতি",
        "মাসিক অনলাইন মিটিং চালু রাখা",
    ],
    "long": [
        "কাউন্দিয়া এলাকার সম্পূর্ণ বালু ভরাট ও প্লট ডিমার্কেশন সম্পন্ন করা",
        "রাস্তা ও যোগাযোগ ব্যবস্থার উন্নয়ন",
        "রাতের আলো ব্যবস্থা করা",
        "সদস্যদের জন্য সফর কার্ড চালু করা",
        "সমাজসেবামূলক কার্যক্রম শুরু করা",
        "এলাকার জনপ্রতিনিধিদের সাথে সমন্বয় করে উন্নয়ন কাজ এগিয়ে নেওয়া",
        "ওয়েস্টার্ন ভ্যালির প্রতারণার বিরুদ্ধে চূড়ান্ত আইনি লড়াই",
        "সংগঠনের সদস্য সংখ্যা বৃদ্ধি ও শক্তিশালী কমিটি গঠন",
        "বাৎসরিক আর্থিক রিপোর্ট প্রকাশ ও সাধারণ সভা আয়োজন",
    ],
}

timeframes_table = sa.table(
    "roadmap_timeframes",
    sa.column("id", sa.Integer),
    sa.column("key", sa.String),
    sa.column("name_bn", sa.String),
    sa.column("name_en", sa.String),
    sa.column("target_window_bn", sa.String),
    sa.column("target_window_en", sa.String),
    sa.column("sort_order", sa.Integer),
)

items_table = sa.table(
    "roadmap_items",
    sa.column("timeframe_id", sa.Integer),
    sa.column("text", sa.String),
    sa.column("status", sa.String),
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
        "roadmap_timeframes",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("key", sa.String(length=16), nullable=False, unique=True),
        sa.Column("name_bn", sa.String(length=120), nullable=False),
        sa.Column("name_en", sa.String(length=120), nullable=False),
        sa.Column("target_window_bn", sa.String(length=60), nullable=False),
        sa.Column("target_window_en", sa.String(length=60), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now()
        ),
    )
    op.create_table(
        "roadmap_items",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column(
            "timeframe_id",
            sa.Integer(),
            sa.ForeignKey("roadmap_timeframes.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column("text", sa.String(length=500), nullable=False),
        sa.Column("status", sa.String(length=16), nullable=False, server_default="planned"),
        sa.Column("target_date", sa.Date(), nullable=True),
        sa.Column("owner", sa.String(length=120), nullable=True),
        sa.Column("note", sa.String(length=1000), nullable=True),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("completed_at", sa.Date(), nullable=True),
        sa.Column("is_active", sa.SmallInteger(), nullable=False, server_default="1"),
        sa.Column("archived_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_by", sa.Integer(), sa.ForeignKey("admin_users.id", ondelete="SET NULL"), nullable=True
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now()
        ),
    )
    op.create_index(
        "ix_roadmap_items_timeframe_active", "roadmap_items", ["timeframe_id", "is_active", "sort_order"]
    )

    conn = op.get_bind()
    for key, name_bn, name_en, window_bn, window_en, order in TIMEFRAME_SEED:
        timeframe_id = conn.execute(
            timeframes_table.insert()
            .values(
                key=key,
                name_bn=name_bn,
                name_en=name_en,
                target_window_bn=window_bn,
                target_window_en=window_en,
                sort_order=order,
            )
            .returning(timeframes_table.c.id)
        ).scalar_one()
        conn.execute(
            items_table.insert(),
            [
                {"timeframe_id": timeframe_id, "text": text, "status": "planned", "sort_order": i, "is_active": 1}
                for i, text in enumerate(ITEM_SEED[key])
            ],
        )

    # Same three roles that steward notices and finance keep the roadmap.
    perm_id = conn.execute(
        permissions_table.insert()
        .values(
            key="manage_roadmap",
            resource="roadmap",
            action="manage",
            description="Add, edit, reorder and update the status of society roadmap items",
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
        sa.select(permissions_table.c.id).where(permissions_table.c.key == "manage_roadmap")
    ).scalar_one_or_none()
    if perm_id is not None:
        conn.execute(role_permissions_table.delete().where(role_permissions_table.c.permission_id == perm_id))
        conn.execute(permissions_table.delete().where(permissions_table.c.id == perm_id))
    op.drop_index("ix_roadmap_items_timeframe_active", table_name="roadmap_items")
    op.drop_table("roadmap_items")
    op.drop_table("roadmap_timeframes")
