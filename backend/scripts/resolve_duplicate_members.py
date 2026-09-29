"""Resolve non-rejected members that collide on nid/mobile/email.

Migration d4e6f8a0b2c4 adds a partial unique index per identifier (nid,
mobile, email) scoped to non-REJECTED members, and refuses to run while such
a collision exists. This script clears that blocker automatically: for each
group of non-rejected members sharing the same normalized identifier, the
most recently created member is kept as-is and every older member in that
group is marked REJECTED (with a rejection_reason explaining why), so a human
can still review and reinstate one manually afterwards.

Normalization matches app/services/normalization.py and the migration itself:
nid/mobile keep digits only, email is lowercased and trimmed.

This runs BEFORE `alembic upgrade head` (scripts/migrate.sh), so the database
may lag the current models. Queries therefore touch only columns that have
existed since the initial schema - selecting whole ORM entities would compile
SQL for newer columns (e.g. members.notification_status) that do not exist
yet. On a fresh database with no members table it is a no-op.

Usage:
    python -m scripts.resolve_duplicate_members            # dry run, prints a report
    python -m scripts.resolve_duplicate_members --apply     # writes the fixes to the DB
"""

import argparse
import asyncio
import re
from collections import defaultdict

from sqlalchemy import inspect, select, update

from app.db.session import AsyncSessionLocal
from app.models.member import Member, MemberStatus

_IDENTIFIERS = ("nid", "mobile", "email")

# Columns present since the initial schema; see module docstring.
_MEMBER_COLUMNS = (Member.id, Member.nid, Member.mobile, Member.email, Member.created_at)


def _normalize(column: str, value: str) -> str:
    if column == "email":
        return value.strip().lower()
    return re.sub(r"\D", "", value)


async def resolve(apply: bool) -> None:
    async with AsyncSessionLocal() as db:
        has_members_table = await db.run_sync(
            lambda session: inspect(session.connection()).has_table("members")
        )
        if not has_members_table:
            print("members table does not exist yet - nothing to resolve")
            return

        rows = (
            await db.execute(
                select(*_MEMBER_COLUMNS).where(Member.status != MemberStatus.REJECTED)
            )
        ).all()

        rejected_ids: set[int] = set()
        updates: list[dict] = []

        for column in _IDENTIFIERS:
            groups: dict[str, list] = defaultdict(list)
            for row in rows:
                if row.id in rejected_ids:
                    continue
                key = _normalize(column, getattr(row, column))
                groups[key].append(row)

            for key, group in groups.items():
                if len(group) < 2:
                    continue
                group.sort(key=lambda r: r.created_at)
                keep = group[-1]
                losers = group[:-1]
                print(
                    f"[{column}={key!r}] keeping member id={keep.id} "
                    f"(created_at={keep.created_at}), rejecting "
                    f"{[r.id for r in losers]}"
                )
                for member in losers:
                    rejected_ids.add(member.id)
                    if apply:
                        updates.append(
                            {
                                "id": member.id,
                                "status": MemberStatus.REJECTED,
                                "rejection_reason": (
                                    "Auto-rejected by scripts/resolve_duplicate_members.py: "
                                    f"duplicate {column} ({key}) with member id={keep.id}"
                                ),
                            }
                        )

        if apply and updates:
            await db.execute(update(Member), updates)
            await db.commit()

        print(
            f"\n{len(rejected_ids)} member(s) "
            f"{'rejected' if apply else 'would be rejected'}"
            + ("" if apply else " (dry run — pass --apply to write changes)")
        )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--apply", action="store_true", help="Write status changes to the database"
    )
    args = parser.parse_args()
    asyncio.run(resolve(apply=args.apply))
