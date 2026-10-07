"""Member self-service installment payments.

A member reports a payment (bKash / Nagad / bank / ...) against one or more of
their DUE installments; a committee member then verifies the transaction and
approves it (installments become PAID) or rejects it (they stay DUE and can be
paid again). Amounts are always computed here - never trusted from the client.
"""

from datetime import date, datetime, timezone
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.config_list_item import ConfigListItem
from app.models.installment import Installment, InstallmentStatus
from app.models.installment_payment import (
    PAYMENT_STATUS_APPROVED,
    PAYMENT_STATUS_PENDING,
    PAYMENT_STATUS_REJECTED,
    InstallmentPayment,
    installment_payment_items,
)
from app.models.member import Member
from app.schemas.installment import InstallmentOut
from app.schemas.installment_payment import (
    InstallmentPaymentOut,
    PayableSummaryOut,
    PaymentAccountOut,
)

PAYMENT_ACCOUNT_CATEGORY = "payment_account"
MAX_INSTALLMENTS_PER_PAYMENT = 24


async def list_payment_accounts(db: AsyncSession) -> list[PaymentAccountOut]:
    result = await db.execute(
        select(ConfigListItem)
        .where(ConfigListItem.category == PAYMENT_ACCOUNT_CATEGORY, ConfigListItem.is_active == 1)
        .order_by(ConfigListItem.sort_order, ConfigListItem.id)
    )
    return [PaymentAccountOut(method=item.value, details=item.label) for item in result.scalars()]


async def _pending_installment_ids(db: AsyncSession, member_id: int) -> set[int]:
    result = await db.execute(
        select(installment_payment_items.c.installment_id)
        .join(InstallmentPayment, InstallmentPayment.id == installment_payment_items.c.payment_id)
        .where(InstallmentPayment.member_id == member_id, InstallmentPayment.status == PAYMENT_STATUS_PENDING)
    )
    return set(result.scalars())


async def list_member_payments(db: AsyncSession, member_id: int) -> list[InstallmentPayment]:
    result = await db.execute(
        select(InstallmentPayment)
        .where(InstallmentPayment.member_id == member_id)
        .order_by(InstallmentPayment.created_at.desc(), InstallmentPayment.id.desc())
    )
    return list(result.scalars().unique())


async def build_payable_summary(db: AsyncSession, member: Member) -> PayableSummaryOut:
    due_result = await db.execute(
        select(Installment)
        .where(Installment.member_id == member.id, Installment.status == InstallmentStatus.DUE)
        .order_by(Installment.year, Installment.month)
    )
    due = list(due_result.scalars())
    pending_ids = await _pending_installment_ids(db, member.id)
    total_due = sum(
        (Decimal(str(i.amount)) for i in due if i.id not in pending_ids), start=Decimal("0")
    )
    return PayableSummaryOut(
        due=[InstallmentOut.model_validate(i) for i in due],
        pending_installment_ids=sorted(pending_ids),
        total_due=total_due,
        accounts=await list_payment_accounts(db),
        payments=[InstallmentPaymentOut.model_validate(p) for p in await list_member_payments(db, member.id)],
    )


def _bad_request(detail: str) -> HTTPException:
    return HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail=detail)


async def _validate_method(db: AsyncSession, method: str) -> str:
    accounts = await list_payment_accounts(db)
    if not accounts:
        raise _bad_request("Online payment is not set up yet. Please contact the society office.")
    for account in accounts:
        if account.method.casefold() == method.strip().casefold():
            return account.method
    raise _bad_request("Unsupported payment method.")


async def _load_payable_installments(
    db: AsyncSession, member_id: int, installment_ids: list[int]
) -> list[Installment]:
    unique_ids = set(installment_ids)
    if not unique_ids:
        raise _bad_request("Select at least one month to pay.")
    if len(unique_ids) > MAX_INSTALLMENTS_PER_PAYMENT:
        raise _bad_request(f"At most {MAX_INSTALLMENTS_PER_PAYMENT} months can be paid at once.")

    result = await db.execute(
        select(Installment)
        .where(Installment.id.in_(unique_ids), Installment.member_id == member_id)
        .with_for_update()
    )
    installments = list(result.scalars())
    if len(installments) != len(unique_ids):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Installment not found")
    if any(i.status != InstallmentStatus.DUE for i in installments):
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Some selected months are already paid.")
    if unique_ids & await _pending_installment_ids(db, member_id):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Some selected months already have a payment awaiting verification.",
        )
    return sorted(installments, key=lambda i: (i.year, i.month))


async def _ensure_unique_reference(db: AsyncSession, method: str, transaction_ref: str) -> None:
    existing = await db.execute(
        select(InstallmentPayment.id).where(
            InstallmentPayment.method == method,
            InstallmentPayment.transaction_ref == transaction_ref,
        )
    )
    if existing.first() is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This transaction ID has already been submitted.",
        )


async def submit_payment(
    db: AsyncSession,
    *,
    member: Member,
    installment_ids: list[int],
    method: str,
    transaction_ref: str,
    paid_on: date,
    sender_account: str | None = None,
    note: str | None = None,
    proof_url: str | None = None,
) -> InstallmentPayment:
    """Validate and stage a pending payment. Caller commits."""
    if paid_on > date.today():
        raise _bad_request("Payment date cannot be in the future.")
    canonical_method = await _validate_method(db, method)
    reference = transaction_ref.strip().upper()
    installments = await _load_payable_installments(db, member.id, installment_ids)
    await _ensure_unique_reference(db, canonical_method, reference)

    payment = InstallmentPayment(
        member_id=member.id,
        method=canonical_method,
        transaction_ref=reference,
        sender_account=(sender_account or "").strip() or None,
        amount=sum((Decimal(str(i.amount)) for i in installments), start=Decimal("0")),
        paid_on=paid_on,
        note=(note or "").strip() or None,
        proof_url=proof_url,
        status=PAYMENT_STATUS_PENDING,
        installments=installments,
    )
    db.add(payment)
    return payment


def _ensure_pending(payment: InstallmentPayment) -> None:
    if payment.status != PAYMENT_STATUS_PENDING:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="This payment has already been reviewed.")


def approve_payment(payment: InstallmentPayment, admin_id: int) -> None:
    """Mark the payment approved and its installments PAID. Caller commits."""
    _ensure_pending(payment)
    now = datetime.now(timezone.utc)
    paid_at = datetime(payment.paid_on.year, payment.paid_on.month, payment.paid_on.day, tzinfo=timezone.utc)
    for installment in payment.installments:
        installment.status = InstallmentStatus.PAID
        installment.paid_at = paid_at
    payment.status = PAYMENT_STATUS_APPROVED
    payment.reviewed_by = admin_id
    payment.reviewed_at = now


def reject_payment(payment: InstallmentPayment, admin_id: int, reason: str) -> None:
    """Reject the payment; its installments stay DUE. Caller commits."""
    _ensure_pending(payment)
    payment.status = PAYMENT_STATUS_REJECTED
    payment.rejection_reason = reason.strip()
    payment.reviewed_by = admin_id
    payment.reviewed_at = datetime.now(timezone.utc)
