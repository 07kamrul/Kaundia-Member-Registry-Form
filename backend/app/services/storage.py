import base64
import re
import uuid
from pathlib import Path

from fastapi import HTTPException, UploadFile, status

from app.core.config import get_settings

settings = get_settings()

_DATA_URL_RE = re.compile(r"^data:(?P<mime>[\w/+.-]+);base64,(?P<data>.+)$", re.DOTALL)

_MIME_EXTENSIONS = {
    "image/jpeg": ".jpg",
    "image/jpg": ".jpg",
    "image/png": ".png",
    "application/pdf": ".pdf",
}

_ALLOWED_UPLOAD_EXTENSIONS = {".jpg", ".jpeg", ".png", ".pdf"}
_MAX_UPLOAD_BYTES = 10 * 1024 * 1024  # 10 MB


def _upload_root() -> Path:
    root = Path(settings.upload_dir)
    root.mkdir(parents=True, exist_ok=True)
    return root


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

    contents = await upload_file.read()
    if len(contents) > _MAX_UPLOAD_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="File exceeds the 10 MB upload limit.",
        )

    target_dir = _upload_root() / subdir
    target_dir.mkdir(parents=True, exist_ok=True)

    filename = f"{uuid.uuid4().hex}{suffix}"
    target_path = target_dir / filename
    target_path.write_bytes(contents)

    return str(Path(subdir) / filename)


def save_data_url(data_url: str, subdir: str) -> str | None:
    """Save a base64 data: URL (e.g. member photo) to disk and return its
    relative path, or None if the input is not a valid data URL."""
    match = _DATA_URL_RE.match(data_url)
    if not match:
        return None

    mime = match.group("mime")
    extension = _MIME_EXTENSIONS.get(mime, "")

    target_dir = _upload_root() / subdir
    target_dir.mkdir(parents=True, exist_ok=True)

    filename = f"{uuid.uuid4().hex}{extension}"
    target_path = target_dir / filename
    target_path.write_bytes(base64.b64decode(match.group("data")))

    return str(Path(subdir) / filename)


def resolve_upload_path(relative_path: str) -> Path:
    """Resolve a path previously returned by save_upload_file/save_data_url
    (relative to the upload root's parent, e.g. 'uploads/photos/x.jpg')."""
    return Path(settings.upload_dir).parent / relative_path
