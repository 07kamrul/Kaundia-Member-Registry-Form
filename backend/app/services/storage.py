import asyncio
import re
import unicodedata
import uuid
from pathlib import Path

from fastapi import HTTPException, UploadFile, status

from app.core.config import get_settings

settings = get_settings()

_ALLOWED_UPLOAD_EXTENSIONS = {".jpg", ".jpeg", ".png", ".pdf"}
_MAX_UPLOAD_BYTES = 10 * 1024 * 1024  # 10 MB
_READ_CHUNK_BYTES = 1024 * 1024

_UNSAFE_PATH_CHARS_RE = re.compile(r'[\\/:*?"<>|]')


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
    target_path = Path(settings.upload_dir) / subdir / filename

    # File writes are blocking; running them on the loop would stall every
    # other in-flight request for the duration of the write.
    await asyncio.to_thread(_write_file, target_path, contents)

    return str(Path(subdir) / filename)


def _write_file(target_path: Path, contents: bytes) -> None:
    target_path.parent.mkdir(parents=True, exist_ok=True)
    target_path.write_bytes(contents)
