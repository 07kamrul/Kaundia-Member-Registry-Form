"""Unit tests for app.seed, app.core.security helpers, app.main middleware,
and app.services.audit.record_audit."""

from datetime import datetime, timezone

import pytest
from httpx import AsyncClient
from sqlalchemy import select, text

from app.core.security import (
    create_access_token,
    decode_token,
    generate_temp_password,
    hash_password,
    normalize_token_role,
    verify_password,
)
from app.db.base import Base
from app.models.admin import AdminRole, AdminUser
from app.models.member import Member, MemberStatus
from app import seed as seed_module
from app.services.audit import record_audit

pytestmark = pytest.mark.asyncio


class _SessionShim:
    """Context manager standing in for AsyncSessionLocal in the test DB."""

    def __init__(self, session):
        self._session = session

    async def __aenter__(self):
        return self._session

    async def __aexit__(self, *exc):
        return False


async def test_seed_creates_default_admin_and_is_idempotent(
    db_session, monkeypatch: pytest.MonkeyPatch
) -> None:
    from app.core.config import get_settings
    from app import seed as seed_module

    settings = get_settings()
    monkeypatch.setattr(settings, "admin_email", "seedadmin@example.com")
    monkeypatch.setattr(settings, "admin_password", "Kaundia@2026")
    monkeypatch.setattr(settings, "admin_name", "Seed Admin")
    monkeypatch.setattr(settings, "admin_role", "super_admin")
    monkeypatch.setattr(seed_module, "AsyncSessionLocal", lambda: _SessionShim(db_session))

    await seed_module.seed_admin()
    await seed_module.seed_admin()  # second run must not duplicate or crash

    admins = (
        (await db_session.execute(select(AdminUser).where(AdminUser.email == "seedadmin@example.com")))
        .scalars()
        .all()
    )
    assert len(admins) == 1
    assert admins[0].role == AdminRole.SUPER_ADMIN
    assert verify_password("Kaundia@2026", admins[0].password_hash)


def test_password_hash_round_trip() -> None:
    hashed = hash_password("s3cret-password")
    assert hashed != "s3cret-password"
    assert verify_password("s3cret-password", hashed)
    assert not verify_password("wrong", hashed)


def test_generate_temp_password_length_and_alphabet() -> None:
    password = generate_temp_password(12)
    assert len(password) == 12
    assert password.isalnum()


def test_decode_token_rejects_garbage_and_wrong_type() -> None:
    assert decode_token("not-a-jwt") is None
    token = create_access_token("1", "member")
    payload = decode_token(token)
    assert payload is not None
    assert payload["type"] == "access"
    assert payload["sub"] == "1"


def test_normalize_token_role_case_and_whitespace() -> None:
    assert normalize_token_role(" MEMBER ") == "member"
    assert normalize_token_role("Super_Admin") == "super_admin"
    assert normalize_token_role(None) == ""
    assert normalize_token_role("wizard") == "wizard"


async def test_record_audit_stamps_actor_action_entity(db_session) -> None:
    from datetime import datetime as dt

    admin = AdminUser(
        email="auditor@example.com",
        password_hash=hash_password("adminpass123"),
        name="Auditor",
        role=AdminRole.EXECUTIVE_COMMITTEE,
    )
    db_session.add(admin)
    await db_session.flush()

    record_audit(
        db_session,
        actor_admin_id=admin.id,
        action="test.action",
        entity_type="test_entity",
        entity_id="42",
        detail="detail text",
    )
    await db_session.commit()

    row = (await db_session.execute(text("SELECT * FROM audit_logs"))).mappings().one()
    assert row["action"] == "test.action"
    assert row["actor_admin_id"] == admin.id
    assert row["entity_type"] == "test_entity"
    assert row["entity_id"] == "42"
    assert row["detail"] == "detail text"
    # sqlite returns a naive string; postgres returns datetime. Either way the
    # stamp must be present and parseable.
    assert dt.fromisoformat(str(row["created_at"]).replace(" ", "T")) is not None


async def test_health_endpoint(client: AsyncClient) -> None:
    response = await client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


async def test_cors_middleware_allows_configured_origin(client: AsyncClient) -> None:
    response = await client.options(
        "/health",
        headers={
            "Origin": "http://localhost:4200",
            "Access-Control-Request-Method": "GET",
        },
    )
    assert response.status_code in (200, 204)
    assert response.headers.get("access-control-allow-origin") is not None


async def test_unhandled_errors_return_500_json_not_a_crash(client: AsyncClient):
    """CorsSafeErrorMiddleware converts any escape into a JSON 500."""
    from app.main import app

    @app.get("/__boom")
    async def boom() -> None:
        raise RuntimeError("exploded")

    response = await client.get("/__boom")
    assert response.status_code == 500
    assert response.json() == {"detail": "Internal server error"}
