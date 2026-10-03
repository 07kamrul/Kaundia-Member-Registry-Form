"""International mobile support: E.164 normalisation, schema validation and
duplicate detection against legacy digits-only Bangladeshi rows."""

import json

import pytest
from httpx import AsyncClient
from pydantic import ValidationError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.admin import AdminUser
from app.models.member import Member, MemberStatus
from app.schemas.submission import SubmissionPayload
from app.services.normalization import mobile_lookup_variants, normalize_mobile
from tests.test_submission_flow import _submission_payload


class TestNormalizeMobile:
    @pytest.mark.parametrize(
        "raw,expected",
        [
            ("01712345678", "+8801712345678"),
            ("+880 1712-345678", "+8801712345678"),
            ("+14155552671", "+14155552671"),
            ("+44 7911 123456", "+447911123456"),
            ("+81 90-1234-5678", "+819012345678"),
            ("+971501234567", "+971501234567"),
        ],
    )
    def test_returns_e164_for_valid_numbers(self, raw: str, expected: str) -> None:
        assert normalize_mobile(raw) == expected

    @pytest.mark.parametrize("raw", ["", "12345", "+1 555", "not a phone", "+8801234"])
    def test_rejects_invalid_numbers(self, raw: str) -> None:
        with pytest.raises(ValueError):
            normalize_mobile(raw)

    def test_bangladesh_variants_include_legacy_national_form(self) -> None:
        assert set(mobile_lookup_variants("+8801712345678")) == {
            "+8801712345678",
            "8801712345678",
            "01712345678",
        }

    def test_foreign_variants_have_no_bangladesh_form(self) -> None:
        assert set(mobile_lookup_variants("+14155552671")) == {"+14155552671", "14155552671"}


class TestSubmissionPayloadPhones:
    def test_normalizes_all_phone_fields(self) -> None:
        payload = _submission_payload()
        payload["mobile"] = "+44 7911 123456"
        payload["urgent_contact_mobile"] = "01712345678"
        payload["nominees"][0]["mobile"] = "+1 415 555 2671"

        data = SubmissionPayload.model_validate(payload)

        assert data.mobile == "+447911123456"
        assert data.urgent_contact_mobile == "+8801712345678"
        assert data.nominees[0].mobile == "+14155552671"

    def test_rejects_invalid_mobile(self) -> None:
        payload = _submission_payload()
        payload["mobile"] = "+1 555"
        with pytest.raises(ValidationError):
            SubmissionPayload.model_validate(payload)


@pytest.mark.asyncio
async def test_duplicate_check_matches_legacy_digits_only_row(
    client: AsyncClient, admin_user: AdminUser, db_session: AsyncSession
) -> None:
    payload = _submission_payload()
    db_session.add(
        Member(
            status=MemberStatus.PENDING,
            full_name="Legacy",
            father_or_husband="f",
            mother="m",
            dob="1990-01-01",
            nationality="Bangladeshi",
            occupation="job",
            nid="5555555555",
            mobile="01712345678",
            gender="male",
            email="legacy@example.com",
            admission_fee="500",
            subscription="100",
            receipt_no="r",
            payment_method="cash",
            submission_date="2026-01-01",
        )
    )
    await db_session.commit()

    payload["mobile"] = "+8801712345678"
    response = await client.post("/api/submissions", data={"payload": json.dumps(payload)})

    assert response.status_code == 409
    assert response.json()["detail"]["code"] == "APPLICATION_PENDING"


@pytest.mark.asyncio
async def test_submission_stores_international_mobile_as_e164(
    client: AsyncClient, admin_user: AdminUser, db_session: AsyncSession
) -> None:
    payload = _submission_payload()
    payload["mobile"] = "+81 90-1234-5678"

    response = await client.post("/api/submissions", data={"payload": json.dumps(payload)})

    assert response.status_code == 201
    member = await db_session.get(Member, response.json()["id"])
    assert member is not None
    assert member.mobile == "+819012345678"
