"""Fund transparency: member-facing read endpoints plus the committee's
transaction workflow (create/link/edit/approve/reject/reverse/soft-delete).

Members (and any authenticated admin-tier account) see ONLY approved,
active rows; the committee manages everything behind `manage_finance`.
Every mutating action writes an audit-log row; period summaries are cached
and invalidated on write via app.services.finance.
"""
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal

from fastapi import APIRouter, Depends, File, HTTPException, Query, Response, UploadFile, status
from sqlalchemy import case, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import get_settings
from app.core.deps import AccountActor, get_account_actor
from app.core.permissions import is_super_admin, require_permission
from app.db.session import get_db
from app.models.admin import AdminUser
from app.models.config_list_item import ConfigListItem
from app.models.installment import Installment, InstallmentStatus
from app.models.financial_transaction import (
    FINANCE_EXPENSE_CATEGORY,
    FINANCE_INCOME_CATEGORY,
    FINANCE_SOURCE_COST_SHARE,
    FINANCE_SOURCE_INSTALLMENT,
    FINANCE_SOURCE_PICNIC_PAYMENT,
    FINANCE_SOURCES,
    FINANCE_STATUS_APPROVED,
    FINANCE_STATUS_DRAFT,
    FINANCE_STATUS_PENDING,
    FINANCE_STATUS_REJECTED,
    FINANCE_TYPES,
    FINANCE_TYPE_EXPENSE,
    FINANCE_TYPE_INCOME,
    FinancialTransaction,
)
from app.models.notice import Notice
from app.models.picnic_payment import PicnicPayment
from app.models.society_cost import CostSplit, CostSplitShare, SocietyCost
from app.schemas.finance import (
    FinanceAdminLedgerOut,
    FinanceCategoryOut,
    FinanceLedgerOut,
    FinanceNoticeThresholdOut,
    FinanceOverviewOut,
    FinanceRejectIn,
    FinanceReportNoticeIn,
    FinanceReverseIn,
    FinanceSummaryOut,
    FinanceTotalsOut,
    FinanceTransactionAdminOut,
    FinanceTransactionCreate,
    FinanceTransactionOut,
    FinanceTransactionUpdate,
    UnlinkedPaymentOut,
)
from app.services.audit import record_audit
from app.services.finance import (
    BN_MONTHS,
    PERIOD_ALL,
    PERIOD_CUSTOM,
    PERIOD_MONTH,
    PERIOD_TYPES,
    PERIOD_YEAR,
    _sum_between,
    balance_all_time,
    format_taka,
    get_summary,
    invalidate_summary_cache,
    next_reference_no,
    period_label,
    resolve_period,
)
from app.services.finance_pdf import FinanceReportData, build_finance_report_pdf
from app.services.storage import save_upload_file

router = APIRouter(tags=["finance"])

settings = get_settings()

# Approved figures may already be public (downloaded reports), so silent
# edits are only allowed briefly; afterwards a correction entry (reversal)
# is required. Window is measured from the approval timestamp.
APPROVED_EDIT_WINDOW_DAYS = 7
_PDF_MAX_ROWS = 1000
_UNLINKED_DEFAULT_LIMIT = 50
_UNLINKED_MAX_LIMIT = 200

_TWO_PLACES = Decimal("0.01")
_DHAKA = timezone(timedelta(hours=6), name="Asia/Dhaka")


def _category_list_for(txn_type: str) -> str:
    return FINANCE_INCOME_CATEGORY if txn_type == FINANCE_TYPE_INCOME else FINANCE_EXPENSE_CATEGORY


async def _require_category_of_type(db: AsyncSession, category_id: int, txn_type: str) -> ConfigListItem:
    result = await db.execute(select(ConfigListItem).where(ConfigListItem.id == category_id))
    item = result.scalar_one_or_none()
    if item is None or item.category != _category_list_for(txn_type):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Category {category_id} is not an active {'income' if txn_type == FINANCE_TYPE_INCOME else 'expense'} category.",
        )
    return item


async def _assert_payment_link(
    db: AsyncSession,
    linked_type: str | None,
    linked_id: int | None,
    *,
    exclude_txn_id: int | None = None,
) -> None:
    if linked_type is None and linked_id is None:
        return
    if linked_type not in FINANCE_SOURCES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unknown payment source '{linked_type}'.",
        )
    if linked_type == FINANCE_SOURCE_INSTALLMENT:
        exists_q = select(Installment.id).where(Installment.id == linked_id)
    elif linked_type == FINANCE_SOURCE_PICNIC_PAYMENT:
        exists_q = select(PicnicPayment.id).where(PicnicPayment.id == linked_id)
    else:
        exists_q = select(CostSplitShare.id).where(CostSplitShare.id == linked_id)
    if (await db.execute(exists_q)).scalar_one_or_none() is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Payment {linked_type}#{linked_id} does not exist.",
        )
    clash_q = select(FinancialTransaction.id).where(
        FinancialTransaction.linked_payment_type == linked_type,
        FinancialTransaction.linked_payment_id == linked_id,
        FinancialTransaction.is_active == 1,
    )
    if exclude_txn_id is not None:
        clash_q = clash_q.where(FinancialTransaction.id != exclude_txn_id)
    clash = (await db.execute(clash_q)).scalar_one_or_none()
    if clash is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Payment {linked_type}#{linked_id} is already linked to transaction #{clash}.",
        )


async def _load_txn(
    db: AsyncSession, txn_id: int, *, include_inactive: bool = False
) -> FinancialTransaction:
    query = select(FinancialTransaction).where(FinancialTransaction.id == txn_id)
    if not include_inactive:
        query = query.where(FinancialTransaction.is_active == 1)
    txn = (await db.execute(query)).scalar_one_or_none()
    if txn is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Transaction not found")
    return txn


def _txn_out(txn: FinancialTransaction, *, admin: bool) -> FinanceTransactionOut | FinanceTransactionAdminOut:
    if admin:
        out = FinanceTransactionAdminOut.model_validate(txn)
        if txn.creator is not None:
            out.created_by_name = txn.creator.name
    else:
        out = FinanceTransactionOut.model_validate(txn)
    if txn.category is not None:
        out.category_label = txn.category.label
    if txn.approver is not None:
        out.approved_by_name = txn.approver.name
    return out


def _assert_custom_period(period: str, date_from: date | None, date_to: date | None) -> None:
    if period == PERIOD_CUSTOM and (date_from is None or date_to is None):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Custom period requires both date_from and date_to.",
        )
    if date_from is not None and date_to is not None and date_from > date_to:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="date_from must not be after date_to.",
        )


def _ledger_conditions(
    *,
    member_view: bool,
    txn_type: str | None,
    category_id: int | None,
    date_from: date | None,
    date_to: date | None,
    min_amount: Decimal | None,
    max_amount: Decimal | None,
    reference: str | None,
    approved_by: int | None,
    search: str | None,
    status_filter: str | None,
    approved_by_name: str | None = None,
) -> list:
    conditions: list = []
    if member_view:
        conditions += [
            FinancialTransaction.status == FINANCE_STATUS_APPROVED,
            FinancialTransaction.is_active == 1,
        ]
    elif status_filter is not None:
        conditions.append(FinancialTransaction.status == status_filter)
    if txn_type is not None:
        conditions.append(FinancialTransaction.type == txn_type)
    if category_id is not None:
        conditions.append(FinancialTransaction.category_id == category_id)
    if date_from is not None:
        conditions.append(FinancialTransaction.txn_date >= date_from)
    if date_to is not None:
        conditions.append(FinancialTransaction.txn_date <= date_to)
    if min_amount is not None:
        conditions.append(FinancialTransaction.amount >= min_amount)
    if max_amount is not None:
        conditions.append(FinancialTransaction.amount <= max_amount)
    if reference:
        conditions.append(FinancialTransaction.reference_no.ilike(f"%{reference}%"))
    if approved_by is not None:
        conditions.append(FinancialTransaction.approved_by == approved_by)
    if approved_by_name:
        conditions.append(
            FinancialTransaction.approved_by.in_(
                select(AdminUser.id).where(AdminUser.name.ilike(f"%{approved_by_name}%"))
            )
        )
    if search:
        like = f"%{search}%"
        conditions.append(
            FinancialTransaction.description.ilike(like)
            | FinancialTransaction.reference_no.ilike(like)
        )
    return conditions


async def _ledger_totals(db: AsyncSession, conditions: list) -> FinanceTotalsOut:
    row = await db.execute(
        select(
            func.coalesce(
                func.sum(
                    case((FinancialTransaction.type == FINANCE_TYPE_INCOME, FinancialTransaction.amount), else_=0)
                ),
                0,
            ),
            func.coalesce(
                func.sum(
                    case((FinancialTransaction.type == FINANCE_TYPE_EXPENSE, FinancialTransaction.amount), else_=0)
                ),
                0,
            ),
        ).where(*conditions)
    )
    income, expense = row.one()
    income, expense = Decimal(str(income)), Decimal(str(expense))
    return FinanceTotalsOut(
        income=f"{income:.2f}", expense=f"{expense:.2f}", net=f"{income - expense:.2f}"
    )


# ---------------------------------------------------------------------------
# Member (read-only): summary, ledger, PDF report
# ---------------------------------------------------------------------------


@router.get("/member/finance/summary", response_model=FinanceSummaryOut)
async def member_finance_summary(
    period: str = Query(default=PERIOD_MONTH),
    date_from: date | None = Query(default=None),
    date_to: date | None = Query(default=None),
    db: AsyncSession = Depends(get_db),
    _actor: AccountActor = Depends(get_account_actor),
) -> FinanceSummaryOut:
    if period not in PERIOD_TYPES:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Unknown period.")
    _assert_custom_period(period, date_from, date_to)
    payload = await get_summary(db, period, date_from, date_to)
    return FinanceSummaryOut(**payload)


@router.get("/member/finance/transactions", response_model=FinanceLedgerOut)
async def member_finance_transactions(
    type: str | None = Query(default=None, pattern=rf"^({'|'.join(FINANCE_TYPES)})$"),
    category_id: int | None = Query(default=None),
    date_from: date | None = Query(default=None),
    date_to: date | None = Query(default=None),
    min_amount: Decimal | None = Query(default=None, gt=0),
    max_amount: Decimal | None = Query(default=None, gt=0),
    reference: str | None = Query(default=None, max_length=64),
    approved_by: int | None = Query(default=None),
    approved_by_name: str | None = Query(default=None, max_length=255),
    search: str | None = Query(default=None, max_length=255),
    limit: int = Query(default=25, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
    _actor: AccountActor = Depends(get_account_actor),
) -> FinanceLedgerOut:
    conditions = _ledger_conditions(
        member_view=True,
        txn_type=type,
        category_id=category_id,
        date_from=date_from,
        date_to=date_to,
        min_amount=min_amount,
        max_amount=max_amount,
        reference=reference,
        approved_by=approved_by,
        approved_by_name=approved_by_name,
        search=search,
        status_filter=None,
    )
    total = (
        await db.execute(select(func.count()).select_from(FinancialTransaction).where(*conditions))
    ).scalar_one()
    totals = await _ledger_totals(db, conditions)
    rows = await db.execute(
        select(FinancialTransaction)
        .where(*conditions)
        .order_by(FinancialTransaction.txn_date.desc(), FinancialTransaction.id.desc())
        .limit(limit)
        .offset(offset)
    )
    items = [_txn_out(txn, admin=False) for txn in rows.scalars().unique()]
    return FinanceLedgerOut(items=items, total=total, totals=totals)


@router.get("/member/finance/report.pdf")
async def member_finance_report_pdf(
    period: str = Query(default=PERIOD_MONTH),
    date_from: date | None = Query(default=None),
    date_to: date | None = Query(default=None),
    type: str | None = Query(default=None, pattern=rf"^({'|'.join(FINANCE_TYPES)})$"),
    category_id: int | None = Query(default=None),
    reference: str | None = Query(default=None, max_length=64),
    approved_by: int | None = Query(default=None),
    approved_by_name: str | None = Query(default=None, max_length=255),
    search: str | None = Query(default=None, max_length=255),
    db: AsyncSession = Depends(get_db),
    _actor: AccountActor = Depends(get_account_actor),
) -> Response:
    if period not in PERIOD_TYPES:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Unknown period.")
    _assert_custom_period(period, date_from, date_to)

    resolved = resolve_period(period, date_from, date_to)
    conditions = _ledger_conditions(
        member_view=True,
        txn_type=type,
        category_id=category_id,
        date_from=resolved.start,
        date_to=resolved.end,
        min_amount=None,
        max_amount=None,
        reference=reference,
        approved_by=approved_by,
        approved_by_name=approved_by_name,
        search=search,
        status_filter=None,
    )
    rows = await db.execute(
        select(FinancialTransaction)
        .where(*conditions)
        .order_by(FinancialTransaction.txn_date.desc(), FinancialTransaction.id.desc())
        .limit(_PDF_MAX_ROWS)
    )
    txns = list(rows.scalars().unique())

    income = sum((t.amount for t in txns if t.type == FINANCE_TYPE_INCOME), Decimal("0"))
    expense = sum((t.amount for t in txns if t.type == FINANCE_TYPE_EXPENSE), Decimal("0"))

    def _breakdown(txn_type: str) -> list[tuple[str, Decimal, str]]:
        per_category: dict[str, Decimal] = {}
        for txn in txns:
            if txn.type == txn_type:
                label = txn.category.label if txn.category is not None else "অন্যান্য"
                per_category[label] = per_category.get(label, Decimal("0")) + txn.amount
        total = sum(per_category.values(), Decimal("0"))
        ordered = sorted(per_category.items(), key=lambda kv: kv[1], reverse=True)
        return [
            (label, amount, f"{(amount / total * 100).quantize(_TWO_PLACES):.2f}" if total > 0 else "0.00")
            for label, amount in ordered
        ]

    filter_bits = []
    if type == FINANCE_TYPE_INCOME:
        filter_bits.append("শুধু আয়")
    elif type == FINANCE_TYPE_EXPENSE:
        filter_bits.append("শুধু ব্যয়")
    if category_id is not None:
        item = (
            await db.execute(select(ConfigListItem).where(ConfigListItem.id == category_id))
        ).scalar_one_or_none()
        if item is not None:
            filter_bits.append(f"খাত: {item.label}")
    if reference:
        filter_bits.append(f"রেফারেন্স: {reference}")
    if search:
        filter_bits.append(f"অনুসন্ধান: {search}")

    now = datetime.now(_DHAKA)
    data = FinanceReportData(
        org_name=settings.organization_name,
        period_label=period_label(period, resolved.start, resolved.end),
        generated_at_label=f"{now.day} {BN_MONTHS[now.month - 1]} {now.year}, {now:%H:%M}",
        income_total=income,
        expense_total=expense,
        balance=await balance_all_time(db),
        income_breakdown=_breakdown(FINANCE_TYPE_INCOME),
        expense_breakdown=_breakdown(FINANCE_TYPE_EXPENSE),
        transactions=[
            (
                t.txn_date,
                t.description,
                t.category.label if t.category is not None else "—",
                "আয়" if t.type == FINANCE_TYPE_INCOME else "ব্যয়",
                t.amount if t.type == FINANCE_TYPE_INCOME else -t.amount,
            )
            for t in txns
        ],
        filter_note="; ".join(filter_bits) or None,
    )
    pdf_bytes = build_finance_report_pdf(data)
    filename = f"fund-transparency-{period}-{date.today():%Y%m%d}.pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


# ---------------------------------------------------------------------------
# Admin: transactions CRUD + workflow
# ---------------------------------------------------------------------------


@router.get("/admin/finance/transactions", response_model=FinanceAdminLedgerOut)
async def admin_finance_transactions(
    status_filter: str | None = Query(default=None, alias="status"),
    type: str | None = Query(default=None, pattern=rf"^({'|'.join(FINANCE_TYPES)})$"),
    category_id: int | None = Query(default=None),
    date_from: date | None = Query(default=None),
    date_to: date | None = Query(default=None),
    search: str | None = Query(default=None, max_length=255),
    include_inactive: bool = Query(default=False),
    limit: int = Query(default=25, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    db: AsyncSession = Depends(get_db),
    _admin=Depends(require_permission("manage_finance")),
) -> FinanceAdminLedgerOut:
    conditions = _ledger_conditions(
        member_view=False,
        txn_type=type,
        category_id=category_id,
        date_from=date_from,
        date_to=date_to,
        min_amount=None,
        max_amount=None,
        reference=None,
        approved_by=None,
        search=search,
        status_filter=status_filter,
    )
    if not include_inactive:
        conditions.append(FinancialTransaction.is_active == 1)
    total = (
        await db.execute(select(func.count()).select_from(FinancialTransaction).where(*conditions))
    ).scalar_one()
    totals = await _ledger_totals(db, conditions)
    rows = await db.execute(
        select(FinancialTransaction)
        .where(*conditions)
        .order_by(FinancialTransaction.txn_date.desc(), FinancialTransaction.id.desc())
        .limit(limit)
        .offset(offset)
    )
    items = [_txn_out(txn, admin=True) for txn in rows.scalars().unique()]
    return FinanceAdminLedgerOut(items=items, total=total, totals=totals)


async def _assign_reference(db: AsyncSession, txn_date: date, reference_no: str | None) -> str | None:
    """Blank reference -> next FT-<year>-<seq>; explicit values are checked
    for uniqueness so the ledger's reference numbers stay trustworthy."""
    if reference_no:
        clash = (
            await db.execute(
                select(FinancialTransaction.id).where(FinancialTransaction.reference_no == reference_no)
            )
        ).scalar_one_or_none()
        if clash is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Reference number '{reference_no}' is already in use.",
            )
        return reference_no
    return await next_reference_no(db, txn_date)


@router.post(
    "/admin/finance/transactions",
    response_model=FinanceTransactionAdminOut,
    status_code=status.HTTP_201_CREATED,
)
async def create_finance_transaction(
    payload: FinanceTransactionCreate,
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_permission("manage_finance")),
) -> FinanceTransactionAdminOut:
    await _require_category_of_type(db, payload.category_id, payload.type)
    await _assert_payment_link(db, payload.linked_payment_type, payload.linked_payment_id)
    txn = FinancialTransaction(
        txn_date=payload.txn_date,
        type=payload.type,
        category_id=payload.category_id,
        amount=payload.amount,
        description=payload.description,
        reference_no=await _assign_reference(db, payload.txn_date, payload.reference_no),
        internal_notes=payload.internal_notes,
        linked_payment_type=payload.linked_payment_type,
        linked_payment_id=payload.linked_payment_id,
        status=payload.status,
        created_by=admin.id,
    )
    db.add(txn)
    await db.flush()
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="finance_transaction.create",
        entity_type="financial_transaction",
        entity_id=str(txn.id),
        detail=f"{txn.type} ৳{txn.amount} ({txn.status}) ref={txn.reference_no}",
    )
    await db.commit()
    await db.refresh(txn)
    invalidate_summary_cache()
    return _txn_out(txn, admin=True)


def _as_utc(value: datetime) -> datetime:
    """SQLite returns timezone-naive datetimes even for tz-aware columns."""
    return value if value.tzinfo is not None else value.replace(tzinfo=timezone.utc)


def _assert_editable(txn: FinancialTransaction) -> None:
    if txn.status != FINANCE_STATUS_APPROVED:
        return
    if txn.approved_at is None:
        return
    age_days = (datetime.now(timezone.utc) - _as_utc(txn.approved_at)).days
    if age_days > APPROVED_EDIT_WINDOW_DAYS:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Approved transactions can only be edited for "
            f"{APPROVED_EDIT_WINDOW_DAYS} days (approved "
            f"{age_days} days ago). Create a correction entry (reversal) instead.",
        )


@router.patch("/admin/finance/transactions/{txn_id}", response_model=FinanceTransactionAdminOut)
async def update_finance_transaction(
    txn_id: int,
    payload: FinanceTransactionUpdate,
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_permission("manage_finance")),
) -> FinanceTransactionAdminOut:
    txn = await _load_txn(db, txn_id)
    _assert_editable(txn)
    changes = payload.model_dump(exclude_unset=True)
    if not changes:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No fields to update")
    if "type" in changes and changes["type"] != txn.type:
        if txn.linked_payment_type is not None and "linked_payment_type" not in changes:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Clear the linked payment before switching this transaction to the other type.",
            )
        if "category_id" not in changes:
            # The existing category belongs to the old type's list.
            await _require_category_of_type(db, txn.category_id, changes["type"])
    new_type = changes.get("type", txn.type)
    if "category_id" in changes and changes["category_id"] != txn.category_id:
        await _require_category_of_type(db, changes["category_id"], new_type)
    if "linked_payment_type" in changes or "linked_payment_id" in changes:
        linked_type = changes.get("linked_payment_type", txn.linked_payment_type)
        linked_id = changes.get("linked_payment_id", txn.linked_payment_id)
        await _assert_payment_link(db, linked_type, linked_id, exclude_txn_id=txn.id)
    if "reference_no" in changes and changes["reference_no"] != txn.reference_no:
        if changes["reference_no"]:
            await _assign_reference(db, txn.txn_date, changes["reference_no"])
        else:
            changes["reference_no"] = await next_reference_no(db, txn.txn_date)

    before = {field: getattr(txn, field) for field in changes}
    for field, value in changes.items():
        setattr(txn, field, value)
    diff = "; ".join(
        f"{field}: {before[field]} → {getattr(txn, field)}" for field in sorted(changes)
    )
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="finance_transaction.update",
        entity_type="financial_transaction",
        entity_id=str(txn.id),
        detail=diff,
    )
    await db.commit()
    await db.refresh(txn)
    invalidate_summary_cache()
    return _txn_out(txn, admin=True)


@router.put("/admin/finance/transactions/{txn_id}/attachment", response_model=FinanceTransactionAdminOut)
async def upload_finance_attachment(
    txn_id: int,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_permission("manage_finance")),
) -> FinanceTransactionAdminOut:
    txn = await _load_txn(db, txn_id)
    path = await save_upload_file(file, f"finance_receipts/txn_{txn.id}")
    txn.attachment_url = path
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="finance_transaction.attachment",
        entity_type="financial_transaction",
        entity_id=str(txn.id),
        detail=path,
    )
    await db.commit()
    await db.refresh(txn)
    return _txn_out(txn, admin=True)


async def _maybe_publish_threshold_notice(
    db: AsyncSession, admin: AdminUser, txn: FinancialTransaction
) -> None:
    threshold = Decimal(str(settings.finance_notice_threshold))
    if txn.amount < threshold or settings.finance_notice_threshold <= 0:
        return
    type_label = "আয়" if txn.type == FINANCE_TYPE_INCOME else "ব্যয়"
    category = txn.category.label if txn.category is not None else "অন্যান্য"
    notice = Notice(
        title="উল্লেখযোগ্য আর্থিক লেনদেন অনুমোদিত",
        body=(
            f"সোসাইটি ফান্ডে একটি উল্লেখযোগ্য {type_label} অনুমোদিত হয়েছে: "
            f"{category} খাতে {format_taka(txn.amount)} টাকা "
            f"(রেফারেন্স: {txn.reference_no or '—'}). "
            "বিস্তারিত জানতে লগইন করে 'ফান্ড স্বচ্ছতা' পেজটি দেখুন।"
        ),
        is_published=True,
        is_members_only=False,
        publish_at=datetime.now(timezone.utc),
        created_by=admin.id,
    )
    db.add(notice)
    await db.flush()
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="finance_transaction.notice_published",
        entity_type="notice",
        entity_id=str(notice.id),
        detail=f"auto notice for txn #{txn.id} (৳{txn.amount} ≥ ৳{threshold})",
    )


@router.post("/admin/finance/transactions/{txn_id}/submit", response_model=FinanceTransactionAdminOut)
async def submit_finance_transaction(
    txn_id: int,
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_permission("manage_finance")),
) -> FinanceTransactionAdminOut:
    txn = await _load_txn(db, txn_id)
    if txn.status != FINANCE_STATUS_DRAFT:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Only draft transactions can be submitted (current: {txn.status}).",
        )
    txn.status = FINANCE_STATUS_PENDING
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="finance_transaction.submit",
        entity_type="financial_transaction",
        entity_id=str(txn.id),
        detail="draft -> pending approval",
    )
    await db.commit()
    await db.refresh(txn)
    return _txn_out(txn, admin=True)


@router.post("/admin/finance/transactions/{txn_id}/approve", response_model=FinanceTransactionAdminOut)
async def approve_finance_transaction(
    txn_id: int,
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_permission("manage_finance")),
) -> FinanceTransactionAdminOut:
    txn = await _load_txn(db, txn_id)
    if txn.status not in (FINANCE_STATUS_DRAFT, FINANCE_STATUS_PENDING):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot approve a transaction in status '{txn.status}'.",
        )
    # Two-person control: the person who recorded the entry cannot also
    # approve it (super_admin can, so a single-admin setup never deadlocks).
    if txn.created_by == admin.id and not is_super_admin(admin):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Two-person control: you cannot approve a transaction you created. "
            "Another committee member must approve it.",
        )
    txn.status = FINANCE_STATUS_APPROVED
    txn.approved_by = admin.id
    txn.approved_at = datetime.now(timezone.utc)
    txn.rejection_reason = None
    await _maybe_publish_threshold_notice(db, admin, txn)
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="finance_transaction.approve",
        entity_type="financial_transaction",
        entity_id=str(txn.id),
        detail=f"approved ৳{txn.amount}",
    )
    await db.commit()
    await db.refresh(txn)
    invalidate_summary_cache()
    return _txn_out(txn, admin=True)


@router.post("/admin/finance/transactions/{txn_id}/reject", response_model=FinanceTransactionAdminOut)
async def reject_finance_transaction(
    txn_id: int,
    payload: FinanceRejectIn,
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_permission("manage_finance")),
) -> FinanceTransactionAdminOut:
    txn = await _load_txn(db, txn_id)
    if txn.status not in (FINANCE_STATUS_DRAFT, FINANCE_STATUS_PENDING):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot reject a transaction in status '{txn.status}'.",
        )
    txn.status = FINANCE_STATUS_REJECTED
    txn.rejection_reason = payload.reason
    txn.approved_by = None
    txn.approved_at = None
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="finance_transaction.reject",
        entity_type="financial_transaction",
        entity_id=str(txn.id),
        detail=f"rejected: {payload.reason}",
    )
    await db.commit()
    await db.refresh(txn)
    return _txn_out(txn, admin=True)


@router.post(
    "/admin/finance/transactions/{txn_id}/reverse",
    response_model=FinanceTransactionAdminOut,
    status_code=status.HTTP_201_CREATED,
)
async def reverse_finance_transaction(
    txn_id: int,
    payload: FinanceReverseIn,
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_permission("manage_finance")),
) -> FinanceTransactionAdminOut:
    """Correction entry for an approved figure: creates the opposite-sign
    transaction (pending approval) instead of silently rewriting history."""
    txn = await _load_txn(db, txn_id)
    if txn.status != FINANCE_STATUS_APPROVED:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only approved transactions can be reversed.",
        )
    opposite = FINANCE_TYPE_EXPENSE if txn.type == FINANCE_TYPE_INCOME else FINANCE_TYPE_INCOME
    reversal = FinancialTransaction(
        txn_date=date.today(),
        type=opposite,
        category_id=txn.category_id,
        amount=txn.amount,
        description=f"স্বয়ংক্রিয় রিভার্সাল (FT ref {txn.reference_no or txn.id}): {payload.reason}",
        status=FINANCE_STATUS_PENDING,
        reversal_of_id=txn.id,
        created_by=admin.id,
    )
    reversal.reference_no = await next_reference_no(db, reversal.txn_date)
    db.add(reversal)
    await db.flush()
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="finance_transaction.reverse",
        entity_type="financial_transaction",
        entity_id=str(txn.id),
        detail=f"reversal #{reversal.id} created ({opposite} ৳{txn.amount}): {payload.reason}",
    )
    await db.commit()
    await db.refresh(reversal)
    return _txn_out(reversal, admin=True)


@router.delete("/admin/finance/transactions/{txn_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_finance_transaction(
    txn_id: int,
    payload: FinanceRejectIn,
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_permission("manage_finance")),
) -> None:
    """Soft delete only: financial records are never hard-deleted, and a
    reason is required for the audit trail."""
    txn = await _load_txn(db, txn_id)
    txn.is_active = 0
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="finance_transaction.delete",
        entity_type="financial_transaction",
        entity_id=str(txn.id),
        detail=f"soft-deleted ({txn.status}, ৳{txn.amount}): {payload.reason}",
    )
    await db.commit()
    invalidate_summary_cache()


# ---------------------------------------------------------------------------
# Admin: categories, overview widget, payment linking, report notices
# ---------------------------------------------------------------------------


@router.get("/admin/finance/categories", response_model=list[FinanceCategoryOut])
async def admin_finance_categories(
    db: AsyncSession = Depends(get_db),
    _admin=Depends(require_permission("manage_finance")),
) -> list[FinanceCategoryOut]:
    """Read-only view of both config lists; categories are added/edited via
    the existing config-lists endpoints so the committee needs no code
    change to add e.g. 'ঈদ অনুষ্ঠান খরচ'."""
    rows = await db.execute(
        select(ConfigListItem)
        .where(ConfigListItem.category.in_([FINANCE_INCOME_CATEGORY, FINANCE_EXPENSE_CATEGORY]))
        .order_by(ConfigListItem.category, ConfigListItem.sort_order, ConfigListItem.id)
    )
    items = [
        FinanceCategoryOut(
            id=item.id,
            type=FINANCE_TYPE_INCOME if item.category == FINANCE_INCOME_CATEGORY else FINANCE_TYPE_EXPENSE,
            label=item.label,
            is_active=bool(item.is_active),
        )
        for item in rows.scalars()
    ]
    return items


@router.get("/admin/finance/overview", response_model=FinanceOverviewOut)
async def admin_finance_overview(
    db: AsyncSession = Depends(get_db),
    _admin=Depends(require_permission("manage_finance")),
) -> FinanceOverviewOut:
    pending_count = (
        await db.execute(
            select(func.count())
            .select_from(FinancialTransaction)
            .where(
                FinancialTransaction.status == FINANCE_STATUS_PENDING,
                FinancialTransaction.is_active == 1,
            )
        )
    ).scalar_one()
    month_start = date.today().replace(day=1)
    month_income, month_expense = await _sum_between(db, month_start, None)
    recent_rows = await db.execute(
        select(FinancialTransaction)
        .where(FinancialTransaction.is_active == 1)
        .order_by(FinancialTransaction.created_at.desc(), FinancialTransaction.id.desc())
        .limit(5)
    )
    return FinanceOverviewOut(
        pending_count=pending_count,
        month_income=f"{month_income:.2f}",
        month_expense=f"{month_expense:.2f}",
        month_net=f"{month_income - month_expense:.2f}",
        balance=f"{await balance_all_time(db):.2f}",
        recent=[_txn_out(txn, admin=True) for txn in recent_rows.scalars().unique()],
    )


def _unlinked_condition(linked_type: str):
    return select(FinancialTransaction.id).where(
        FinancialTransaction.linked_payment_type == linked_type,
        FinancialTransaction.is_active == 1,
    ).correlate(None)


@router.get("/admin/finance/unlinked-payments", response_model=list[UnlinkedPaymentOut])
async def admin_unlinked_payments(
    source_type: str | None = Query(default=None, pattern=rf"^({'|'.join(FINANCE_SOURCES)})$"),
    search: str | None = Query(default=None, max_length=255),
    limit: int = Query(default=_UNLINKED_DEFAULT_LIMIT, ge=1, le=_UNLINKED_MAX_LIMIT),
    db: AsyncSession = Depends(get_db),
    _admin=Depends(require_permission("manage_finance")),
) -> list[UnlinkedPaymentOut]:
    """Payments already recorded elsewhere (monthly subscription, picnic fee,
    cost-share collection) that no ledger row links against yet - so income
    already in the system is never double-counted."""
    like = f"%{search}%" if search else None
    results: list[UnlinkedPaymentOut] = []

    if source_type in (None, FINANCE_SOURCE_INSTALLMENT):
        linked = _unlinked_condition(FINANCE_SOURCE_INSTALLMENT).scalar_subquery()
        query = (
            select(Installment)
            .options(selectinload(Installment.member))
            .where(
                Installment.status == InstallmentStatus.PAID,
                ~Installment.id.in_(linked),
            )
            .order_by(Installment.paid_at.desc())
            .limit(limit)
        )
        rows = await db.execute(query)
        for inst in rows.scalars().unique():
            member = inst.member
            name = member.full_name if member is not None else None
            if like and (name or "").lower().find(search.lower()) < 0:
                continue
            results.append(
                UnlinkedPaymentOut(
                    source_type=FINANCE_SOURCE_INSTALLMENT,
                    source_id=inst.id,
                    member_name=name,
                    member_display_id=member.member_id if member is not None else None,
                    amount=f"{Decimal(str(inst.amount)):.2f}",
                    paid_on=(inst.paid_at.date() if inst.paid_at else inst.created_at.date()),
                    receipt_no=None,
                    detail=f"মাসিক চাঁদা — {BN_MONTHS[inst.month - 1]} {inst.year}",
                )
            )

    if source_type in (None, FINANCE_SOURCE_PICNIC_PAYMENT):
        linked = _unlinked_condition(FINANCE_SOURCE_PICNIC_PAYMENT).scalar_subquery()
        query = (
            select(PicnicPayment)
            .where(~PicnicPayment.id.in_(linked))
            .order_by(PicnicPayment.payment_date.desc())
            .limit(limit)
        )
        rows = await db.execute(query)
        for payment in rows.scalars().unique():
            name = payment.member.full_name if payment.member is not None else None
            if like and (name or "").lower().find(search.lower()) < 0:
                continue
            heads = payment.additional_count + 1
            results.append(
                UnlinkedPaymentOut(
                    source_type=FINANCE_SOURCE_PICNIC_PAYMENT,
                    source_id=payment.id,
                    member_name=name,
                    member_display_id=payment.member.member_id if payment.member is not None else None,
                    amount=f"{Decimal(str(payment.total)):.2f}",
                    paid_on=payment.payment_date,
                    receipt_no=payment.receipt_no,
                    detail=f"পিকনিক ফি ({heads} জন)",
                )
            )

    if source_type in (None, FINANCE_SOURCE_COST_SHARE):
        linked = _unlinked_condition(FINANCE_SOURCE_COST_SHARE).scalar_subquery()
        query = (
            select(CostSplitShare)
            .where(CostSplitShare.amount_paid > 0, ~CostSplitShare.id.in_(linked))
            .order_by(CostSplitShare.paid_at.desc())
            .limit(limit)
        )
        rows = await db.execute(query)
        for share in rows.scalars().unique():
            name = share.member.full_name if share.member is not None else None
            if like and (name or "").lower().find(search.lower()) < 0:
                continue
            cost = share.split.cost if share.split is not None else None
            title = cost.title if cost is not None else "সোসাইটি খরচ"
            results.append(
                UnlinkedPaymentOut(
                    source_type=FINANCE_SOURCE_COST_SHARE,
                    source_id=share.id,
                    member_name=name,
                    member_display_id=share.member.member_id if share.member is not None else None,
                    amount=f"{Decimal(str(share.amount_paid)):.2f}",
                    paid_on=(share.paid_at.date() if share.paid_at else share.updated_at.date()),
                    receipt_no=share.receipt_no,
                    detail=f"খরচের কিস্তি — {title}",
                )
            )

    results.sort(key=lambda item: item.paid_on, reverse=True)
    return results[:limit]


@router.get("/admin/finance/notice-threshold", response_model=FinanceNoticeThresholdOut)
async def admin_notice_threshold(
    _admin=Depends(require_permission("manage_finance")),
) -> FinanceNoticeThresholdOut:
    return FinanceNoticeThresholdOut(threshold=format_taka(settings.finance_notice_threshold))


@router.post("/admin/finance/publish-report-notice", status_code=status.HTTP_201_CREATED)
async def publish_report_notice(
    payload: FinanceReportNoticeIn,
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_permission("manage_finance")),
) -> dict:
    """Announce a published report through the existing Notices feature
    (e.g. 'বাৎসরিক আর্থিক রিপোর্ট প্রকাশিত হয়েছে')."""
    if payload.period not in PERIOD_TYPES:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Unknown period.")
    _assert_custom_period(payload.period, payload.date_from, payload.date_to)
    summary = await get_summary(db, payload.period, payload.date_from, payload.date_to)
    totals = summary["totals"]
    label = period_label(payload.period, summary["period"]["date_from"], summary["period"]["date_to"])
    notice = Notice(
        title="আর্থিক রিপোর্ট প্রকাশিত হয়েছে",
        body=(
            f"{label} সময়ের আর্থিক রিপোর্ট প্রকাশিত হয়েছে: "
            f"আয় {format_taka(totals['income'])} টাকা, ব্যয় {format_taka(totals['expense'])} টাকা, "
            f"নিট জমা {format_taka(totals['net'])} টাকা। "
            "বিস্তারিত ও ডাউনলোডযোগ্য রিপোর্টের জন্য 'ফান্ড স্বচ্ছতা' পেজটি দেখুন।"
        ),
        is_published=True,
        is_members_only=False,
        publish_at=datetime.now(timezone.utc),
        created_by=admin.id,
    )
    db.add(notice)
    await db.flush()
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="finance_transaction.report_notice",
        entity_type="notice",
        entity_id=str(notice.id),
        detail=f"report notice for period={payload.period}",
    )
    await db.commit()
    return {"id": notice.id, "title": notice.title}
