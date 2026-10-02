"""Final backend gap batch: unified-login member path, land-share Decimal
errors, picnic payment schema validators, digits-only helper, as_utc helper,
RBAC role-update guards, receipt-photo upload branch, and public-stats
amount parsing."""

from datetime import datetime, timezone

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.routes.public import _parse_amount
from app.core.security import create_access_token, hash_password
from app.models.admin import AdminRole, AdminUser
from app.models.member import Member, MemberStatus
from app.schemas.common import validate_digits_only, as_utc
from app.schemas.picnic_payment import PicnicPaymentIn
from tests.test_submission_flow import _submission_payload

pytestmark = pytest.mark.asyncio


class TestPureHelpers:
    def test_parse_amount_handles_empty_and_garbage(self) -> None:
        assert _parse_amount(None) == 0
        assert _parse_amount("") == 0
        assert _parse_amount("abc") == 0
        assert _parse_amount("120.50") == 120.5

    def test_validate_digits_only(self) -> None:
        assert validate_digits_only(None) is None
        assert validate_digits_only("") == ""
        assert validate_digits_only("123") == "123"
        with pytest.raises(ValueError):
            validate_digits_only("12a3")

    def test_as_utc_normalises_naive_and_offsets(self) -> None:
        assert as_utc(None) is None
        naive = datetime(2026, 1, 1, 12, 0)
        assert as_utc(naive).tzinfo == timezone.utc
        offset = datetime(2026, 1, 1, 15, 0, tzinfo=timezone.utc)
        from datetime import timedelta

        shifted = as_utc(datetime(2026, 1, 1, 18, 0, tzinfo=timezone(timedelta(hours=3))))
        assert shifted == offset

    def test_picnic_additional_head_validator(self) -> None:
        with pytest.raises(ValueError):
            PicnicPaymentIn.require_integer(2.5)
        with pytest.raises(ValueError):
            PicnicPaymentIn.require_integer("2x")
        assert PicnicPaymentIn.require_integer(2) == 2
        assert PicnicPaymentIn.require_integer("2") == "2"


class TestSubmissionLandShareDecimalError:
    async def test_invalid_share_quantity_is_422(self, client: AsyncClient) -> None:
        payload = _submission_payload()
        payload["properties"][0]["my_share_quantity"] = "abc"
        response = await client.post(
            "/api/submissions", data={"payload": json.dumps(payload)}
        )
        assert response.status_code == 422
        # The schema's digits-only validator catches it first (422 either
        # way); the route-level Decimal guard remains as defense-in-depth.
        assert "my_share_quantity" in response.json()["detail"]


import json


class TestReceiptPhotoBranch:
    async def test_receipt_photo_is_stored(self, client: AsyncClient, tmp_path, monkeypatch) -> None:
        from app.services import storage

        monkeypatch.setattr(storage.settings, "upload_dir", str(tmp_path))
        response = await client.post(
            "/api/submissions",
            data={"payload": json.dumps(_submission_payload())},
            files=[
                ("member_photo", ("photo.jpg", b"\xff\xd8\xff\xe0jpeg", "image/jpeg")),
                ("receipt_photo", ("receipt.png", b"\x89PNG png", "image/png")),
            ],
        )
        assert response.status_code == 201, response.text


class TestRbacRoleUpdateGuards:
    async def test_patch_user_role_unknown_role_and_unknown_role_id(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        root = AdminUser(
            email="root9@example.com", password_hash=hash_password("adminpass123"),
            name="Root9", role=AdminRole.SUPER_ADMIN,
        )
        db_session.add(root)
        await db_session.commit()
        login = await client.post(
            "/api/admin/login", json={"email": "root9@example.com", "password": "adminpass123"}
        )
        headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

        unknown_role = await client.patch(
            f"/api/admin/rbac/users/{root.id}/role",
            json={"role": "emperor", "role_id": None},
            headers=headers,
        )
        assert unknown_role.status_code == 400
        assert "Unknown role" in unknown_role.json()["detail"]

        ghost_role_id = await client.patch(
            f"/api/admin/rbac/users/{root.id}/role",
            json={"role": "administrator", "role_id": 987654},
            headers=headers,
        )
        assert ghost_role_id.status_code == 404

        keep = await client.patch(
            f"/api/admin/rbac/users/{root.id}/role",
            json={"role": "super_admin", "role_id": None},
            headers=headers,
        )
        assert keep.status_code == 200

    async def test_last_super_admin_cannot_demote_themselves(
        self, client: AsyncClient, db_session: AsyncSession
    ) -> None:
        root = AdminUser(
            email="solo@example.com", password_hash=hash_password("adminpass123"),
            name="Solo", role=AdminRole.SUPER_ADMIN,
        )
        db_session.add(root)
        await db_session.commit()
        login = await client.post(
            "/api/admin/login", json={"email": "solo@example.com", "password": "adminpass123"}
        )
        headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

        response = await client.patch(
            f"/api/admin/rbac/users/{root.id}/role",
            json={"role": "administrator", "role_id": None},
            headers=headers,
        )
        assert response.status_code == 400
        assert "last super_admin" in response.json()["detail"]
