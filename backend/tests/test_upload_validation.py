"""Upload validation: oversize and unsupported file types must be rejected
loudly, never silently accepted. (Storage+serve round-trip and the Bangla
slug mapping are covered in test_upload_serving.py.)"""

import json

import pytest
from httpx import AsyncClient

from app.services import storage
from tests.test_submission_flow import _submission_payload

pytestmark = pytest.mark.asyncio


def _files(name: str, content: bytes, mime: str) -> list[tuple[str, tuple[str, bytes, str]]]:
    return [
        ("member_photo", ("photo.jpg", b"\xff\xd8\xff\xe0fakejpeg", "image/jpeg")),
        ("doc_files", (name, content, mime)),
    ]


async def _post_submission(client: AsyncClient, files) -> AsyncClient.response:
    payload = _submission_payload()
    payload["properties"][0]["applicable_docs"] = [{"doc_type": "খাজনা/কর রশিদ"}]
    return await client.post(
        "/api/submissions",
        data={"payload": json.dumps(payload)},
        files=files,
    )


async def test_oversize_upload_is_rejected_with_413(
    client: AsyncClient, tmp_path, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(storage.settings, "upload_dir", str(tmp_path))
    oversized = b"x" * (10 * 1024 * 1024 + 1)
    response = await _post_submission(
        client, _files("big.pdf", oversized, "application/pdf")
    )
    assert response.status_code == 413
    assert "10 MB" in response.json()["detail"]


async def test_unsupported_file_type_is_rejected_with_422(
    client: AsyncClient, tmp_path, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(storage.settings, "upload_dir", str(tmp_path))
    for name, mime in (
        ("script.exe", "application/octet-stream"),
        ("notes.txt", "text/plain"),
        ("noext", "application/octet-stream"),
    ):
        response = await _post_submission(
            client, _files(name, b"malicious-or-not", mime)
        )
        assert response.status_code == 422, name
        assert "Unsupported file type" in response.json()["detail"]


async def test_rejected_upload_leaves_no_member_row(
    client: AsyncClient, db_session, tmp_path, monkeypatch: pytest.MonkeyPatch
) -> None:
    from sqlalchemy import func, select

    from app.models.member import Member

    monkeypatch.setattr(storage.settings, "upload_dir", str(tmp_path))
    await _post_submission(client, _files("evil.exe", b"...", "application/octet-stream"))
    count = await db_session.scalar(select(func.count()).select_from(Member))
    assert count == 0
