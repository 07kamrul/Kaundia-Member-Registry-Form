import asyncio
import hashlib
import logging
import os
import re
import unicodedata
import uuid
from pathlib import Path

from fastapi import HTTPException, UploadFile, status
from starlette.staticfiles import StaticFiles

from app.core.config import get_settings

settings = get_settings()
logger = logging.getLogger(__name__)

_ALLOWED_UPLOAD_EXTENSIONS = {".jpg", ".jpeg", ".png", ".pdf"}
_MAX_UPLOAD_BYTES = 10 * 1024 * 1024  # 10 MB
_READ_CHUNK_BYTES = 1024 * 1024

_UNSAFE_PATH_CHARS_RE = re.compile(r'[\\/:*?"<>|]')

# Display labels of the registration form's document checklist mapped to stable
# ASCII folder names. `doc_type` is stored (and shown) as the Bengali label the
# applicant picked, but the filesystem only ever sees the slug: raw Bengali
# labels as folder names depend on OS/filesystem encoding and URL handling, and
# a label containing '/' silently merged into a single folder.
_DOC_TYPE_SLUGS = {
    "খতিয়ান/পর্চা": "khatian_porcha",
    "নামজারি/মিউটেশন": "namjari_mutation",
    "খাজনা/কর রশিদ": "khajna_kar_rashid",
    "উত্তরাধিকার সনদ": "uttoradhikar_sonod",
}


def sanitize_path_segment(value: str) -> str:
    """Make a string safe to use as a single filesystem path segment.

    Replaces characters that are unsafe on Windows/Linux filesystems (or that
    would otherwise be interpreted as a path separator, silently merging
    words like "খাজনা/কর রশিদ" into "খাজনাকর রশিদ") with '-', preserves
    Unicode (e.g. Bengali) text, normalizes to NFC so the same label always
    maps to the same bytes on disk regardless of OS/input normalization, and
    collapses empty results to 'misc' so a folder is never created with an
    empty or '.'/'..' name.
    """
    normalized = unicodedata.normalize("NFC", value)
    cleaned = _UNSAFE_PATH_CHARS_RE.sub("-", normalized).strip().strip(".")
    return cleaned or "misc"


def slugify_path_segment(value: str) -> str:
    """ASCII folder name for a human-readable (often Bengali) label.

    Known document labels map to a fixed slug; anything else is transliterated
    to `[a-z0-9-]`, falling back to a short content hash when the label has no
    ASCII characters at all. The result is always a single, non-empty ASCII
    segment so the path is stable across OS/filesystem encodings.
    """
    normalized = unicodedata.normalize("NFC", value).strip()
    known = _DOC_TYPE_SLUGS.get(normalized)
    if known:
        return known

    ascii_slug = re.sub(r"[^a-z0-9]+", "-", normalized.lower()).strip("-")
    if ascii_slug:
        return ascii_slug[:64]
    digest = hashlib.sha1(normalized.encode("utf-8")).hexdigest()[:10]
    return f"doc-{digest}"


class UploadStaticFiles(StaticFiles):
    """Serves ``settings.upload_root`` - the directory ``save_upload_file``
    writes to.

    The root is re-resolved on every lookup instead of being captured once at
    import, so the mount can never drift from the save path (relative
    ``upload_dir`` values, env reloads, tests), and a miss is logged with the
    absolute path that was searched.
    """

    def __init__(self, **kwargs: object) -> None:
        root = settings.upload_root
        root.mkdir(parents=True, exist_ok=True)
        super().__init__(directory=str(root), **kwargs)  # type: ignore[arg-type]

    def lookup_path(self, path: str) -> tuple[str, os.stat_result | None]:
        root = settings.upload_root
        if not root.is_dir():
            root.mkdir(parents=True, exist_ok=True)
        self.directory = str(root)
        self.all_directories = [root]
        full_path, stat_result = super().lookup_path(path)
        if stat_result is None:
            logger.warning(
                "[uploads] 404 miss: requested=%r searched=%s", path, root / path
            )
        return full_path, stat_result


async def _read_capped(upload_file: UploadFile) -> bytes:
    """Read the upload in 1 MB chunks, aborting as soon as the cap is passed.

    The old single `read()` materialised the whole (up to 10 MB) body in memory
    before the size check could reject it.
    """
    chunks: list[bytes] = []
    total = 0
    while True:
        chunk = await upload_file.read(_READ_CHUNK_BYTES)
        if not chunk:
            break
        total += len(chunk)
        if total > _MAX_UPLOAD_BYTES:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail="File exceeds the 10 MB upload limit.",
            )
        chunks.append(chunk)
    return b"".join(chunks)


async def save_upload_file(upload_file: UploadFile, subdir: str) -> str:
    """Save a multipart UploadFile to disk and return its relative path.

    Rejects files outside the image/PDF allow-list or over the size cap,
    since this is reachable from an unauthenticated public endpoint.
    """
    suffix = Path(upload_file.filename or "").suffix.lower()
    if suffix not in _ALLOWED_UPLOAD_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Unsupported file type '{suffix or 'unknown'}'. Allowed: jpg, jpeg, png, pdf.",
        )

    contents = await _read_capped(upload_file)

    subdir = unicodedata.normalize("NFC", subdir)
    filename = f"{uuid.uuid4().hex}{suffix}"
    # Same root the /uploads static mount serves (Settings.upload_root), so the
    # absolute path logged here can be compared 1:1 with serve-side logs.
    target_path = settings.upload_root / subdir / filename

    # File writes are blocking; running them on the loop would stall every
    # other in-flight request for the duration of the write.
    await asyncio.to_thread(_write_file, target_path, contents)
    logger.info("[uploads] saved: %s", target_path)

    return str(Path(subdir) / filename)


def _write_file(target_path: Path, contents: bytes) -> None:
    target_path.parent.mkdir(parents=True, exist_ok=True)
    target_path.write_bytes(contents)
