"""Repair stored upload paths (ApplicableDoc.file_path, Member photo/receipt).

Two classes of damage are healed:

1. Broken rows - the doc-type slash bug. Before the fix in
   app/services/storage.py, sanitize_path_segment() stripped '/' out of
   doc-type labels instead of replacing it, so a label like "খাজনা/কর রশিদ"
   collapsed into a single merged folder name "খাজনাকর রশিদ". On some
   filesystems the Unicode form written to disk (NFC vs NFD) can also drift
   from what's stored in the DB, so a file that exists on disk can still 404
   through the static file server. Such rows are re-pointed at the file
   actually found on disk.

2. Working rows that live in a non-canonical folder - raw Bengali labels (or
   NFC/NFD variants of them) used as directory names. Uploads now always land
   in ASCII folders (`slugify_path_segment()`), so those files are moved to
   their canonical path and the DB updated to match.

3. Dangling rows (opt-in, --clear-missing) - the file is gone from disk
   entirely (typically uploaded before the persistent volume was mounted, then
   wiped by a redeploy). The stored path is set to NULL so the API stops
   returning a URL that 404s and the member is prompted to upload again.
   Never runs when the upload root is completely empty: that indicates a
   missing volume mount, not lost files, and clearing would destroy every
   reference.

The saved name is a random uuid4 hex, so a basename match is unambiguous.

Usage:
    python -m scripts.repair_document_paths            # dry run, prints a report
    python -m scripts.repair_document_paths --apply     # writes the fixes to the DB
    python -m scripts.repair_document_paths --apply --clear-missing
                                                        # also NULLs paths whose file is gone
"""

import argparse
import asyncio
import shutil
import unicodedata
from pathlib import Path

from sqlalchemy import or_, select
from sqlalchemy.orm import selectinload

from app.core.config import get_settings
from app.db.session import AsyncSessionLocal
from app.models.member import Member
from app.models.property import ApplicableDoc
from app.services.storage import slugify_path_segment

settings = get_settings()


def _upload_root() -> Path:
    return settings.upload_root


def _find_by_basename(root: Path, basename: str) -> list[Path]:
    return [p for p in root.rglob(basename) if p.is_file()]


def _locate(root: Path, stored: str) -> Path | None:
    """Absolute path of the file a stored relative path refers to, if any."""
    for candidate in (root / stored, root / unicodedata.normalize("NFD", stored)):
        if candidate.is_file():
            return candidate
    matches = _find_by_basename(root, Path(stored).name)
    return matches[0] if len(matches) == 1 else None


def _member_dir(member_id: int) -> str:
    return f"member_{member_id}"


def _canonical_for_doc(member_id: int, doc_type: str, stored: str) -> Path:
    """Preferred location of a document: ASCII slug folder under its member."""
    filename = Path(stored).name
    return Path("documents") / _member_dir(member_id) / slugify_path_segment(doc_type) / filename


def _canonical_for_member_file(folder: str, member_id: int, stored: str) -> Path:
    return Path(folder) / _member_dir(member_id) / Path(stored).name


def _targets(docs, members):
    """Yield (label, row, attribute, canonical_path) for every stored upload path."""
    for doc in docs:
        member_id = doc.property.member_id
        yield (
            f"doc id={doc.id} doc_type={doc.doc_type!r}",
            doc,
            "file_path",
            _canonical_for_doc(member_id, doc.doc_type, doc.file_path or ""),
        )
    for member in members:
        for attr, folder in (("member_photo_path", "photos"), ("receipt_photo_path", "receipts")):
            stored = getattr(member, attr)
            if not stored:
                continue
            yield (
                f"member id={member.id} {attr}",
                member,
                attr,
                _canonical_for_member_file(folder, member.id, stored),
            )


def _has_any_file(root: Path) -> bool:
    return root.is_dir() and any(p.is_file() and not p.name.startswith(".") for p in root.rglob("*"))


async def repair(apply: bool, clear_missing: bool = False, session_factory=AsyncSessionLocal) -> None:
    root = _upload_root()
    print(f"upload root: {root}")
    if clear_missing and not _has_any_file(root):
        print("[SKIP] --clear-missing ignored: upload root has no files (volume not mounted?)")
        clear_missing = False
    async with session_factory() as db:
        docs = (
            await db.execute(
                select(ApplicableDoc)
                .where(ApplicableDoc.file_path.is_not(None))
                .options(selectinload(ApplicableDoc.property))
            )
        ).scalars().all()
        members = (
            await db.execute(
                select(Member).where(
                    or_(Member.member_photo_path.is_not(None), Member.receipt_photo_path.is_not(None))
                )
            )
        ).scalars().all()

        checked = missing = fixed = moved = unresolved = cleared = 0

        for label, row, attr, canonical in _targets(docs, members):
            checked += 1
            stored = getattr(row, attr)
            actual = _locate(root, stored)
            if actual is None:
                missing += 1
                if clear_missing:
                    print(f"[CLEAR] {label} path={stored!r} -> file gone, clearing stored path")
                    if apply:
                        setattr(row, attr, None)
                        cleared += 1
                    continue
                unresolved += 1
                print(f"[UNRESOLVED] {label} path={stored!r} -> no file with that name on disk")
                continue

            relative = actual.relative_to(root)
            if relative == canonical:
                continue

            action = "MISSING-PATH" if Path(stored) != relative else "MOVE"
            print(f"[{action}] {label} path={stored!r} -> {str(canonical)!r}")
            if apply:
                destination = root / canonical
                if actual != destination:
                    destination.parent.mkdir(parents=True, exist_ok=True)
                    if destination.exists():
                        # Same uuid name already at the canonical spot: point the
                        # row there and leave the stray copy for manual review.
                        print(f"  (kept existing {destination})")
                    else:
                        source_dir = actual.parent
                        shutil.move(str(actual), str(destination))
                        moved += 1
                        # Drop the now-empty (possibly Bengali-named) folder.
                        try:
                            source_dir.rmdir()
                        except OSError:
                            pass
                setattr(row, attr, str(canonical))
                fixed += 1

        if apply and (fixed or cleared):
            await db.commit()

        print(
            f"\n{checked} file path(s) checked, {missing} missing from their stored path, "
            f"{fixed if apply else 0} updated"
            + ("" if apply else " (dry run — pass --apply to write changes)")
        )
        if apply and moved:
            print(f"{moved} file(s) physically moved to their canonical ASCII folder.")
        if cleared:
            print(f"{cleared} dangling path(s) cleared; those members must re-upload.")
        if unresolved:
            print(f"{unresolved} could not be resolved automatically and need manual review.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--apply", action="store_true", help="Write corrected file_path values to the database"
    )
    parser.add_argument(
        "--clear-missing",
        action="store_true",
        help="NULL stored paths whose file no longer exists anywhere under the upload root",
    )
    args = parser.parse_args()
    asyncio.run(repair(apply=args.apply, clear_missing=args.clear_missing))
