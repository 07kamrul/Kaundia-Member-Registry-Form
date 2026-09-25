"""Repair stored upload paths (ApplicableDoc.file_path, Member photo/receipt) —
rows left broken by the doc-type slash bug.

Before the fix in app/services/storage.py, sanitize_path_segment() stripped
'/' out of doc-type labels instead of replacing it, so a label like
"খাজনা/কর রশিদ" collapsed into a single merged folder name
"খাজনাকর রশিদ". On some filesystems the Unicode form written to disk
(NFC vs NFD) can also drift from what's stored in the DB, so a file that
exists on disk can still 404 through the static file server.

This script finds ApplicableDoc rows whose file_path doesn't resolve to a
real file on disk, searches the uploads directory for a file with the same
filename (the saved name is a random uuid4 hex, so a basename match is
unambiguous), and reports (or applies) the corrected file_path.

Usage:
    python -m scripts.repair_document_paths            # dry run, prints a report
    python -m scripts.repair_document_paths --apply     # writes the fixes to the DB
"""

import argparse
import asyncio
import unicodedata
from pathlib import Path

from sqlalchemy import or_, select

from app.core.config import get_settings
from app.db.session import AsyncSessionLocal
from app.models.member import Member
from app.models.property import ApplicableDoc

settings = get_settings()


def _upload_root() -> Path:
    return Path(settings.upload_dir)


def _find_by_basename(root: Path, basename: str) -> list[Path]:
    return [p for p in root.rglob(basename) if p.is_file()]


def _resolve(root: Path, stored: str) -> tuple[bool, list[Path]]:
    """Return (was_missing, candidates) for a stored relative path."""
    if (root / stored).is_file():
        return False, []
    nfd_path = root / unicodedata.normalize("NFD", stored)
    if nfd_path.is_file():
        return False, [nfd_path]
    return True, _find_by_basename(root, Path(stored).name)


def _targets(docs, members):
    """Yield (label, row, attribute) for every stored upload path."""
    for doc in docs:
        yield f"doc id={doc.id} doc_type={doc.doc_type!r}", doc, "file_path"
    for member in members:
        for attr in ("member_photo_path", "receipt_photo_path"):
            if getattr(member, attr):
                yield f"member id={member.id} {attr}", member, attr


async def repair(apply: bool) -> None:
    root = _upload_root()
    async with AsyncSessionLocal() as db:
        docs = (
            await db.execute(select(ApplicableDoc).where(ApplicableDoc.file_path.is_not(None)))
        ).scalars().all()
        members = (
            await db.execute(
                select(Member).where(
                    or_(Member.member_photo_path.is_not(None), Member.receipt_photo_path.is_not(None))
                )
            )
        ).scalars().all()

        checked = missing = fixed = unresolved = 0

        for label, row, attr in _targets(docs, members):
            checked += 1
            stored = getattr(row, attr)
            was_missing, candidates = _resolve(root, stored)
            if not was_missing and not candidates:
                continue
            missing += was_missing

            if len(candidates) != 1:
                unresolved += 1
                print(
                    f"[UNRESOLVED] {label} path={stored!r} "
                    f"-> {len(candidates)} candidate(s) found on disk"
                )
                continue

            new_relative = str(candidates[0].relative_to(root))
            print(f"[FIX] {label} path={stored!r} -> {new_relative!r}")
            if apply:
                setattr(row, attr, new_relative)
                fixed += 1

        if apply and fixed:
            await db.commit()

        print(
            f"\n{checked} file path(s) checked, {missing} missing on their stored path, "
            f"{fixed if apply else 0} fixed"
            + ("" if apply else " (dry run — pass --apply to write changes)")
        )
        if unresolved:
            print(f"{unresolved} could not be resolved automatically and need manual review.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--apply", action="store_true", help="Write corrected file_path values to the database"
    )
    args = parser.parse_args()
    asyncio.run(repair(apply=args.apply))
