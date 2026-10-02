"""Member self-service routes: /me, /installments, /picnic-rates,
/profile (core-field re-queue workflow), and /me/photo."""

import pytest
from httpx import AsyncClient
from sqlalchemy import select, text

from app.core.security import create_access_token, hash_password
from app.models.credential import MemberCredential
from app.models.installment import Installment, InstallmentStatus
from app.models.member import Member, MemberStatus
from app.services import storage

pytestmark = pytest.mark.asyncio


async def _approved_member(db_session, *, email="self@example.com", with_credential=True) -> Member:
    member = Member(
        status=MemberStatus.APPROVED,
        full_name="Md. Self Service",
        father_or_husband="Father",
        mother="Mother",
        dob="1990-01-01",
        nationality="Bangladeshi",
        occupation="Job",
        nid="1234567890",
        mobile="01758290421",
        gender="পুরুষ",
        email=email,
        admission_fee="500",
        subscription="100",
        receipt_no="R-1",
        payment_method="Cash",
        submission_date="2026-01-01",
        member_photo_path="photos/member_x/old.jpg",
    )
    db_session.add(member)
    await db_session.commit()
    await db_session.refresh(member)
    if with_credential:
        db_session.add(MemberCredential(
            member_id=member.id,
            username="ukamks-9999",
            password_hash=hash_password("currentpass123"),
            must_change_password=False,
        ))
        await db_session.commit()
    return member


def _member_headers(member: Member) -> dict:
    return {"Authorization": f"Bearer {create_access_token(str(member.id), 'member')}"}


async def test_member_installments_listed_ordered(
    client: AsyncClient, db_session
) -> None:
    member = await _approved_member(db_session)
    db_session.add_all([
        Installment(member_id=member.id, year=2026, month=3, amount=100, status=InstallmentStatus.DUE),
        Installment(member_id=member.id, year=2026, month=1, amount=100, status=InstallmentStatus.PAID),
    ])
    await db_session.commit()

    response = await client.get("/api/member/installments", headers=_member_headers(member))
    assert response.status_code == 200
    rows = response.json()
    assert [(r["year"], r["month"]) for r in rows] == [(2026, 1), (2026, 3)]


async def test_picnic_rates_configured_and_not_configured(
    client: AsyncClient, db_session
) -> None:
    member = await _approved_member(db_session)
    headers = _member_headers(member)

    missing = await client.get("/api/member/picnic-rates", headers=headers)
    assert missing.status_code == 404
    assert missing.json()["detail"]["code"] == "PICNIC_RATES_NOT_CONFIGURED"

    # Configure rates effective today.
    from datetime import date
    from app.models.fee_settings import FeeSetting
    db_session.add_all([
        FeeSetting(key="picnic_head_fee", value=300, start_date=date(2000, 1, 1)),
        FeeSetting(key="picnic_additional_head_fee", value=150, start_date=date(2000, 1, 1)),
    ])
    await db_session.commit()

    found = await client.get("/api/member/picnic-rates", headers=headers)
    assert found.status_code == 200
    body = found.json()
    assert body["head_fee"] == 300
    assert body["additional_head_fee"] == 150


async def test_profile_patch_non_core_field_stays_approved(
    client: AsyncClient, db_session
) -> None:
    member = await _approved_member(db_session)
    headers = _member_headers(member)

    response = await client.patch(
        "/api/member/profile", json={"urgent_contact_name": "New Contact"}, headers=headers
    )
    assert response.status_code == 200
    assert response.json()["status"] == "approved"

    await db_session.refresh(member)
    assert member.status == MemberStatus.APPROVED
    rows = (await db_session.execute(
        text("SELECT id FROM audit_logs WHERE action='member.self_edit_requeued'")
    )).all()
    assert rows == []


async def test_profile_patch_core_field_requeues_with_audit_and_email(
    client: AsyncClient, db_session, monkeypatch: pytest.MonkeyPatch
) -> None:
    sent: list[dict] = []

    async def fake_send_email(to: str, subject: str, html_body: str) -> bool:
        sent.append({"to": to, "subject": subject})
        return True

    from app.api.routes import member as member_routes
    monkeypatch.setattr(member_routes, "send_email", fake_send_email)

    member = await _approved_member(db_session)
    headers = _member_headers(member)

    response = await client.patch(
        "/api/member/profile", json={"occupation": "Engineer", "mobile": "01911111111"}, headers=headers
    )
    assert response.status_code == 200

    await db_session.refresh(member)
    assert member.status == MemberStatus.PENDING
    assert member.occupation == "Engineer"

    rows = (await db_session.execute(
        text("SELECT action FROM audit_logs WHERE entity_type='member' AND entity_id=:eid"),
        {"eid": str(member.id)},
    )).scalars().all()
    assert rows == ["member.self_edit_requeued"]
    assert len(sent) == 1
    assert "Under Review" in sent[0]["subject"]


async def test_photo_upload_accepts_image_rejects_other_types(
    client: AsyncClient, db_session, tmp_path, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(storage.settings, "upload_dir", str(tmp_path))
    member = await _approved_member(db_session)
    headers = _member_headers(member)

    rejected = await client.post(
        "/api/member/me/photo",
        files={"photo": ("scan.pdf", b"%PDF-1.4 fake", "application/pdf")},
        headers=headers,
    )
    assert rejected.status_code == 422
    assert "JPG or PNG" in rejected.json()["detail"]

    accepted = await client.post(
        "/api/member/me/photo",
        files={"photo": ("me.png", b"\x89PNG fakepng", "image/png")},
        headers=headers,
    )
    assert accepted.status_code == 200, accepted.text
    assert accepted.json()["member_photo_path"].startswith(f"photos/member_{member.id}/")
    assert accepted.json()["member_photo_path"].endswith(".png")

    await db_session.refresh(member)
    assert member.member_photo_path.startswith(f"photos/member_{member.id}/")
