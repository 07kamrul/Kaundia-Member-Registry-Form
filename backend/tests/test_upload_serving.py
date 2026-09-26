"""Uploads must be served from exactly the directory they are saved to.

A 404 on an attachment that exists on disk means the save path and the static
mount disagreed; these tests pin both ends of that contract (plus the ASCII
folder names new uploads use) so the mismatch cannot come back silently.
"""

import json
import urllib.parse

import pytest
from httpx import AsyncClient

from app.services import storage
from app.services.storage import slugify_path_segment
from tests.test_submission_flow import _submission_payload

_JPG_BYTES = b"\xff\xd8\xff\xe0fakejpegbytes"
_PDF_BYTES = b"%PDF-1.4\nfakepdfbytes\n%%EOF"


def _upload_url(relative_path: str) -> str:
    return "/uploads/" + "/".join(urllib.parse.quote(seg) for seg in relative_path.split("/"))


def _payload_with_doc(doc_type: str) -> dict:
    payload = _submission_payload()
    payload["properties"][0]["applicable_docs"] = [{"doc_type": doc_type}]
    return payload


async def test_uploaded_file_is_served_from_the_save_directory(
    client: AsyncClient,
    db_session,
    tmp_path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    from sqlalchemy import select

    from app.models.member import Member
    from app.models.property import ApplicableDoc

    monkeypatch.setattr(storage.settings, "upload_dir", str(tmp_path))

    response = await client.post(
        "/api/submissions",
        data={"payload": json.dumps(_payload_with_doc("খাজনা/কর রশিদ"))},
        files=[
            ("member_photo", ("photo.jpg", _JPG_BYTES, "image/jpeg")),
            ("doc_files", ("rashid.pdf", _PDF_BYTES, "application/pdf")),
        ],
    )
    assert response.status_code == 201
    member_pk = response.json()["id"]

    member = await db_session.get(Member, member_pk)
    photo_path = member.member_photo_path
    assert photo_path and photo_path.startswith(f"photos/member_{member_pk}/")

    doc = (await db_session.execute(select(ApplicableDoc))).scalars().one()
    assert doc.file_path is not None

    # The bytes written during the upload are readable back through the
    # /uploads static mount - i.e. save path == serve path.
    for relative_path, expected_bytes in (
        (photo_path, _JPG_BYTES),
        (doc.file_path, _PDF_BYTES),
    ):
        served = await client.get(_upload_url(relative_path))
        assert served.status_code == 200, relative_path
        assert served.content == expected_bytes


async def test_missing_attachment_logs_the_absolute_path_searched(
    client: AsyncClient,
    tmp_path,
    monkeypatch: pytest.MonkeyPatch,
    caplog: pytest.LogCaptureFixture,
) -> None:
    monkeypatch.setattr(storage.settings, "upload_dir", str(tmp_path))

    with caplog.at_level("WARNING", logger="app.services.storage"):
        response = await client.get("/uploads/photos/member_9/nope.jpg")

    assert response.status_code == 404
    assert response.json() == {"detail": "Not Found"}
    assert any(
        "searched=" in record.message and str(tmp_path) in record.getMessage()
        for record in caplog.records
    )


async def test_document_folders_use_ascii_slugs(
    client: AsyncClient,
    db_session,
    tmp_path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    from sqlalchemy import select

    from app.models.property import ApplicableDoc

    monkeypatch.setattr(storage.settings, "upload_dir", str(tmp_path))

    response = await client.post(
        "/api/submissions",
        data={"payload": json.dumps(_payload_with_doc("খাজনা/কর রশিদ"))},
        files=[("doc_files", ("rashid.pdf", _PDF_BYTES, "application/pdf"))],
    )
    assert response.status_code == 201
    member_pk = response.json()["id"]

    doc = (await db_session.execute(select(ApplicableDoc))).scalars().one()
    # Bengali stays in doc_type for display; the folder is an ASCII slug.
    assert doc.doc_type == "খাজনা/কর রশিদ"
    assert doc.file_path is not None
    assert doc.file_path.isascii()
    filename = doc.file_path.rsplit("/", 1)[-1]
    assert doc.file_path == f"documents/member_{member_pk}/khajna_kar_rashid/{filename}"
    assert (tmp_path / doc.file_path).is_file()

    served = await client.get(_upload_url(doc.file_path))
    assert served.status_code == 200
    assert served.content == _PDF_BYTES


@pytest.mark.parametrize(
    ("label", "expected"),
    [
        ("খাজনা/কর রশিদ", "khajna_kar_rashid"),
        ("খতিয়ান/পর্চা", "khatian_porcha"),
        ("নামজারি/মিউটেশন", "namjari_mutation"),
        ("উত্তরাধিকার সনদ", "uttoradhikar_sonod"),
        ("Deed of Gift", "deed-of-gift"),
        ("১০ # দলিল", "doc-d5e4547f03"),
    ],
)
def test_slugify_path_segment(label: str, expected: str) -> None:
    slug = slugify_path_segment(label)
    assert slug == expected
    assert slug.isascii()
    assert "/" not in slug and "\\" not in slug
