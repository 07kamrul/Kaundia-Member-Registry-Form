"""Period aggregation for the fund transparency dashboard.

Sums run only over approved + active rows; money stays Decimal until the
final string cast in the schemas. Period summaries are cached in-process
(same pattern as the permission cache) and invalidated on every write so
the hero card and charts stay fast as the ledger grows.
"""
import calendar
import time
from dataclasses import dataclass
from datetime import date, timedelta
from decimal import Decimal

from sqlalchemy import case, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.config_list_item import ConfigListItem
from app.models.financial_transaction import (
    FINANCE_STATUS_APPROVED,
    FINANCE_TYPE_EXPENSE,
    FINANCE_TYPE_INCOME,
    FinancialTransaction,
)

PERIOD_MONTH = "month"
PERIOD_YEAR = "year"
PERIOD_CUSTOM = "custom"
PERIOD_ALL = "all"
PERIOD_TYPES = (PERIOD_MONTH, PERIOD_YEAR, PERIOD_CUSTOM, PERIOD_ALL)

_TWO_PLACES = Decimal("0.01")
_ZERO = Decimal("0")

# Bengali month names for report headers/period labels (Gregorian calendar).
BN_MONTHS = (
    "জানুয়ারি", "ফেব্রুয়ারি", "মার্চ", "এপ্রিল", "মে", "জুন",
    "জুলাই", "আগস্ট", "সেপ্টেম্বর", "অক্টোবর", "নভেম্বর", "ডিসেম্বর",
)

_SUMMARY_CACHE_TTL_SECONDS = 60.0
_summary_cache: dict[str, tuple[float, dict]] = {}
_summary_generation = 0


def invalidate_summary_cache() -> None:
    """Drop cached period summaries after any finance write."""
    global _summary_generation
    _summary_generation += 1
    _summary_cache.clear()


def format_taka(value: Decimal | int | float | str) -> str:
    """South-Asian (lakh/crore) digit grouping with 2 decimals: 1250000 ->
    '12,50,000.00'. Matches what members see on the web (en-IN locale)."""
    amount = Decimal(str(value)).quantize(_TWO_PLACES)
    sign = "-" if amount < 0 else ""
    rupees, cents = divmod(abs(amount).quantize(_TWO_PLACES), Decimal("1"))
    digits = str(int(rupees))
    if len(digits) > 3:
        head, tail = digits[:-3], digits[-3:]
        groups = []
        while len(head) > 2:
            groups.insert(0, head[-2:])
            head = head[:-2]
        if head:
            groups.insert(0, head)
        digits = ",".join(groups + [tail])
    return f"{sign}{digits}.{int(cents):02d}"


def _month_label(year: int, month: int) -> str:
    return f"{BN_MONTHS[month - 1]} {year}"


def period_label(period_type: str, date_from: date | None, date_to: date | None) -> str:
    if period_type == PERIOD_ALL:
        return "সর্বমোট (সব সময়)"
    if period_type == PERIOD_YEAR:
        return str(date_from.year) if date_from else ""
    if date_from is None or date_to is None:
        return ""
    if period_type == PERIOD_MONTH:
        return _month_label(date_from.year, date_from.month)
    return f"{date_from:%d/%m/%Y} – {date_to:%d/%m/%Y}"


@dataclass(frozen=True)
class ResolvedPeriod:
    type: str
    start: date | None  # None means "beginning of time"
    end: date | None
    prev_start: date | None
    prev_end: date | None
    granularity: str  # series bucket size: month | year


def resolve_period(
    period_type: str,
    date_from: date | None = None,
    date_to: date | None = None,
    today: date | None = None,
) -> ResolvedPeriod:
    today = today or date.today()

    if period_type == PERIOD_ALL:
        return ResolvedPeriod(PERIOD_ALL, None, None, None, None, "year")

    if period_type == PERIOD_MONTH:
        start = today.replace(day=1)
        end = today
    elif period_type == PERIOD_YEAR:
        start = today.replace(month=1, day=1)
        end = today
    else:  # custom; caller validates presence/order
        start, end = date_from, date_to

    length = (end - start).days + 1
    if period_type == PERIOD_CUSTOM:
        prev_end = start - timedelta(days=1)
        prev_start = prev_end - timedelta(days=length - 1)
    elif period_type == PERIOD_MONTH:
        first_of_prev = (start - timedelta(days=1)).replace(day=1)
        last_of_prev = start - timedelta(days=1)
        prev_start = first_of_prev
        prev_end = min(first_of_prev + timedelta(days=length - 1), last_of_prev)
    else:  # year
        prev_start = start.replace(year=start.year - 1)
        prev_end = min(prev_start + timedelta(days=length - 1), start - timedelta(days=1))

    granularity = "month"
    if period_type == PERIOD_YEAR:
        granularity = "year"
    elif period_type == PERIOD_CUSTOM and ((end.year - start.year) * 12 + end.month - start.month) > 24:
        granularity = "year"

    return ResolvedPeriod(period_type, start, end, prev_start, prev_end, granularity)


def _approved_rows_filter():
    return (FinancialTransaction.status == FINANCE_STATUS_APPROVED, FinancialTransaction.is_active == 1)


async def _sum_between(db: AsyncSession, start: date | None, end: date | None) -> tuple[Decimal, Decimal]:
    """(income, expense) totals for approved rows in [start, end]."""
    conditions = list(_approved_rows_filter())
    if start is not None:
        conditions.append(FinancialTransaction.txn_date >= start)
    if end is not None:
        conditions.append(FinancialTransaction.txn_date <= end)
    row = await db.execute(
        select(
            func.coalesce(
                func.sum(case((FinancialTransaction.type == FINANCE_TYPE_INCOME, FinancialTransaction.amount), else_=0)),
                0,
            ),
            func.coalesce(
                func.sum(case((FinancialTransaction.type == FINANCE_TYPE_EXPENSE, FinancialTransaction.amount), else_=0)),
                0,
            ),
        ).where(*conditions)
    )
    income, expense = row.one()
    return Decimal(str(income)), Decimal(str(expense))


async def balance_all_time(db: AsyncSession) -> Decimal:
    income, expense = await _sum_between(db, None, None)
    return income - expense


async def _category_breakdown(
    db: AsyncSession, start: date | None, end: date | None, txn_type: str
) -> list[dict]:
    conditions = [*(_approved_rows_filter()), FinancialTransaction.type == txn_type]
    if start is not None:
        conditions.append(FinancialTransaction.txn_date >= start)
    if end is not None:
        conditions.append(FinancialTransaction.txn_date <= end)
    rows = await db.execute(
        select(
            FinancialTransaction.category_id,
            func.coalesce(ConfigListItem.label, "অন্যান্য"),
            func.sum(FinancialTransaction.amount),
        )
        .select_from(FinancialTransaction)
        .outerjoin(ConfigListItem, ConfigListItem.id == FinancialTransaction.category_id)
        .where(*conditions)
        .group_by(FinancialTransaction.category_id, ConfigListItem.label)
        .order_by(func.sum(FinancialTransaction.amount).desc())
    )
    grouped = rows.all()
    total = sum((Decimal(str(amount)) for _, _, amount in grouped), _ZERO)
    breakdown = []
    for category_id, label, amount in grouped:
        share = (Decimal(str(amount)) / total * 100).quantize(_TWO_PLACES) if total > 0 else Decimal("0")
        breakdown.append(
            {
                "category_id": category_id,
                "category": label,
                "amount": f"{Decimal(str(amount)):.2f}",
                "share": f"{share:.2f}",
            }
        )
    return breakdown


def _empty_breakdown() -> list[dict]:
    return []


async def _txn_count(db: AsyncSession, start: date | None, end: date | None) -> int:
    conditions = list(_approved_rows_filter())
    if start is not None:
        conditions.append(FinancialTransaction.txn_date >= start)
    if end is not None:
        conditions.append(FinancialTransaction.txn_date <= end)
    row = await db.execute(select(func.count()).select_from(FinancialTransaction).where(*conditions))
    return int(row.scalar_one())


async def _last_updated(db: AsyncSession) -> date | None:
    row = await db.execute(
        select(func.max(FinancialTransaction.updated_at)).where(*(_approved_rows_filter()))
    )
    return row.scalar_one()


async def _series(db: AsyncSession, resolved: ResolvedPeriod) -> list[dict]:
    """Income/expense/net per bucket, aggregated in Python from (date, type,
    amount) rows: dialect-free date truncation, and the ledger is far too
    small to justify a group-by SQL round trip per bucket."""
    today = date.today()
    if resolved.granularity == "year":
        years = 6
        series_start = date(today.year - years + 1, 1, 1)
    else:
        months = 12
        start_year, start_month = today.year, today.month - months + 1
        while start_month <= 0:
            start_month += 12
            start_year -= 1
        series_start = date(start_year, start_month, 1)
        if resolved.type == PERIOD_CUSTOM and resolved.start is not None:
            series_start = min(series_start, resolved.start.replace(day=1))

    rows = await db.execute(
        select(FinancialTransaction.txn_date, FinancialTransaction.type, FinancialTransaction.amount).where(
            *_approved_rows_filter(), FinancialTransaction.txn_date >= series_start
        )
    )
    buckets: dict[str, dict[str, Decimal]] = {}
    for txn_date, txn_type, amount in rows.all():
        if resolved.granularity == "year":
            key = str(txn_date.year)
        else:
            key = f"{txn_date.year:04d}-{txn_date.month:02d}"
        bucket = buckets.setdefault(key, {"income": _ZERO, "expense": _ZERO})
        bucket["income" if txn_type == FINANCE_TYPE_INCOME else "expense"] += Decimal(str(amount))

    points = []
    if resolved.granularity == "year":
        for year in range(series_start.year, today.year + 1):
            bucket = buckets.get(str(year), {"income": _ZERO, "expense": _ZERO})
            net = bucket["income"] - bucket["expense"]
            points.append(
                {"label": str(year), "income": f"{bucket['income']:.2f}",
                 "expense": f"{bucket['expense']:.2f}", "net": f"{net:.2f}"}
            )
    else:
        cursor = series_start
        while cursor <= today:
            key = f"{cursor.year:04d}-{cursor.month:02d}"
            bucket = buckets.get(key, {"income": _ZERO, "expense": _ZERO})
            net = bucket["income"] - bucket["expense"]
            points.append(
                {"label": key, "income": f"{bucket['income']:.2f}",
                 "expense": f"{bucket['expense']:.2f}", "net": f"{net:.2f}"}
            )
            cursor = date(cursor.year + (cursor.month == 12), cursor.month % 12 + 1, 1)
    return points


async def build_summary(
    db: AsyncSession,
    period_type: str,
    date_from: date | None = None,
    date_to: date | None = None,
) -> dict:
    resolved = resolve_period(period_type, date_from, date_to)

    income, expense = await _sum_between(db, resolved.start, resolved.end)
    breakdown_income = await _category_breakdown(db, resolved.start, resolved.end, FINANCE_TYPE_INCOME)
    breakdown_expense = await _category_breakdown(db, resolved.start, resolved.end, FINANCE_TYPE_EXPENSE)

    previous = None
    prev_income_breakdown = _empty_breakdown()
    prev_expense_breakdown = _empty_breakdown()
    if resolved.prev_start is not None and resolved.prev_end is not None:
        prev_income, prev_expense = await _sum_between(db, resolved.prev_start, resolved.prev_end)
        previous = {
            "income": f"{prev_income:.2f}",
            "expense": f"{prev_expense:.2f}",
            "net": f"{prev_income - prev_expense:.2f}",
        }
        prev_income_breakdown = await _category_breakdown(
            db, resolved.prev_start, resolved.prev_end, FINANCE_TYPE_INCOME
        )
        prev_expense_breakdown = await _category_breakdown(
            db, resolved.prev_start, resolved.prev_end, FINANCE_TYPE_EXPENSE
        )

    balance = await balance_all_time(db)
    series = await _series(db, resolved)
    count = await _txn_count(db, resolved.start, resolved.end)
    last_updated = await _last_updated(db)

    return {
        "period": {
            "type": resolved.type,
            "date_from": resolved.start,
            "date_to": resolved.end,
        },
        "totals": {
            "income": f"{income:.2f}",
            "expense": f"{expense:.2f}",
            "net": f"{income - expense:.2f}",
        },
        "balance": f"{balance:.2f}",
        "previous": previous,
        "income_by_category": breakdown_income,
        "expense_by_category": breakdown_expense,
        "previous_income_by_category": prev_income_breakdown,
        "previous_expense_by_category": prev_expense_breakdown,
        "series": series,
        "granularity": resolved.granularity,
        "transaction_count": count,
        "last_updated": last_updated,
    }


async def get_summary(
    db: AsyncSession,
    period_type: str,
    date_from: date | None = None,
    date_to: date | None = None,
) -> dict:
    """Cached build_summary: the hero card and both charts come from one
    payload, so one cache entry serves the whole dashboard."""
    key = f"{period_type}|{date_from}|{date_to}|{_summary_generation}"
    cached = _summary_cache.get(key)
    now = time.monotonic()
    if cached is not None and now - cached[0] < _SUMMARY_CACHE_TTL_SECONDS:
        return cached[1]
    payload = await build_summary(db, period_type, date_from, date_to)
    _summary_cache[key] = (now, payload)
    return payload


async def next_reference_no(db: AsyncSession, txn_date: date) -> str:
    """Next FT-<year>-<seq> reference for the transaction's year."""
    prefix = f"FT-{txn_date.year}-"
    rows = await db.execute(
        select(FinancialTransaction.reference_no).where(FinancialTransaction.reference_no.like(f"{prefix}%"))
    )
    max_seq = 0
    for (reference,) in rows.all():
        suffix = (reference or "")[len(prefix):]
        if suffix.isdigit():
            max_seq = max(max_seq, int(suffix))
    return f"{prefix}{max_seq + 1:04d}"


def days_in_month(year: int, month: int) -> int:
    return calendar.monthrange(year, month)[1]
