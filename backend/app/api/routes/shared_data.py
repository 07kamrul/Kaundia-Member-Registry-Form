"""Static JSON datasets shared by the Angular and Flutter clients.

Every file under ``data/shared/`` (geo lists, khatian catalog, ...) is served
read-only at ``GET /api/data/{name}``, so both clients load one copy from one
place. Names are matched against the directory listing, never joined into a
path, so traversal is impossible.
"""

import json
from functools import lru_cache
from pathlib import Path

from fastapi import APIRouter, HTTPException, Response, status

from app.core.config import get_settings

router = APIRouter(prefix="/data", tags=["shared-data"])

CACHE_CONTROL = "public, max-age=3600"


@lru_cache(maxsize=1)
def _dataset_paths() -> dict[str, Path]:
    root = Path(get_settings().shared_data_dir)
    return {p.stem: p for p in root.glob("*.json")}


@lru_cache(maxsize=32)
def _load(path: Path) -> bytes:
    return json.dumps(json.loads(path.read_text(encoding="utf-8")), separators=(",", ":")).encode()


@router.get("/{name}")
def get_shared_dataset(name: str) -> Response:
    path = _dataset_paths().get(name.removesuffix(".json"))
    if path is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "DATASET_NOT_FOUND", "message": "Dataset not found."},
        )
    return Response(
        content=_load(path),
        media_type="application/json",
        headers={"Cache-Control": CACHE_CONTROL},
    )
