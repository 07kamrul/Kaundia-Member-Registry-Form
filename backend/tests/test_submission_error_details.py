"""POST /api/submissions returns structured, field-level error bodies so the
registration form can show meaningful messages instead of a generic one."""

import json

import pytest
from httpx import AsyncClient
from sqlalchemy import delete

from app.models.fee_settings import FeeSetting
from tests.test_submission_flow import _submission_payload

pytestmark = pytest.mark.asyncio


async def _post(client: AsyncClient, payload: str):
    return await client.post("/api/submissions", data={"payload": payload})


async def test_invalid_email_returns_field_level_errors(client: AsyncClient) -> None:
    payload = {**_submission_payload(), "email": "not-an-email"}

    response = await _post(client, json.dumps(payload))

    assert response.status_code == 422
    detail = response.json()["detail"]
    assert detail["code"] == "VALIDATION_ERROR"
    assert [e["field"] for e in detail["errors"]] == ["email"]


async def test_missing_required_field_is_reported_by_name(client: AsyncClient) -> None:
    payload = _submission_payload()
    del payload["full_name"]

    response = await _post(client, json.dumps(payload))

    detail = response.json()["detail"]
    assert detail["errors"][0] == {
        "field": "full_name",
        "code": "missing",
        "message": "Field required",
    }


async def test_malformed_json_returns_invalid_payload_code(client: AsyncClient) -> None:
    response = await _post(client, "{not json")

    assert response.status_code == 422
    assert response.json()["detail"]["code"] == "INVALID_PAYLOAD"


async def test_missing_fee_setting_returns_fee_not_configured(client: AsyncClient, db_session) -> None:
    await db_session.execute(delete(FeeSetting).where(FeeSetting.key == "admission_fee"))
    await db_session.commit()

    response = await _post(client, json.dumps(_submission_payload()))

    assert response.status_code == 409
    assert response.json()["detail"]["code"] == "FEE_NOT_CONFIGURED"
