"""Config list CRUD: admin vs public visibility, duplicate rejection, and
audit rows for each write."""

import pytest
from httpx import AsyncClient
from sqlalchemy import text

from app.models.admin import AdminUser

pytestmark = pytest.mark.asyncio


async def _admin_headers(client: AsyncClient) -> dict:
    response = await client.post(
        "/api/admin/login", json={"email": "admin@example.com", "password": "adminpass123"}
    )
    assert response.status_code == 200
    return {"Authorization": f"Bearer {response.json()['access_token']}"}


async def _create(client: AsyncClient, headers: dict, value: str, **kwargs) -> dict:
    response = await client.post(
        "/api/admin/config-lists",
        json={"category": "property_type", "value": value, "label": kwargs.pop("label", value), **kwargs},
        headers=headers,
    )
    return response


async def test_created_item_appears_in_admin_list_and_public_list(
    client: AsyncClient, admin_user: AdminUser
) -> None:
    headers = await _admin_headers(client)
    created = await _create(client, headers, "কৃষি জমি", label="Agricultural Land")
    assert created.status_code == 201, created.text

    admin_list = await client.get(
        "/api/admin/config-lists", params={"category": "property_type"}, headers=headers
    )
    assert any(item["value"] == "কৃষি জমি" for item in admin_list.json())

    public_list = await client.get("/api/public/config-lists/property_type")
    assert public_list.status_code == 200
    assert any(item["value"] == "কৃষি জমি" for item in public_list.json())


async def test_inactive_item_hidden_from_public_but_visible_to_admin(
    client: AsyncClient, admin_user: AdminUser
) -> None:
    headers = await _admin_headers(client)
    created = await _create(client, headers, "শিল্প জমি")
    item_id = created.json()["id"]

    toggle = await client.patch(
        f"/api/admin/config-lists/{item_id}", json={"is_active": False}, headers=headers
    )
    assert toggle.status_code == 200, toggle.text

    public_list = await client.get("/api/public/config-lists/property_type")
    assert all(item["value"] != "শিল্প জমি" for item in public_list.json())

    admin_list = await client.get(
        "/api/admin/config-lists", params={"category": "property_type"}, headers=headers
    )
    assert any(item["id"] == item_id for item in admin_list.json())


async def test_duplicate_category_value_rejected_with_400(
    client: AsyncClient, admin_user: AdminUser
) -> None:
    headers = await _admin_headers(client)
    first = await _create(client, headers, "বাণিজ্যিক জমি")
    assert first.status_code == 201

    duplicate = await _create(client, headers, "বাণিজ্যিক জমি")
    assert duplicate.status_code == 400
    assert "already exists" in duplicate.json()["detail"]


async def test_same_value_in_different_category_is_allowed(
    client: AsyncClient, admin_user: AdminUser
) -> None:
    headers = await _admin_headers(client)
    assert (await _create(client, headers, "উপকূল")).status_code == 201
    other = await client.post(
        "/api/admin/config-lists",
        json={"category": "ownership_type", "value": "উপকূল", "label": "উপকূল"},
        headers=headers,
    )
    assert other.status_code == 201


async def test_config_list_writes_produce_exactly_one_audit_row_each(
    client: AsyncClient, db_session, admin_user: AdminUser
) -> None:
    headers = await _admin_headers(client)
    created = await _create(client, headers, "চাষের জমি")
    item_id = created.json()["id"]
    await client.patch(
        f"/api/admin/config-lists/{item_id}", json={"is_active": False}, headers=headers
    )

    rows = (
        (
            await db_session.execute(
                text(
                    "SELECT action, actor_admin_id, entity_id FROM audit_logs "
                    "WHERE entity_type='config_list_item' ORDER BY id"
                )
            )
        )
        .all()
    )
    assert rows == [
        ("config_list.create", admin_user.id, f"property_type:চাষের জমি"),
        ("config_list.update", admin_user.id, f"property_type:চাষের জমি"),
    ]
