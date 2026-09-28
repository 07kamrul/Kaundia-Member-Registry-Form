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

Usage:
    python -m scripts.resolve_duplicate_members            # dry run, prints a report
    python -m scripts.resolve_duplicate_members --apply     # writes the fixes to the DB
"""

import argparse
import asyncio
import re
from collections import defaultdict

from sqlalchemy import select

from app.db.session import AsyncSessionLocal
from app.models.member import Member, MemberStatus

_IDENTIFIERS = ("nid", "mobile", "email")


def _normalize(column: str, value: str) -> str:
    if column == "email":
        return value.strip().lower()
    return re.sub(r"\D", "", value)


async def resolve(apply: bool) -> None:
    async with AsyncSessionLocal() as db:
        members = (
            await db.execute(
                select(Member).where(Member.status != MemberStatus.REJECTED)
            )
        ).scalars().all()

        rejected_ids: set[int] = set()

        for column in _IDENTIFIERS:
            groups: dict[str, list[Member]] = defaultdict(list)
            for member in members:
                if member.id in rejected_ids:
                    continue
                key = _normalize(column, getattr(member, column))
                groups[key].append(member)

            for key, group in groups.items():
                if len(group) < 2:
                    continue
                group.sort(key=lambda m: m.created_at)
                keep = group[-1]
                losers = group[:-1]
                print(
                    f"[{column}={key!r}] keeping member id={keep.id} "
                    f"(created_at={keep.created_at}), rejecting "
                    f"{[m.id for m in losers]}"
                )
                for member in losers:
                    rejected_ids.add(member.id)
                    if apply:
                        member.status = MemberStatus.REJECTED
                        member.rejection_reason = (
                            "Auto-rejected by scripts/resolve_duplicate_members.py: "
                            f"duplicate {column} ({key}) with member id={keep.id}"
                        )

        if apply and rejected_ids:
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
