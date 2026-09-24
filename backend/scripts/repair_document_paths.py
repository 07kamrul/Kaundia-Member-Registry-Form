"""Repair ApplicableDoc.file_path rows left broken by the doc-type slash bug.

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

from sqlalchemy import select

from app.core.config import get_settings
from app.db.session import AsyncSessionLocal
from app.models.property import ApplicableDoc

settings = get_settings()


def _upload_root() -> Path:
    return Path(settings.upload_dir)


def _find_by_basename(root: Path, basename: str) -> list[Path]:
    return [p for p in root.rglob(basename) if p.is_file()]


async def repair(apply: bool) -> None:
    root = _upload_root()
    async with AsyncSessionLocal() as db:
        result = await db.execute(
            select(ApplicableDoc).where(ApplicableDoc.file_path.is_not(None))
        )
        docs = result.scalars().all()

        missing = 0
        fixed = 0
        unresolved = 0

        for doc in docs:
            stored_path = root / doc.file_path
            if stored_path.is_file():
                continue
            nfd_path = root / unicodedata.normalize("NFD", doc.file_path)
            if nfd_path.is_file():
                candidates = [nfd_path]
            else:
                missing += 1
                basename = Path(doc.file_path).name
                candidates = _find_by_basename(root, basename)

            if len(candidates) != 1:
                unresolved += 1
                print(
                    f"[UNRESOLVED] doc id={doc.id} doc_type={doc.doc_type!r} "
                    f"file_path={doc.file_path!r} -> {len(candidates)} candidate(s) found on disk"
                )
                continue

            new_relative = str(candidates[0].relative_to(root))
            print(
                f"[FIX] doc id={doc.id} doc_type={doc.doc_type!r} "
                f"file_path={doc.file_path!r} -> {new_relative!r}"
            )
            if apply:
                doc.file_path = new_relative
                fixed += 1

        if apply and fixed:
            await db.commit()

        print(
            f"\n{len(docs)} document(s) checked, {missing} missing on their stored path, "
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
