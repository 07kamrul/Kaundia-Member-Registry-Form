import json
import re

import pytest
from httpx import AsyncClient

from app.api.routes import admin as admin_routes
from app.models.admin import AdminUser

pytestmark = pytest.mark.asyncio


def _submission_payload() -> dict:
    return {
        "full_name": "Test User",
        "father_or_husband": "Test Father",
        "mother": "Test Mother",
        "dob": "1990-01-01",
        "nationality": "Bangladeshi",
        "occupation": "Farmer",
        "nid": "1234567890",
        "mobile": "01700000000",
        "whatsapp": "01700000000",
        "email": "member@example.com",
        "permanent_address": {
            "house": "12",
            "road": "Village Road",
            "post_office": "Savar",
            "upazila": "Savar",
            "district": "Dhaka",
        },
        "current_address": {
            "house": "12",
            "road": "Village Road",
            "post_office": "Savar",
            "upazila": "Savar",
            "district": "Dhaka",
        },
        "urgent_contact_name": "Contact Person",
        "urgent_contact_relation": "Brother",
        "urgent_contact_mobile": "01800000000",
        "urgent_contact_address": "Village Road",
        "properties": [
            {
                "property_type": ["কৃষি জমি"],
                "property_type_other": "",
                "khatian_no": "123",
                "dag_no_cs": "45",
                "dag_no_rs": "67",
                "land_quantity": "1.5 acre",
                "ownership": "একক",
                "co_owners": [],
                "applicable_docs": [],
            }
        ],
        "nominees": [
            {"name": "Nominee One", "relation": "Son", "mobile": "01900000000", "address": "Village Road"}
        ],
        "admission_fee": "500",
        "subscription": "100",
        "receipt_no": "R-001",
        "payment_method": "Cash",
        "member_signature": "",
        "submission_date": "2026-09-15",
    }


async def test_submission_approval_member_id_login_flow(
    client: AsyncClient, admin_user: AdminUser, monkeypatch: pytest.MonkeyPatch
) -> None:
    sent_emails: list[dict] = []

    async def fake_send_email(to: str, subject: str, html_body: str) -> bool:
        sent_emails.append({"to": to, "subject": subject, "html_body": html_body})
        return True

    monkeypatch.setattr(admin_routes, "send_email", fake_send_email)

    # 1. Public submission
    response = await client.post(
        "/api/submissions",
        data={"payload": json.dumps(_submission_payload())},
    )
    assert response.status_code == 201
    submission = response.json()
    assert submission["status"] == "pending"
    member_pk = submission["id"]

    # 1b. Pending (unverified) member cannot log in yet — no credential exists
    pending_login = await client.post(
        "/api/member/login",
        json={"username": "any-username", "password": "any-password"},
    )
    assert pending_login.status_code == 401

    # 2. Admin login
    login_response = await client.post(
        "/api/admin/login", json={"email": "admin@example.com", "password": "adminpass123"}
    )
    assert login_response.status_code == 200
    admin_token = login_response.json()["access_token"]
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    # 3. Admin sees pending submission
    list_response = await client.get("/api/admin/submissions?status=pending", headers=admin_headers)
    assert list_response.status_code == 200
    assert any(item["id"] == member_pk for item in list_response.json())

    # 4. Approve submission -> member_id assigned
    approve_response = await client.post(
        f"/api/admin/submissions/{member_pk}/approve", headers=admin_headers
    )
    assert approve_response.status_code == 200
    generated_member_id = approve_response.json()["member_id"]
    assert generated_member_id.startswith("KAM-")

    detail_response = await client.get(
        f"/api/admin/submissions/{member_pk}", headers=admin_headers
    )
    assert detail_response.status_code == 200
    assert detail_response.json()["status"] == "approved"
    assert detail_response.json()["member_id"] == generated_member_id

    # 5. Wrong password is rejected
    bad_login = await client.post(
        "/api/member/login",
        json={"username": generated_member_id.lower(), "password": "wrong-password"},
    )
    assert bad_login.status_code == 401

    # 6. Extract the temp password from the "sent" approval email and log in
    assert len(sent_emails) == 1
    match = re.search(r"Temporary password: <b>(.+?)</b>", sent_emails[0]["html_body"])
    assert match is not None
    temp_password = match.group(1)

    member_login = await client.post(
        "/api/member/login",
        json={"username": generated_member_id.lower(), "password": temp_password},
    )
    assert member_login.status_code == 200
    member_login_body = member_login.json()
    assert member_login_body["must_change_password"] is True
    member_token = member_login_body["access_token"]
    member_headers = {"Authorization": f"Bearer {member_token}"}

    # 7. Member can fetch own profile
    profile_response = await client.get("/api/member/me", headers=member_headers)
    assert profile_response.status_code == 200
    assert profile_response.json()["member_id"] == generated_member_id

    # 8. Member changes password
    change_response = await client.post(
        "/api/member/change-password",
        json={"current_password": temp_password, "new_password": "newpass123"},
        headers=member_headers,
    )
    assert change_response.status_code == 204

    relogin = await client.post(
        "/api/member/login",
        json={"username": generated_member_id.lower(), "password": "newpass123"},
    )
    assert relogin.status_code == 200
    assert relogin.json()["must_change_password"] is False


async def test_reject_submission(client: AsyncClient, admin_user: AdminUser) -> None:
    response = await client.post(
        "/api/submissions",
        data={"payload": json.dumps(_submission_payload())},
    )
    member_pk = response.json()["id"]

    login_response = await client.post(
        "/api/admin/login", json={"email": "admin@example.com", "password": "adminpass123"}
    )
    admin_headers = {"Authorization": f"Bearer {login_response.json()['access_token']}"}

    reject_response = await client.post(
        f"/api/admin/submissions/{member_pk}/reject",
        json={"reason": "Incomplete documents"},
        headers=admin_headers,
    )
    assert reject_response.status_code == 204

    detail_response = await client.get(
        f"/api/admin/submissions/{member_pk}", headers=admin_headers
    )
    assert detail_response.json()["status"] == "rejected"
