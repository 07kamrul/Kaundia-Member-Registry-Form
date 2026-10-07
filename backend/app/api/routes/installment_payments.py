"""Member self-service monthly installment payments and committee verification."""

from datetime import date
from html import escape

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.routes.member import _reject_fee_manager
from app.core.deps import AccountActor, get_account_actor
from app.core.permissions import require_permission
from app.db.session import get_db
from app.models.installment_payment import PAYMENT_STATUSES, PAYMENT_STATUS_PENDING, InstallmentPayment
from app.models.member import Member
from app.schemas.installment_payment import (
    InstallmentPaymentAdminOut,
    InstallmentPaymentOut,
    PayableSummaryOut,
    PaymentRejectIn,
)
from app.services import installment_payment as payments
from app.services.audit import record_audit
from app.services.email import send_email
from app.services.storage import save_upload_file

router = APIRouter(tags=["installment-payments"])

ADMIN_LIST_LIMIT = 200
MEMBER_ONLY_MESSAGE = "Only accounts linked to a member profile can pay installments."


def _require_member(actor: AccountActor) -> Member:
    _reject_fee_manager(actor)
    if actor.member is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=MEMBER_ONLY_MESSAGE)
    return actor.member


def _parse_installment_ids(raw: str) -> list[int]:
    try:
        return [int(part) for part in raw.split(",") if part.strip()]
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT, detail="Invalid installment selection."
        ) from exc


async def _load_payment(db: AsyncSession, payment_id: int) -> InstallmentPayment:
    result = await db.execute(
        select(InstallmentPayment)
        .where(InstallmentPayment.id == payment_id)
        .execution_options(populate_existing=True)
    )
    payment = result.scalars().unique().one_or_none()
    if payment is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Payment not found")
    return payment


def _admin_out(payment: InstallmentPayment) -> InstallmentPaymentAdminOut:
    member = payment.member
    return InstallmentPaymentAdminOut(
        **InstallmentPaymentOut.model_validate(payment).model_dump(),
        member_id=payment.member_id,
        member_name=member.full_name if member is not None else None,
        member_display_id=member.member_id if member is not None else None,
    )


def _months_label(payment: InstallmentPayment) -> str:
    return ", ".join(f"{i.month:02d}/{i.year}" for i in payment.installments)


async def _notify_member(payment: InstallmentPayment) -> None:
    member = payment.member
    if member is None or not member.email:
        return
    months = escape(_months_label(payment))
    if payment.status == payments.PAYMENT_STATUS_APPROVED:
        subject = "চাঁদা পরিশোধ নিশ্চিত হয়েছে / Payment confirmed"
        body = (
            f"<p>প্রিয় {escape(member.full_name)},</p>"
            f"<p>আপনার ৳{payment.amount} পরিশোধ ({months}) যাচাই করে গ্রহণ করা হয়েছে। ধন্যবাদ।</p>"
            f"<p>Your payment of ৳{payment.amount} for {months} has been verified. Thank you.</p>"
        )
    else:
        reason = escape(payment.rejection_reason or "")
        subject = "চাঁদা পরিশোধ যাচাই করা যায়নি / Payment could not be verified"
        body = (
            f"<p>প্রিয় {escape(member.full_name)},</p>"
            f"<p>আপনার ৳{payment.amount} পরিশোধ ({months}) যাচাই করা যায়নি। কারণ: {reason}</p>"
            f"<p>Your payment for {months} could not be verified. Reason: {reason}. "
            "You can submit it again from your profile.</p>"
        )
    await send_email(member.email, subject, body)


# --- Member -----------------------------------------------------------------


@router.get("/member/installment-payments/payable", response_model=PayableSummaryOut)
async def get_payable_summary(
    actor: AccountActor = Depends(get_account_actor),
    db: AsyncSession = Depends(get_db),
) -> PayableSummaryOut:
    member = _require_member(actor)
    return await payments.build_payable_summary(db, member)


@router.post(
    "/member/installment-payments",
    response_model=InstallmentPaymentOut,
    status_code=status.HTTP_201_CREATED,
)
async def submit_installment_payment(
    installment_ids: str = Form(..., max_length=500),
    method: str = Form(..., min_length=1, max_length=64),
    transaction_ref: str = Form(..., min_length=4, max_length=64, pattern=r"^[A-Za-z0-9\-_/ ]+$"),
    paid_on: date = Form(...),
    sender_account: str | None = Form(default=None, max_length=64),
    note: str | None = Form(default=None, max_length=500),
    proof: UploadFile | None = File(default=None),
    actor: AccountActor = Depends(get_account_actor),
    db: AsyncSession = Depends(get_db),
) -> InstallmentPayment:
    member = _require_member(actor)
    payment = await payments.submit_payment(
        db,
        member=member,
        installment_ids=_parse_installment_ids(installment_ids),
        method=method,
        transaction_ref=transaction_ref,
        paid_on=paid_on,
        sender_account=sender_account,
        note=note,
    )
    # Upload only after every validation passed, so rejected submissions
    # never leave orphaned files behind.
    if proof is not None and proof.filename:
        payment.proof_url = await save_upload_file(proof, f"installment_payments/member_{member.id}")
    await db.commit()
    return await _load_payment(db, payment.id)


@router.get("/member/installment-payments", response_model=list[InstallmentPaymentOut])
async def list_my_installment_payments(
    actor: AccountActor = Depends(get_account_actor),
    db: AsyncSession = Depends(get_db),
) -> list[InstallmentPayment]:
    member = _require_member(actor)
    return await payments.list_member_payments(db, member.id)


# --- Admin ------------------------------------------------------------------


@router.get("/admin/installment-payments", response_model=list[InstallmentPaymentAdminOut])
async def admin_list_installment_payments(
    status_filter: str | None = Query(default=None, alias="status", pattern=rf"^({'|'.join(PAYMENT_STATUSES)})$"),
    db: AsyncSession = Depends(get_db),
    _admin=Depends(require_permission("manage_finance")),
) -> list[InstallmentPaymentAdminOut]:
    query = select(InstallmentPayment)
    if status_filter:
        query = query.where(InstallmentPayment.status == status_filter)
    result = await db.execute(
        query.order_by(InstallmentPayment.created_at.desc(), InstallmentPayment.id.desc()).limit(ADMIN_LIST_LIMIT)
    )
    return [_admin_out(p) for p in result.scalars().unique()]


@router.get("/admin/installment-payments/pending-count")
async def admin_pending_payment_count(
    db: AsyncSession = Depends(get_db),
    _admin=Depends(require_permission("manage_finance")),
) -> dict[str, int]:
    result = await db.execute(
        select(func.count(InstallmentPayment.id)).where(InstallmentPayment.status == PAYMENT_STATUS_PENDING)
    )
    return {"count": int(result.scalar_one())}


@router.post("/admin/installment-payments/{payment_id}/approve", response_model=InstallmentPaymentAdminOut)
async def admin_approve_installment_payment(
    payment_id: int,
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_permission("manage_finance")),
) -> InstallmentPaymentAdminOut:
    payment = await _load_payment(db, payment_id)
    payments.approve_payment(payment, admin.id)
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="installment_payment.approve",
        entity_type="installment_payment",
        entity_id=str(payment.id),
        detail=f"{payment.method} {payment.transaction_ref} ৳{payment.amount} ({_months_label(payment)})",
    )
    await db.commit()
    payment = await _load_payment(db, payment_id)
    await _notify_member(payment)
    return _admin_out(payment)


@router.post("/admin/installment-payments/{payment_id}/reject", response_model=InstallmentPaymentAdminOut)
async def admin_reject_installment_payment(
    payment_id: int,
    payload: PaymentRejectIn,
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_permission("manage_finance")),
) -> InstallmentPaymentAdminOut:
    payment = await _load_payment(db, payment_id)
    payments.reject_payment(payment, admin.id, payload.reason)
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="installment_payment.reject",
        entity_type="installment_payment",
        entity_id=str(payment.id),
        detail=payload.reason,
    )
    await db.commit()
    payment = await _load_payment(db, payment_id)
    await _notify_member(payment)
    return _admin_out(payment)
