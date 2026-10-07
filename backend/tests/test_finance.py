"""Fund transparency: transaction workflow (create/link/edit/approve/reject/
reverse/soft-delete), member-only visibility of approved rows, summary math,
filtered ledger, PDF report, notices integration and audit trail."""

from datetime import date, datetime, timedelta, timezone
from decimal import Decimal

import pytest
from httpx import AsyncClient
from sqlalchemy import select as sa_select

from app.core.security import create_access_token, hash_password
from app.models.admin import AdminRole, AdminUser
from app.models.config_list_item import ConfigListItem
from app.models.financial_transaction import FinancialTransaction
from app.models.installment import Installment, InstallmentStatus
from app.models.member import Member, MemberStatus
from app.models.notice import Notice
from app.models.picnic_payment import PicnicPayment
from app.services.finance import invalidate_summary_cache

pytestmark = pytest.mark.asyncio


@pytest.fixture(autouse=True)
def _clear_summary_cache():
    invalidate_summary_cache()
    yield
    invalidate_summary_cache()


async def _seed_categories(db_session) -> dict[str, ConfigListItem]:
    """The migration seeds these in production; tests build the tables from
    metadata, so seed the two finance config lists here."""
    items = {}
    seeds = [
        ("finance_income_category", "চাঁদা"),
        ("finance_income_category", "ভর্তি ফি"),
        ("finance_expense_category", "বিদ্যুৎ বিল"),
        ("finance_expense_category", "রক্ষণাবেক্ষণ"),
        ("finance_expense_category", "অনুষ্ঠান"),
    ]
    for sort, (category, label) in enumerate(seeds):
        item = ConfigListItem(category=category, value=label, label=label, sort_order=sort)
        db_session.add(item)
        items[label] = item
    await db_session.commit()
    for item in items.values():
        await db_session.refresh(item)
    return items


async def _approved_member(db_session, *, email="member@x.com") -> Member:
    member = Member(
        status=MemberStatus.APPROVED,
        member_id="UKAMKS-91",
        full_name="কামরুল হাসান",
        father_or_husband="Father",
        mother="Mother",
        dob="1990-01-01",
        nationality="Bangladeshi",
        occupation="Job",
        nid="1234567890",
        mobile="01758290411",
        gender="পুরুষ",
        email=email,
        admission_fee="500",
        subscription="100",
        receipt_no="R-1",
        payment_method="Cash",
        submission_date="2026-01-01",
    )
    db_session.add(member)
    await db_session.commit()
    await db_session.refresh(member)
    return member


async def _admin(db_session, *, email, role=AdminRole.EXECUTIVE_COMMITTEE) -> AdminUser:
    admin = AdminUser(
        email=email,
        password_hash=hash_password("pass12345"),
        name=f"Admin {email}",
        role=role,
    )
    db_session.add(admin)
    await db_session.commit()
    await db_session.refresh(admin)
    return admin


def _headers(account_id: int | str, role: str) -> dict:
    return {"Authorization": f"Bearer {create_access_token(str(account_id), role)}"}


def _income_payload(categories, **overrides) -> dict:
    payload = {
        "txn_date": "2026-10-05",
        "type": "income",
        "category_id": categories["চাঁদা"].id,
        "amount": "50000.00",
        "description": "অক্টোবর মাসের চাঁদা আদায়",
    }
    payload.update(overrides)
    return payload


def _expense_payload(categories, **overrides) -> dict:
    payload = {
        "txn_date": "2026-10-06",
        "type": "expense",
        "category_id": categories["বিদ্যুৎ বিল"].id,
        "amount": "8000.00",
        "description": "অক্টোবর মাসের বিদ্যুৎ বিল",
    }
    payload.update(overrides)
    return payload


async def _create(client, headers, payload) -> dict:
    response = await client.post("/api/admin/finance/transactions", json=payload, headers=headers)
    assert response.status_code == 201, response.text
    return response.json()


async def _approve(client, headers, txn_id) -> dict:
    response = await client.post(
        f"/api/admin/finance/transactions/{txn_id}/approve", headers=headers
    )
    assert response.status_code == 200, response.text
    return response.json()


# ---------------------------------------------------------------------------
# Creation, validation, reference numbers
# ---------------------------------------------------------------------------


async def test_create_auto_reference_and_categories_endpoint(client, db_session, admin_user):
    categories = await _seed_categories(db_session)
    headers = _headers(admin_user.id, "executive_committee")

    txn = await _create(client, headers, _income_payload(categories))
    assert txn["reference_no"] == f"FT-2026-0001"
    assert txn["status"] == "pending"
    assert txn["category_label"] == "চাঁদা"
    assert txn["created_by_name"].startswith("Admin")

    second = await _create(client, headers, _expense_payload(categories))
    assert second["reference_no"] == "FT-2026-0002"

    listed = await client.get("/api/admin/finance/categories", headers=headers)
    assert listed.status_code == 200
    labels = {item["label"]: item["type"] for item in listed.json()}
    assert labels["চাঁদা"] == "income"
    assert labels["বিদ্যুৎ বিল"] == "expense"


async def test_create_validates_amount_category_and_duplicate_reference(client, db_session, admin_user):
    categories = await _seed_categories(db_session)
    headers = _headers(admin_user.id, "executive_committee")

    bad_amount = await client.post(
        "/api/admin/finance/transactions",
        json=_income_payload(categories, amount="0"),
        headers=headers,
    )
    assert bad_amount.status_code == 422

    wrong_category = await client.post(
        "/api/admin/finance/transactions",
        json=_income_payload(categories, category_id=categories["বিদ্যুৎ বিল"].id),
        headers=headers,
    )
    assert wrong_category.status_code == 400

    txn = await _create(client, headers, _income_payload(categories))
    duplicate = await client.post(
        "/api/admin/finance/transactions",
        json=_income_payload(categories, reference_no=txn["reference_no"]),
        headers=headers,
    )
    assert duplicate.status_code == 409


async def test_payment_link_blocks_double_counting(client, db_session, admin_user):
    categories = await _seed_categories(db_session)
    member = await _approved_member(db_session)
    payment = PicnicPayment(
        member_id=member.id,
        head_price=1000,
        additional_price=0,
        additional_count=0,
        total=1000,
        payment_date=date(2026, 9, 20),
        receipt_no="PIC-1",
    )
    db_session.add(payment)
    await db_session.commit()
    await db_session.refresh(payment)

    headers = _headers(admin_user.id, "executive_committee")

    # Link on an expense is invalid at the schema level.
    expense_link = await client.post(
        "/api/admin/finance/transactions",
        json=_expense_payload(
            categories,
            linked_payment_type="picnic_payment",
            linked_payment_id=payment.id,
        ),
        headers=headers,
    )
    assert expense_link.status_code == 422

    unlinked = await client.get(
        "/api/admin/finance/unlinked-payments", headers=headers
    )
    assert unlinked.status_code == 200
    assert any(p["source_id"] == payment.id for p in unlinked.json())

    linked = await _create(
        client,
        headers,
        _income_payload(
            categories,
            linked_payment_type="picnic_payment",
            linked_payment_id=payment.id,
        ),
    )
    assert linked["linked_payment_type"] == "picnic_payment"

    again = await client.post(
        "/api/admin/finance/transactions",
        json=_income_payload(
            categories,
            linked_payment_type="picnic_payment",
            linked_payment_id=payment.id,
        ),
        headers=headers,
    )
    assert again.status_code == 409

    unlinked_after = await client.get(
        "/api/admin/finance/unlinked-payments", headers=headers
    )
    assert not any(p["source_id"] == payment.id for p in unlinked_after.json())


async def test_unlinked_payments_lists_paid_installments(client, db_session, admin_user):
    categories = await _seed_categories(db_session)
    member = await _approved_member(db_session)
    installment = Installment(
        member_id=member.id,
        year=2026,
        month=9,
        amount=100,
        status=InstallmentStatus.PAID,
        paid_at=datetime(2026, 9, 15, tzinfo=timezone.utc),
    )
    db_session.add(installment)
    await db_session.commit()

    headers = _headers(admin_user.id, "executive_committee")
    response = await client.get(
        "/api/admin/finance/unlinked-payments?source_type=installment", headers=headers
    )
    assert response.status_code == 200
    rows = response.json()
    assert len(rows) == 1
    assert rows[0]["member_name"] == "কামরুল হাসান"
    assert "চাঁদা" in rows[0]["detail"]


# ---------------------------------------------------------------------------
# Approval workflow
# ---------------------------------------------------------------------------


async def test_two_person_control_and_member_visibility(client, db_session, admin_user):
    categories = await _seed_categories(db_session)
    member = await _approved_member(db_session)
    approver = await _admin(db_session, email="approver@x.com")
    creator_headers = _headers(admin_user.id, "executive_committee")
    approver_headers = _headers(approver.id, "executive_committee")
    member_headers = _headers(member.id, "member")

    txn = await _create(client, creator_headers, _income_payload(categories))
    assert txn["status"] == "pending"

    # Members never see pending rows.
    ledger = await client.get("/api/member/finance/transactions", headers=member_headers)
    assert ledger.status_code == 200
    assert ledger.json()["total"] == 0

    # The creator cannot approve their own entry...
    own = await client.post(
        f"/api/admin/finance/transactions/{txn['id']}/approve", headers=creator_headers
    )
    assert own.status_code == 403

    # ...but another committee member can.
    approved = await _approve(client, approver_headers, txn["id"])
    assert approved["status"] == "approved"
    assert approved["approved_by_name"].startswith("Admin approver")

    ledger = await client.get("/api/member/finance/transactions", headers=member_headers)
    body = ledger.json()
    assert body["total"] == 1
    assert body["items"][0]["id"] == txn["id"]
    # Internal-only fields never reach the member projection.
    assert "internal_notes" not in body["items"][0]
    assert body["totals"]["income"] == "50000.00"


async def test_super_admin_can_approve_own_entry(client, db_session):
    categories = await _seed_categories(db_session)
    super_admin = await _admin(db_session, email="root@x.com", role=AdminRole.SUPER_ADMIN)
    headers = _headers(super_admin.id, "super_admin")
    txn = await _create(client, headers, _income_payload(categories))
    approved = await _approve(client, headers, txn["id"])
    assert approved["status"] == "approved"


async def test_reject_requires_reason_and_blocks_approved(client, db_session, admin_user):
    categories = await _seed_categories(db_session)
    approver = await _admin(db_session, email="approver@x.com")
    creator_headers = _headers(admin_user.id, "executive_committee")
    approver_headers = _headers(approver.id, "executive_committee")

    txn = await _create(client, creator_headers, _income_payload(categories))
    no_reason = await client.post(
        f"/api/admin/finance/transactions/{txn['id']}/reject", json={}, headers=approver_headers
    )
    assert no_reason.status_code == 422

    rejected = await client.post(
        f"/api/admin/finance/transactions/{txn['id']}/reject",
        json={"reason": "রশিদ পাওয়া যায়নি"},
        headers=approver_headers,
    )
    assert rejected.status_code == 200
    assert rejected.json()["status"] == "rejected"
    assert rejected.json()["rejection_reason"] == "রশিদ পাওয়া যায়নি"

    reject_approved = await client.post(
        f"/api/admin/finance/transactions/{txn['id']}/reject",
        json={"reason": "x"},
        headers=approver_headers,
    )
    assert reject_approved.status_code == 400


async def test_draft_submit_flow(client, db_session, admin_user):
    categories = await _seed_categories(db_session)
    headers = _headers(admin_user.id, "executive_committee")
    txn = await _create(client, headers, _income_payload(categories, status="draft"))
    assert txn["status"] == "draft"

    submitted = await client.post(
        f"/api/admin/finance/transactions/{txn['id']}/submit", headers=headers
    )
    assert submitted.status_code == 200
    assert submitted.json()["status"] == "pending"

    resubmit = await client.post(
        f"/api/admin/finance/transactions/{txn['id']}/submit", headers=headers
    )
    assert resubmit.status_code == 400


# ---------------------------------------------------------------------------
# Edit window, reversal, soft delete, audit
# ---------------------------------------------------------------------------


async def _approved_txn(db_session, client, categories, *, age_days=0):
    creator = await _admin(db_session, email=f"creator{age_days}@x.com")
    approver = await _admin(db_session, email=f"approver{age_days}@x.com")
    txn = await _create(
        client, _headers(creator.id, "executive_committee"), _expense_payload(categories)
    )
    await _approve(client, _headers(approver.id, "executive_committee"), txn["id"])
    row = (
        await db_session.execute(
            sa_select(FinancialTransaction).where(FinancialTransaction.id == txn["id"])
        )
    ).scalar_one()
    if age_days:
        row.approved_at = datetime.now(timezone.utc) - timedelta(days=age_days)
        await db_session.commit()
    return txn, creator, approver


async def test_edit_within_window_and_audit_diff(client, db_session, admin_user):
    categories = await _seed_categories(db_session)
    txn, creator, _ = await _approved_txn(db_session, client, categories, age_days=0)
    headers = _headers(creator.id, "executive_committee")

    patched = await client.patch(
        f"/api/admin/finance/transactions/{txn['id']}",
        json={"amount": "9000.00"},
        headers=headers,
    )
    assert patched.status_code == 200, patched.text
    assert patched.json()["amount"] == "9000.00"

    from app.models.audit_log import AuditLog

    logs = (
        await db_session.execute(
            sa_select(AuditLog).where(
                AuditLog.entity_id == str(txn["id"]), AuditLog.action == "finance_transaction.update"
            )
        )
    ).scalars().all()
    assert len(logs) == 1
    assert "amount: 8000.00 → 9000.00" in logs[0].detail


async def test_edit_blocked_after_window_and_reversal_works(client, db_session, admin_user):
    categories = await _seed_categories(db_session)
    txn, creator, approver = await _approved_txn(db_session, client, categories, age_days=8)
    headers = _headers(creator.id, "executive_committee")

    blocked = await client.patch(
        f"/api/admin/finance/transactions/{txn['id']}",
        json={"amount": "1.00"},
        headers=headers,
    )
    assert blocked.status_code == 409

    reversal = await client.post(
        f"/api/admin/finance/transactions/{txn['id']}/reverse",
        json={"reason": "বিল দুবার এন্ট্রি হয়েছিল"},
        headers=headers,
    )
    assert reversal.status_code == 201, reversal.text
    body = reversal.json()
    assert body["type"] == "income"  # opposite of the expense
    assert body["amount"] == "8000.00"
    assert body["status"] == "pending"
    assert body["reversal_of_id"] == txn["id"]


async def test_soft_delete_with_reason_hides_from_members(client, db_session, admin_user):
    categories = await _seed_categories(db_session)
    member = await _approved_member(db_session)
    txn, creator, approver = await _approved_txn(db_session, client, categories)
    member_headers = _headers(member.id, "member")

    no_reason = await client.request(
        "DELETE",
        f"/api/admin/finance/transactions/{txn['id']}",
        json={},
        headers=_headers(approver.id, "executive_committee"),
    )
    assert no_reason.status_code == 422

    deleted = await client.request(
        "DELETE",
        f"/api/admin/finance/transactions/{txn['id']}",
        json={"reason": "ভুল এন্ট্রি"},
        headers=_headers(approver.id, "executive_committee"),
    )
    assert deleted.status_code == 204

    ledger = await client.get("/api/member/finance/transactions", headers=member_headers)
    assert ledger.json()["total"] == 0

    # The row still exists for admins (audit trail) with include_inactive.
    admin_view = await client.get(
        "/api/admin/finance/transactions?include_inactive=true",
        headers=_headers(creator.id, "executive_committee"),
    )
    assert any(item["id"] == txn["id"] for item in admin_view.json()["items"])


# ---------------------------------------------------------------------------
# Summary math, filters, pagination, PDF
# ---------------------------------------------------------------------------


async def _seed_ledger(db_session, client, categories):
    """Three admins trade approval duties so two-person control holds."""
    a1 = await _admin(db_session, email="s1@x.com")
    a2 = await _admin(db_session, email="s2@x.com")
    h1 = _headers(a1.id, "executive_committee")
    h2 = _headers(a2.id, "executive_committee")

    rows = [
        _income_payload(categories, txn_date="2026-09-10", amount="30000.00", description="সেপ্টেম্বর চাঁদা"),
        _income_payload(categories, txn_date="2026-10-02", amount="50000.00", description="অক্টোবর চাঁদা"),
        _expense_payload(categories, txn_date="2026-09-12", amount="12000.00"),
        _expense_payload(categories, txn_date="2026-10-03", amount="6000.00"),
        _expense_payload(categories, txn_date="2026-10-07", amount="8000.00", category_id=categories["অনুষ্ঠান"].id),
    ]
    created = []
    for index, payload in enumerate(rows):
        (creator, approver) = (h1, h2) if index % 2 == 0 else (h2, h1)
        txn = await _create(client, creator, payload)
        await _approve(client, approver, txn["id"])
        created.append(txn)
    return created


async def test_member_summary_math_and_series(client, db_session, admin_user):
    categories = await _seed_categories(db_session)
    await _seed_ledger(db_session, client, categories)
    member = await _approved_member(db_session)

    response = await client.get(
        "/api/member/finance/summary?period=year", headers=_headers(member.id, "member")
    )
    assert response.status_code == 200
    body = response.json()

    assert body["totals"] == {"income": "80000.00", "expense": "26000.00", "net": "54000.00"}
    assert body["balance"] == "54000.00"
    assert body["transaction_count"] == 5
    assert body["granularity"] == "year"
    labels = [point["label"] for point in body["series"]]
    assert str(date.today().year) in labels
    assert body["last_updated"] is not None

    income_map = {row["category"]: row for row in body["income_by_category"]}
    assert income_map["চাঁদা"]["amount"] == "80000.00"
    assert income_map["চাঁদা"]["share"] == "100.00"

    expense_map = {row["category"]: row for row in body["expense_by_category"]}
    assert expense_map["বিদ্যুৎ বিল"]["amount"] == "18000.00"

    # 'all' has no previous window.
    all_body = (
        await client.get(
            "/api/member/finance/summary?period=all", headers=_headers(member.id, "member")
        )
    ).json()
    assert all_body["previous"] is None
    assert all_body["balance"] == "54000.00"


async def test_ledger_filters_pagination_and_synced_totals(client, db_session, admin_user):
    categories = await _seed_categories(db_session)
    await _seed_ledger(db_session, client, categories)
    member = await _approved_member(db_session)
    headers = _headers(member.id, "member")

    base = "/api/member/finance/transactions"
    page1 = (await client.get(f"{base}?limit=2&offset=0", headers=headers)).json()
    page2 = (await client.get(f"{base}?limit=2&offset=2", headers=headers)).json()
    assert page1["total"] == 5 and len(page1["items"]) == 2
    assert page2["items"][0]["id"] != page1["items"][0]["id"]
    assert page1["items"][0]["txn_date"] >= page1["items"][1]["txn_date"]

    # Filters update the story (totals), not just the table.
    only_expense = (await client.get(f"{base}?type=expense", headers=headers)).json()
    assert only_expense["totals"] == {"income": "0.00", "expense": "26000.00", "net": "-26000.00"}

    searched = (
        await client.get(f"{base}?search=অক্টোবর চাঁদা", headers=headers)
    ).json()
    assert searched["total"] == 1
    assert searched["totals"]["income"] == "50000.00"

    by_amount = (
        await client.get(f"{base}?min_amount=10000", headers=headers)
    ).json()
    assert by_amount["total"] == 3  # 30000, 50000, 12000

    by_category = (
        await client.get(
            f"{base}?category_id={categories['অনুষ্ঠান'].id}", headers=headers
        )
    ).json()
    assert by_category["total"] == 1

    custom_errors = await client.get(
        "/api/member/finance/summary?period=custom", headers=headers
    )
    assert custom_errors.status_code == 400


async def test_pdf_report_is_a_real_pdf(client, db_session, admin_user):
    categories = await _seed_categories(db_session)
    await _seed_ledger(db_session, client, categories)
    member = await _approved_member(db_session)

    response = await client.get(
        "/api/member/finance/report.pdf?period=year",
        headers=_headers(member.id, "member"),
    )
    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"
    assert "attachment" in response.headers.get("content-disposition", "")
    assert response.content[:5] == b"%PDF-"
    assert len(response.content) > 5000

    filtered = await client.get(
        "/api/member/finance/report.pdf?period=year&type=expense",
        headers=_headers(admin_user.id, "executive_committee"),
    )
    assert filtered.status_code == 200
    assert filtered.content[:5] == b"%PDF-"


async def test_admin_overview_widget(client, db_session, admin_user):
    categories = await _seed_categories(db_session)
    await _seed_ledger(db_session, client, categories)
    # One pending row that should show up in the widget.
    await _create(client, _headers(admin_user.id, "executive_committee"), _expense_payload(categories))

    response = await client.get(
        "/api/admin/finance/overview",
        headers=_headers(admin_user.id, "executive_committee"),
    )
    assert response.status_code == 200
    body = response.json()
    assert body["pending_count"] == 1
    assert Decimal(body["balance"]) == Decimal("54000.00")
    assert len(body["recent"]) == 5  # endpoint keeps the widget light
    assert body["recent"][0]["status"] == "pending"  # newest first


# ---------------------------------------------------------------------------
# Notices integration, permission gating, cache invalidation
# ---------------------------------------------------------------------------


async def test_threshold_approve_publishes_notice(client, db_session, admin_user, monkeypatch):
    from app.core.config import get_settings

    settings = get_settings()
    monkeypatch.setattr(settings, "finance_notice_threshold", 40000)

    categories = await _seed_categories(db_session)
    creator = await _admin(db_session, email="c@x.com")
    txn = await _create(
        client, _headers(creator.id, "executive_committee"), _income_payload(categories)
    )
    await _approve(client, _headers(admin_user.id, "executive_committee"), txn["id"])

    notices = (await db_session.execute(sa_select(Notice))).scalars().all()
    assert len(notices) == 1
    assert "50,000.00" in notices[0].body
    assert notices[0].is_published is True


async def test_below_threshold_no_notice(client, db_session, admin_user, monkeypatch):
    from app.core.config import get_settings

    settings = get_settings()
    monkeypatch.setattr(settings, "finance_notice_threshold", 60000)

    categories = await _seed_categories(db_session)
    creator = await _admin(db_session, email="c2@x.com")
    txn = await _create(
        client, _headers(creator.id, "executive_committee"), _income_payload(categories)
    )
    await _approve(client, _headers(admin_user.id, "executive_committee"), txn["id"])

    notices = (await db_session.execute(sa_select(Notice))).scalars().all()
    assert notices == []


async def test_publish_report_notice(client, db_session, admin_user):
    categories = await _seed_categories(db_session)
    await _seed_ledger(db_session, client, categories)

    response = await client.post(
        "/api/admin/finance/publish-report-notice",
        json={"period": "year"},
        headers=_headers(admin_user.id, "executive_committee"),
    )
    assert response.status_code == 201

    notices = (await db_session.execute(sa_select(Notice))).scalars().all()
    report_notices = [n for n in notices if n.title == "আর্থিক রিপোর্ট প্রকাশিত হয়েছে"]
    assert len(report_notices) == 1
    assert "80,000.00" in report_notices[0].body


async def test_member_cannot_use_admin_endpoints(client, db_session, admin_user):
    categories = await _seed_categories(db_session)
    member = await _approved_member(db_session)
    member_headers = _headers(member.id, "member")

    for method, path in [
        ("get", "/api/admin/finance/transactions"),
        ("post", "/api/admin/finance/transactions"),
        ("get", "/api/admin/finance/overview"),
    ]:
        response = await client.request(method, path, headers=member_headers)
        assert response.status_code in (401, 403), (method, path, response.status_code)

    unauthenticated = await client.get("/api/member/finance/summary")
    assert unauthenticated.status_code == 401


async def test_summary_cache_invalidated_on_approve(client, db_session, admin_user):
    categories = await _seed_categories(db_session)
    member = await _approved_member(db_session)
    headers = _headers(member.id, "member")
    creator = await _admin(db_session, email="cc@x.com")

    before = (
        await client.get("/api/member/finance/summary?period=all", headers=headers)
    ).json()
    assert before["totals"]["income"] == "0.00"

    txn = await _create(
        client, _headers(creator.id, "executive_committee"), _income_payload(categories)
    )
    await _approve(client, _headers(admin_user.id, "executive_committee"), txn["id"])

    after = (
        await client.get("/api/member/finance/summary?period=all", headers=headers)
    ).json()
    assert after["totals"]["income"] == "50000.00"
