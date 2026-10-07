"""scripts.repair_document_paths --clear-missing: NULL paths whose file is gone."""

from pathlib import Path

import pytest
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.models.member import Member
from scripts import repair_document_paths as repair_script

pytestmark = pytest.mark.asyncio

MISSING_PHOTO = "photos/member_1/85b0adc977324a7c94e725e5d2f70769.jpg"
PRESENT_RECEIPT = "receipts/member_1/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.jpg"


async def _member(db: AsyncSession) -> Member:
    member = Member(
        status="approved",
        member_id="KAM-2026-0001",
        full_name="Md. Kamrul Hasan",
        father_or_husband="father",
        mother="mother",
        dob="1990-01-01",
        nationality="Bangladeshi",
        occupation="job",
        nid="1234567890",
        mobile="01758290421",
        gender="male",
        email="m@example.com",
        admission_fee="500",
        subscription="100",
        receipt_no="r",
        payment_method="cash",
        submission_date="2026-01-01",
        member_photo_path=MISSING_PHOTO,
        receipt_photo_path=PRESENT_RECEIPT,
    )
    db.add(member)
    await db.commit()
    await db.refresh(member)
    return member


def _write(root: Path, relative: str) -> None:
    target = root / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(b"x")


async def _run(db: AsyncSession, member_id: int, **kwargs) -> Member:
    factory = async_sessionmaker(bind=db.bind, expire_on_commit=False)
    await repair_script.repair(session_factory=factory, **kwargs)
    db.expire_all()
    return await db.get(Member, member_id)  # type: ignore[return-value]


@pytest.fixture
def upload_root(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    monkeypatch.setattr(repair_script.settings, "upload_dir", str(tmp_path))
    return tmp_path


async def test_clears_missing_path_and_keeps_existing(db_session: AsyncSession, upload_root: Path) -> None:
    # Arrange
    created = await _member(db_session)
    _write(upload_root, PRESENT_RECEIPT)

    # Act
    member = await _run(db_session, created.id, apply=True, clear_missing=True)

    # Assert
    assert member.member_photo_path is None
    assert member.receipt_photo_path == PRESENT_RECEIPT


async def test_dry_run_changes_nothing(db_session: AsyncSession, upload_root: Path) -> None:
    created = await _member(db_session)
    _write(upload_root, PRESENT_RECEIPT)

    member = await _run(db_session, created.id, apply=False, clear_missing=True)

    assert member.member_photo_path == MISSING_PHOTO


async def test_without_flag_missing_path_is_kept(db_session: AsyncSession, upload_root: Path) -> None:
    created = await _member(db_session)
    _write(upload_root, PRESENT_RECEIPT)

    member = await _run(db_session, created.id, apply=True)

    assert member.member_photo_path == MISSING_PHOTO


async def test_empty_upload_root_never_clears(db_session: AsyncSession, upload_root: Path) -> None:
    # An empty root means the volume is not mounted - clearing would wipe every reference.
    created = await _member(db_session)

    member = await _run(db_session, created.id, apply=True, clear_missing=True)

    assert member.member_photo_path == MISSING_PHOTO
    assert member.receipt_photo_path == PRESENT_RECEIPT
