from datetime import date, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, hash_password
from app.models.admin import AdminRole, AdminUser
from app.models.config_list_item import ConfigListItem
from app.models.installment import Installment, InstallmentStatus
from app.models.member import Member

pytestmark = pytest.mark.asyncio

URL = "/api/member/installment-payments"


async def _seed_accounts(db: AsyncSession) -> None:
    db.add_all(
        [
            ConfigListItem(category="payment_account", value="bKash", label="01700000000 (Merchant)"),
            ConfigListItem(category="payment_account", value="Bank", label="Sonali Bank A/C 123"),
        ]
    )
    await db.commit()


async def _seed_member(db: AsyncSession, email: str) -> Member:
    member = Member(
        status="approved",
        full_name=email.split("@")[0],
        father_or_husband="f",
        mother="m",
        dob="1990-01-01",
        nationality="Bangladeshi",
        occupation="job",
        nid=str(abs(hash(email)) % 10**10),
        mobile="0170000000",
        gender="male",
        email=email,
        admission_fee="500",
        subscription="100",
        receipt_no="r",
        payment_method="cash",
        submission_date="2026-01-01",
    )
    db.add(member)
    await db.commit()
    await db.refresh(member)
    return member


async def _seed_due(db: AsyncSession, member: Member, months: list[int], amount: int = 200) -> list[Installment]:
    rows = [Installment(member_id=member.id, year=2026, month=m, amount=amount) for m in months]
    db.add_all(rows)
    await db.commit()
    for row in rows:
        await db.refresh(row)
    return rows


async def _seed_admin(db: AsyncSession) -> AdminUser:
    admin = AdminUser(
        email="fin@example.com", password_hash=hash_password("pass12345"), name="fin", role=AdminRole.SUPER_ADMIN
    )
    db.add(admin)
    await db.commit()
    await db.refresh(admin)
    return admin


def _member_headers(member: Member) -> dict[str, str]:
    return {"Authorization": f"Bearer {create_access_token(str(member.id), 'member')}"}


def _admin_headers(admin: AdminUser) -> dict[str, str]:
    return {"Authorization": f"Bearer {create_access_token(str(admin.id), admin.role.value)}"}


def _form(ids: list[int], ref: str = "TRX12345", method: str = "bkash", **extra: str) -> dict[str, str]:
    return {
        "installment_ids": ",".join(str(i) for i in ids),
        "method": method,
        "transaction_ref": ref,
        "paid_on": date.today().isoformat(),
        **extra,
    }


async def test_payable_summary_lists_due_months_and_accounts(client: AsyncClient, db_session: AsyncSession) -> None:
    await _seed_accounts(db_session)
    member = await _seed_member(db_session, "a@example.com")
    await _seed_due(db_session, member, [1, 2])

    response = await client.get(f"{URL}/payable", headers=_member_headers(member))

    assert response.status_code == 200
    body = response.json()
    assert [i["month"] for i in body["due"]] == [1, 2]
    assert float(body["total_due"]) == 400
    assert {a["method"] for a in body["accounts"]} == {"bKash", "Bank"}


async def test_submit_computes_amount_server_side_and_marks_pending(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    await _seed_accounts(db_session)
    member = await _seed_member(db_session, "b@example.com")
    due = await _seed_due(db_session, member, [3, 4])

    response = await client.post(
        URL, data=_form([d.id for d in due], ref="ab12cd", amount="1"), headers=_member_headers(member)
    )

    assert response.status_code == 201, response.text
    body = response.json()
    assert float(body["amount"]) == 400
    assert body["status"] == "pending"
    assert body["method"] == "bKash"
    assert body["transaction_ref"] == "AB12CD"
    assert [i["month"] for i in body["installments"]] == [3, 4]

    summary = (await client.get(f"{URL}/payable", headers=_member_headers(member))).json()
    assert sorted(summary["pending_installment_ids"]) == sorted(d.id for d in due)
    assert float(summary["total_due"]) == 0


async def test_cannot_pay_another_members_installment(client: AsyncClient, db_session: AsyncSession) -> None:
    await _seed_accounts(db_session)
    me = await _seed_member(db_session, "me@example.com")
    other = await _seed_member(db_session, "other@example.com")
    theirs = await _seed_due(db_session, other, [5])

    response = await client.post(URL, data=_form([theirs[0].id]), headers=_member_headers(me))

    assert response.status_code == 404


async def test_rejects_double_submission_and_duplicate_reference(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    await _seed_accounts(db_session)
    member = await _seed_member(db_session, "c@example.com")
    jan, feb = await _seed_due(db_session, member, [1, 2])
    headers = _member_headers(member)

    assert (await client.post(URL, data=_form([jan.id], ref="REF0001"), headers=headers)).status_code == 201
    same_month = await client.post(URL, data=_form([jan.id], ref="REF0002"), headers=headers)
    same_ref = await client.post(URL, data=_form([feb.id], ref="ref0001"), headers=headers)

    assert same_month.status_code == 409
    assert same_ref.status_code == 409


@pytest.mark.parametrize(
    "overrides,expected",
    [
        ({"method": "Cheque"}, 422),
        ({"paid_on": (date.today() + timedelta(days=2)).isoformat()}, 422),
        ({"transaction_ref": "bad<ref>"}, 422),
        ({"installment_ids": "x,y"}, 422),
        ({"installment_ids": ""}, 422),
    ],
)
async def test_submit_validation_errors(
    client: AsyncClient, db_session: AsyncSession, overrides: dict, expected: int
) -> None:
    await _seed_accounts(db_session)
    member = await _seed_member(db_session, "d@example.com")
    due = await _seed_due(db_session, member, [6])

    response = await client.post(URL, data={**_form([due[0].id]), **overrides}, headers=_member_headers(member))

    assert response.status_code == expected


async def test_submit_fails_when_no_payment_account_configured(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    member = await _seed_member(db_session, "e@example.com")
    due = await _seed_due(db_session, member, [7])

    response = await client.post(URL, data=_form([due[0].id]), headers=_member_headers(member))

    assert response.status_code == 422
    assert "not set up" in response.json()["detail"]


async def test_approve_marks_installments_paid(client: AsyncClient, db_session: AsyncSession) -> None:
    await _seed_accounts(db_session)
    admin = await _seed_admin(db_session)
    member = await _seed_member(db_session, "f@example.com")
    due = await _seed_due(db_session, member, [8, 9])
    created = await client.post(URL, data=_form([d.id for d in due]), headers=_member_headers(member))
    payment_id = created.json()["id"]

    pending = await client.get(
        "/api/admin/installment-payments?status=pending", headers=_admin_headers(admin)
    )
    count = await client.get("/api/admin/installment-payments/pending-count", headers=_admin_headers(admin))
    response = await client.post(
        f"/api/admin/installment-payments/{payment_id}/approve", headers=_admin_headers(admin)
    )
    again = await client.post(
        f"/api/admin/installment-payments/{payment_id}/approve", headers=_admin_headers(admin)
    )

    assert [p["id"] for p in pending.json()] == [payment_id]
    assert pending.json()[0]["member_name"] == "f"
    assert count.json() == {"count": 1}
    assert response.status_code == 200
    assert response.json()["status"] == "approved"
    assert again.status_code == 409
    rows = (await db_session.execute(select(Installment).where(Installment.member_id == member.id).execution_options(populate_existing=True)
    )).scalars()
    assert all(r.status == InstallmentStatus.PAID and r.paid_at is not None for r in rows)


async def test_reject_keeps_installments_due_and_allows_resubmit(
    client: AsyncClient, db_session: AsyncSession
) -> None:
    await _seed_accounts(db_session)
    admin = await _seed_admin(db_session)
    member = await _seed_member(db_session, "g@example.com")
    due = await _seed_due(db_session, member, [10])
    created = await client.post(URL, data=_form([due[0].id], ref="WRONG01"), headers=_member_headers(member))

    response = await client.post(
        f"/api/admin/installment-payments/{created.json()['id']}/reject",
        json={"reason": "Transaction not found"},
        headers=_admin_headers(admin),
    )
    resubmit = await client.post(URL, data=_form([due[0].id], ref="RIGHT01"), headers=_member_headers(member))
    history = await client.get(URL, headers=_member_headers(member))

    assert response.status_code == 200
    assert response.json()["rejection_reason"] == "Transaction not found"
    assert resubmit.status_code == 201
    assert [p["status"] for p in history.json()] == ["pending", "rejected"]


async def test_member_cannot_use_admin_endpoints(client: AsyncClient, db_session: AsyncSession) -> None:
    member = await _seed_member(db_session, "h@example.com")

    response = await client.get("/api/admin/installment-payments", headers=_member_headers(member))

    assert response.status_code in (401, 403)


async def test_admin_cannot_pay_as_member(client: AsyncClient, db_session: AsyncSession) -> None:
    admin = await _seed_admin(db_session)

    response = await client.get(f"{URL}/payable", headers=_admin_headers(admin))

    assert response.status_code == 403
