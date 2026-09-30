"""Dry-run preview (or one-shot apply) of the KAM-YYYY-NNNN -> UKAMKS-N
member id renumbering.

Usage (run from backend/ with the project venv):
    python scripts/migrate_member_ids.py            # dry-run: prints the mapping, writes nothing
    python scripts/migrate_member_ids.py --apply    # performs the same rewrite inside one transaction

The database is taken from DATABASE_URL (defaults to the app config, usually
sqlite dev.db). The authoritative, versioned change lives in alembic revision
b8e2c4a6d9f1 — prefer `alembic upgrade head`; this script exists so the
mapping can be reviewed before migrating and to apply it in environments
managed outside alembic.
"""
import argparse
import asyncio
import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from sqlalchemy import text  # noqa: E402

UKAMKS_PATTERN = re.compile(r"^UKAMKS-\d+$")


async def compute_mapping(conn) -> list[tuple[int, str, str]]:
    rows = (await conn.execute(
        text("SELECT id, member_id, reviewed_at, created_at FROM members")
    )).fetchall()
    approved = sorted(
        (r for r in rows if r[1] is not None),
        key=lambda r: (r[2] or r[3], r[0]),
    )
    mapping = []
    n = 0
    for pk, old_id, _reviewed, _created in approved:
        if UKAMKS_PATTERN.match(old_id):
            continue
        n += 1
        mapping.append((pk, old_id, f"UKAMKS-{n}"))
    return mapping


async def main(apply: bool) -> None:
    from app.db.session import engine

    async with engine.begin() as conn:
        mapping = await compute_mapping(conn)
        if not mapping:
            print("Nothing to do: no KAM-style member ids found.")
            return

        print(f"{'member pk':>10}  {'old id':<16} -> new id")
        for pk, old_id, new_id in mapping:
            print(f"{pk:>10}  {old_id:<16} -> {new_id}")
        print(f"\n{len(mapping)} member id(s) would be renumbered; "
              f"sequence will be seeded to {len(mapping)}.")

        if not apply:
            print("\nDry run only — no rows were written. Re-run with --apply to execute.")
            return

        await conn.execute(text(
            "CREATE TABLE IF NOT EXISTS member_id_sequence ("
            "id INTEGER PRIMARY KEY, value INTEGER NOT NULL)"
        ))
        await conn.execute(text(
            "CREATE TABLE IF NOT EXISTS member_id_migrations ("
            "id INTEGER PRIMARY KEY AUTOINCREMENT, "
            "member_pk INTEGER NOT NULL, "
            "old_member_id VARCHAR(32) NOT NULL, "
            "new_member_id VARCHAR(32) NOT NULL, "
            "migrated_at DATETIME DEFAULT CURRENT_TIMESTAMP)"
        ))
        for pk, old_id, new_id in mapping:
            await conn.execute(text(
                "UPDATE members SET member_id = :new WHERE id = :pk"
            ), {"new": new_id, "pk": pk})
            await conn.execute(text(
                "UPDATE member_credentials SET username = :username "
                "WHERE member_id = :pk AND username = :old_username"
            ), {"username": new_id.lower(), "pk": pk, "old_username": old_id.lower()})
            await conn.execute(text(
                "UPDATE audit_logs SET detail = REPLACE(detail, :old, :new) "
                "WHERE detail LIKE :needle"
            ), {"old": old_id, "new": new_id, "needle": f"%{old_id}%"})
            await conn.execute(text(
                "INSERT INTO member_id_migrations (member_pk, old_member_id, new_member_id) "
                "VALUES (:pk, :old, :new)"
            ), {"pk": pk, "old": old_id, "new": new_id})
            await conn.execute(text(
                "INSERT INTO audit_logs (actor_admin_id, action, entity_type, entity_id, detail) "
                "VALUES (NULL, 'member.member_id_migration', 'member', :pk, :detail)"
            ), {"pk": str(pk), "detail": f"member id renumbered {old_id} -> {new_id}"})
        await conn.execute(text(
            "DELETE FROM member_id_sequence"
        ))
        await conn.execute(text(
            "INSERT INTO member_id_sequence (id, value) VALUES (1, :v)"
        ), {"v": len(mapping)})
        print(f"Applied: {len(mapping)} member id(s) renumbered, sequence seeded to {len(mapping)}.")

    await engine.dispose()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apply", action="store_true", help="write the changes (default: dry run)")
    args = parser.parse_args()
    asyncio.run(main(args.apply))
