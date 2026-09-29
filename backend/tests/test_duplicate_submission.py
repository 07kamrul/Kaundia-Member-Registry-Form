import json

import pytest
from httpx import AsyncClient

from app.models.admin import AdminUser
from tests.test_submission_flow import _submission_payload

pytestmark = pytest.mark.asyncio


async def _approve(client: AsyncClient, admin_headers: dict, member_pk: int) -> None:
    response = await client.post(
        f"/api/admin/submissions/{member_pk}/approve", headers=admin_headers
    )
    assert response.status_code == 200


async def _reject(client: AsyncClient, admin_headers: dict, member_pk: int) -> None:
    response = await client.post(
        f"/api/admin/submissions/{member_pk}/reject",
        json={"reason": "Incomplete documents"},
        headers=admin_headers,
    )
    assert response.status_code == 200


async def _admin_headers(client: AsyncClient) -> dict:
    login_response = await client.post(
        "/api/admin/login", json={"email": "admin@example.com", "password": "adminpass123"}
    )
    return {"Authorization": f"Bearer {login_response.json()['access_token']}"}


@pytest.mark.parametrize(
    "field,changed_value",
    [
        ("nid", "1234567890"),
        ("mobile", "01700000000"),
        ("email", "member@example.com"),
    ],
)
async def test_duplicate_pending_submission_rejected(
    client: AsyncClient, admin_user: AdminUser, field: str, changed_value: str
) -> None:
    first = await client.post(
        "/api/submissions", data={"payload": json.dumps(_submission_payload())}
    )
    assert first.status_code == 201

    second_payload = _submission_payload()
    # Vary every identifier except the one under test, so only that field
    # collides with the first (still PENDING) submission.
    second_payload["nid"] = "9999999990"
    second_payload["mobile"] = "01911111111"
    second_payload["email"] = "someone-else@example.com"
    second_payload[field] = changed_value

    second = await client.post(
        "/api/submissions", data={"payload": json.dumps(second_payload)}
    )
    assert second.status_code == 409
    body = second.json()["detail"]
    assert body["code"] == "APPLICATION_PENDING"


@pytest.mark.parametrize(
    "field,changed_value",
    [
        ("nid", "1234567890"),
        ("mobile", "01700000000"),
        ("email", "member@example.com"),
    ],
)
async def test_duplicate_approved_submission_rejected(
    client: AsyncClient, admin_user: AdminUser, field: str, changed_value: str
) -> None:
    first = await client.post(
        "/api/submissions", data={"payload": json.dumps(_submission_payload())}
    )
    member_pk = first.json()["id"]
    admin_headers = await _admin_headers(client)
    await _approve(client, admin_headers, member_pk)

    second_payload = _submission_payload()
    second_payload["nid"] = "9999999990"
    second_payload["mobile"] = "01911111111"
    second_payload["email"] = "someone-else@example.com"
    second_payload[field] = changed_value

    second = await client.post(
        "/api/submissions", data={"payload": json.dumps(second_payload)}
    )
    assert second.status_code == 409
    body = second.json()["detail"]
    assert body["code"] == "ALREADY_REGISTERED"


async def test_resubmission_allowed_after_rejection(
    client: AsyncClient, admin_user: AdminUser
) -> None:
    first = await client.post(
        "/api/submissions", data={"payload": json.dumps(_submission_payload())}
    )
    member_pk = first.json()["id"]
    admin_headers = await _admin_headers(client)
    await _reject(client, admin_headers, member_pk)

    second = await client.post(
        "/api/submissions", data={"payload": json.dumps(_submission_payload())}
    )
    assert second.status_code == 201


async def test_duplicate_check_normalizes_identifiers(
    client: AsyncClient, admin_user: AdminUser
) -> None:
    first = await client.post(
        "/api/submissions", data={"payload": json.dumps(_submission_payload())}
    )
    assert first.status_code == 201

    second_payload = _submission_payload()
    second_payload["nid"] = "9999999990"
    second_payload["mobile"] = "01911111111"
    # Same email as the first submission, differing only by case/whitespace.
    second_payload["email"] = "  Member@Example.com  "

    second = await client.post(
        "/api/submissions", data={"payload": json.dumps(second_payload)}
    )
    assert second.status_code == 409
    assert second.json()["detail"]["code"] == "APPLICATION_PENDING"
