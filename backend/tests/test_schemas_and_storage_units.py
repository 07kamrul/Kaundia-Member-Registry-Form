"""Pydantic schema round-trips/validation and storage-service unit tests."""

from datetime import date, datetime

import pytest
from fastapi import HTTPException, UploadFile
from pydantic import ValidationError

from app.schemas.config_list import ConfigListItemCreate, ConfigListItemUpdate
from app.schemas.fee_settings import FeeSettingCreate, FeeSettingOut
from app.schemas.installment import InstallmentUpdate
from app.schemas.member import RejectRequest
from app.schemas.public import SubscriptionQuoteRequest
from app.schemas.submission import SubmissionPayload

pytestmark = pytest.mark.asyncio


def _valid_payload() -> dict:
    from tests.test_submission_flow import _submission_payload

    return _submission_payload()


class TestSubmissionSchema:
    def test_valid_payload_round_trips(self) -> None:
        data = SubmissionPayload.model_validate(_valid_payload())
        assert data.full_name == "Test User"
        assert data.permanent_address.district == "Dhaka"
        assert data.properties[0].land_quantity == "15"
        assert data.nominees[0].relation == "Son"

    def test_nid_is_a_lenient_string_normalized_downstream(self) -> None:
        # The schema accepts any string; app.services.normalization strips
        # non-digits before storage/duplicate checks.
        payload = _valid_payload()
        payload["nid"] = " 1234-5678 "
        data = SubmissionPayload.model_validate(payload)
        assert data.nid == " 1234-5678 "  # untouched at the schema boundary

    def test_nominee_mobile_required(self) -> None:
        payload = _valid_payload()
        del payload["nominees"][0]["mobile"]
        with pytest.raises(ValidationError):
            SubmissionPayload.model_validate(payload)

    def test_extra_fields_are_ignored_not_erroring(self) -> None:
        payload = _valid_payload()
        payload["hacked_field"] = "value"
        data = SubmissionPayload.model_validate(payload)
        assert not hasattr(data, "hacked_field")


class TestFeeSettingsSchema:
    def test_create_defaults_start_date_to_none(self) -> None:
        create = FeeSettingCreate(key="admission_fee", value=500)
        assert create.start_date is None
        assert create.unit is None

    def test_create_rejects_missing_key(self) -> None:
        with pytest.raises(ValidationError):
            FeeSettingCreate(value=500)

    def test_out_serializes_dates_as_iso(self) -> None:
        out = FeeSettingOut(
            id=1, key="admission_fee", value=500.0, unit=None,
            start_date=date(2026, 1, 1), end_date=None, status=1,
            created_by=None, created_at=datetime(2026, 1, 1), updated_at=datetime(2026, 1, 1),
        )
        dumped = out.model_dump(mode="json")
        assert dumped["start_date"] == "2026-01-01"


class TestInstallmentUpdate:
    def test_status_accepts_paid_and_due(self) -> None:
        assert InstallmentUpdate(status="paid").status.value == "paid"
        assert InstallmentUpdate(status="due").status.value == "due"

    def test_status_rejects_unknown(self) -> None:
        with pytest.raises(ValidationError):
            InstallmentUpdate(status="postponed")


class TestConfigListSchemas:
    def test_create_requires_category_value_label(self) -> None:
        item = ConfigListItemCreate(category="c", value="v", label="L")
        assert item.sort_order == 0
        with pytest.raises(ValidationError):
            ConfigListItemCreate(category="c", value="v")

    def test_update_all_fields_optional(self) -> None:
        update = ConfigListItemUpdate()
        assert update.model_dump(exclude_unset=True) == {}
        assert ConfigListItemUpdate(is_active=True).model_dump(exclude_unset=True) == {"is_active": True}


class TestPublicSchemas:
    def test_quote_request_accepts_string_decimal(self) -> None:
        req = SubscriptionQuoteRequest(land_size_decimal="3.5")
        assert req.land_size_decimal == 3.5

    def test_quote_request_negative_size_accepted_at_schema_level(self) -> None:
        # Rejection (422) happens in calculate_monthly_subscription, covered
        # by tests/test_fee_calculation.py; the schema itself is permissive.
        req = SubscriptionQuoteRequest(land_size_decimal="-1")
        assert req.land_size_decimal == -1

    def test_reject_request_requires_reason(self) -> None:
        assert RejectRequest(reason="why").reason == "why"
        with pytest.raises(ValidationError):
            RejectRequest()


class TestStorageService:
    async def test_save_rejects_empty_filename_suffix(self, tmp_path, monkeypatch) -> None:
        from app.services import storage

        monkeypatch.setattr(storage.settings, "upload_dir", str(tmp_path))
        upload = UploadFile(file=__import__("io").BytesIO(b"x"), filename=None)
        with pytest.raises(HTTPException) as exc:
            await storage.save_upload_file(upload, "photos/member_1")
        assert exc.value.status_code == 422

    async def test_slugify_falls_back_to_content_hash(self) -> None:
        from app.services.storage import slugify_path_segment

        # Pure Bangla with no known mapping → doc-<hash> fallback.
        slug = slugify_path_segment("অজানা নথি")
        assert slug.startswith("doc-")
        assert len(slug) == 14

    async def test_slugify_transliterates_unknown_ascii(self) -> None:
        from app.services.storage import slugify_path_segment

        assert slugify_path_segment("Land Papers 2026!") == "land-papers-2026"

    async def test_sanitize_path_segment_handles_unsafe_and_empty(self) -> None:
        from app.services.storage import sanitize_path_segment

        assert sanitize_path_segment("a/b\\c:d*e") == "a-b-c-d-e"
        assert sanitize_path_segment("") == "misc"
        assert sanitize_path_segment("..") == "misc"
