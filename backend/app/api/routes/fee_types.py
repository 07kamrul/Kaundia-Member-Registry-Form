"""Admin endpoints for the generic fee-type catalog (Fee Settings screen).

A fee type is an admin-managed definition; its rates remain versioned
``fee_settings`` rows keyed by ``services.fee_catalog.setting_keys_for`` so
every pre-existing version history keeps working unchanged. Fee-type
create/edit and every new version are written to the audit log.
"""

from datetime import date
from decimal import ROUND_CEILING, Decimal

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import AdminUser
from app.core.permissions import require_permission
from app.db.session import get_db
from app.models.fee_payment import FeePayment
from app.models.fee_settings import FeeSetting, FeeType
from app.schemas.fee_type import (
    FeeTypeCalculateIn,
    FeeTypeCreate,
    FeeTypeCurrentVersion,
    FeeTypeOut,
    FeeTypeUpdate,
    FeeTypeVersionCreate,
    FeeTypeVersionOut,
)
from app.services.audit import record_audit
from app.services.fee_calculation import resolve_active_fee_versions
from app.services.fee_catalog import (
    CALC_FIXED,
    CALC_HEAD_ADDITIONAL,
    CALC_TIERED,
    CALC_VARIABLE,
    PAYMENT_TYPE_ALIASES,
    setting_keys_for,
    variable_setting_keys,
)

router = APIRouter(prefix="/admin", tags=["fee-types"])


async def _get_fee_type(db: AsyncSession, key: str) -> FeeType:
    result = await db.execute(select(FeeType).where(FeeType.key == key))
    fee_type = result.scalar_one_or_none()
    if fee_type is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Fee type not found")
    return fee_type


def _version_keys(fee_type: FeeType) -> list[str]:
    return setting_keys_for(
        fee_type.calculation_type,
        fee_type.key,
        fee_type.head_setting_key,
        fee_type.additional_setting_key,
    )


async def _payment_counts(db: AsyncSession, keys: list[str]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for key in keys:
        aliases = (key, *PAYMENT_TYPE_ALIASES.get(key, ()))
        total = await db.execute(
            select(func.count(FeePayment.id)).where(FeePayment.fee_type.in_(aliases))
        )
        counts[key] = int(total.scalar_one())
    return counts


async def _current_version(
    db: AsyncSession, fee_type: FeeType
) -> FeeTypeCurrentVersion | None:
    """The active rate snapshot for a fee type: the newest active row per
    setting key. Variable fees may legitimately have no rows yet (the member
    then enters the amount), so only None means "no version at all"."""
    keys = _version_keys(fee_type)
    if fee_type.calculation_type == CALC_VARIABLE:
        keys = variable_setting_keys(fee_type.key)
    if not keys:
        return None
    result = await db.execute(
        select(FeeSetting)
        .where(FeeSetting.key.in_(keys), FeeSetting.status == 1)
        .order_by(FeeSetting.start_date.desc(), FeeSetting.id.desc())
    )
    rows: dict[str, FeeSetting] = {}
    for row in result.scalars():
        rows.setdefault(row.key, row)
    if not rows:
        return None
    primary_key = keys[0]
    primary = rows.get(primary_key)
    # Canonical key order (head before additional, base->rate->threshold) so
    # clients can rely on positional access, not JSON key order.
    ordered = {k: float(rows[k].value) for k in keys if k in rows}
    ordered.update({k: float(row.value) for k, row in rows.items() if k not in ordered})
    return FeeTypeCurrentVersion(
        values=ordered,
        unit=primary.unit if primary is not None else fee_type.unit,
        start_date=max(row.start_date for row in rows.values()),
    )


@router.get("/fee-types", response_model=list[FeeTypeOut])
async def list_fee_types(
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("manage_fee_settings")),
) -> list[FeeTypeOut]:
    result = await db.execute(
        select(FeeType).order_by(FeeType.fee_category, FeeType.sort_order, FeeType.key)
    )
    fee_types = list(result.scalars().all())
    counts = await _payment_counts(db, [ft.key for ft in fee_types])
    out: list[FeeTypeOut] = []
    for ft in fee_types:
        item = FeeTypeOut.model_validate(ft)
        item.current_version = await _current_version(db, ft)
        item.payment_count = counts.get(ft.key, 0)
        out.append(item)
    return out


@router.post("/fee-types", response_model=FeeTypeOut, status_code=status.HTTP_201_CREATED)
async def create_fee_type(
    payload: FeeTypeCreate,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_fee_settings")),
) -> FeeTypeOut:
    existing = await db.execute(select(FeeType).where(FeeType.key == payload.key))
    if existing.scalar_one_or_none() is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"A fee type with key '{payload.key}' already exists",
        )
    fee_type = FeeType(
        key=payload.key,
        label_bn=payload.label_bn,
        label_en=payload.label_en,
        calculation_type=payload.calculation_type,
        unit=payload.unit or "taka",
        is_recurring=payload.is_recurring,
        is_pay_once=payload.is_pay_once,
        fee_category=payload.fee_category,
        is_active=True,
        sort_order=0,
        created_by=admin.id,
    )
    db.add(fee_type)
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="fee_types.create",
        entity_type="fee_types",
        entity_id=fee_type.key,
        detail=(
            f"role={admin.role.value} label_en={fee_type.label_en}"
            f" calculation_type={fee_type.calculation_type}"
            f" fee_category={fee_type.fee_category}"
        ),
    )
    await db.commit()
    await db.refresh(fee_type)
    return FeeTypeOut.model_validate(fee_type)


@router.put("/fee-types/{key}", response_model=FeeTypeOut)
async def update_fee_type(
    key: str,
    payload: FeeTypeUpdate,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_fee_settings")),
) -> FeeTypeOut:
    fee_type = await _get_fee_type(db, key)
    before = {
        "label_bn": fee_type.label_bn,
        "label_en": fee_type.label_en,
        "unit": fee_type.unit,
        "is_recurring": fee_type.is_recurring,
        "is_pay_once": fee_type.is_pay_once,
        "fee_category": fee_type.fee_category,
        "is_active": fee_type.is_active,
    }
    changes = payload.model_dump(exclude_unset=True, exclude_none=True)
    for field, value in changes.items():
        setattr(fee_type, field, value)
    changed = {
        field: (before[field], getattr(fee_type, field))
        for field in changes
        if before[field] != getattr(fee_type, field)
    }
    if changed:
        record_audit(
            db,
            actor_admin_id=admin.id,
            action="fee_types.update",
            entity_type="fee_types",
            entity_id=fee_type.key,
            detail=(
                f"role={admin.role.value} "
                + " ".join(f"{f}: {old!r}->{new!r}" for f, (old, new) in sorted(changed.items()))
            ),
        )
        await db.commit()
    await db.refresh(fee_type)
    item = FeeTypeOut.model_validate(fee_type)
    item.current_version = await _current_version(db, fee_type)
    item.payment_count = (await _payment_counts(db, [fee_type.key])).get(fee_type.key, 0)
    return item


@router.get("/fee-types/{key}/versions", response_model=list[FeeTypeVersionOut])
async def list_fee_type_versions(
    key: str,
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("manage_fee_settings")),
) -> list[FeeTypeVersionOut]:
    fee_type = await _get_fee_type(db, key)
    keys = _version_keys(fee_type)
    if fee_type.calculation_type == CALC_VARIABLE:
        keys = variable_setting_keys(fee_type.key)
    if not keys:
        return []
    result = await db.execute(
        select(FeeSetting)
        .where(FeeSetting.key.in_(keys))
        .order_by(FeeSetting.start_date.desc(), FeeSetting.id.desc())
    )
    # Rows sharing a start_date were written as one version (the create
    # endpoint writes every key of a fee type with the same start date); the
    # first row seen per key in the desc-ordered result wins.
    versions: list[FeeTypeVersionOut] = []
    current_unordered: dict[str, float] = {}
    group_date: date | None = None
    group_end: date | None = None
    group_status = 1

    def _flush(values: dict[str, float]) -> dict[str, float]:
        # Emit in canonical key order (see _current_version).
        ordered = {k: values[k] for k in keys if k in values}
        ordered.update({k: v for k, v in values.items() if k not in ordered})
        return ordered
    for row in result.scalars():
        if group_date is None or row.start_date != group_date:
            if current_unordered:
                versions.append(
                    FeeTypeVersionOut(
                        start_date=group_date,
                        end_date=group_end,
                        status=group_status,
                        values=_flush(current_unordered),
                    )
                )
            group_date = row.start_date
            group_end = row.end_date
            group_status = row.status
            current = {}
        current_unordered.setdefault(row.key, float(row.value))
    if current_unordered:
        versions.append(
            FeeTypeVersionOut(
                start_date=group_date,
                end_date=group_end,
                status=group_status,
                values=_flush(current_unordered),
            )
        )
    return versions


async def _close_active_versions(db: AsyncSession, keys: list[str], end_on: date) -> None:
    if not keys:
        return
    result = await db.execute(
        select(FeeSetting).where(FeeSetting.key.in_(keys), FeeSetting.status == 1)
    )
    for row in result.scalars():
        row.end_date = end_on
        row.status = 0


async def _create_setting_version(
    db: AsyncSession,
    admin: AdminUser,
    *,
    key: str,
    value: Decimal,
    unit: str | None,
    start_date: date,
    fee_key: str,
    fee_category: str,
) -> None:
    await _close_active_versions(db, [key], date.today())
    db.add(
        FeeSetting(
            key=key,
            value=float(value),
            unit=unit,
            fee_category=fee_category,
            start_date=start_date,
            end_date=None,
            status=1,
            created_by=admin.id,
        )
    )
    record_audit(
        db,
        actor_admin_id=admin.id,
        action="fee_settings.new_version",
        entity_type="fee_types",
        entity_id=fee_key,
        detail=(f"role={admin.role.value} setting={key} value={value} start_date={start_date}"),
    )


@router.post(
    "/fee-types/{key}/versions",
    response_model=list[FeeTypeVersionOut],
    status_code=status.HTTP_201_CREATED,
)
async def create_fee_type_version(
    key: str,
    payload: FeeTypeVersionCreate,
    db: AsyncSession = Depends(get_db),
    admin: AdminUser = Depends(require_permission("manage_fee_settings")),
) -> list[FeeTypeVersionOut]:
    fee_type = await _get_fee_type(db, key)
    start_date = payload.start_date or date.today()
    unit = payload.unit or fee_type.unit

    calc = fee_type.calculation_type
    if calc == CALC_FIXED:
        if payload.value is None:
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, detail="value is required")
        rows = [(fee_type.key, Decimal(str(payload.value)), unit)]
    elif calc == CALC_TIERED:
        if (
            payload.base_amount is None
            or payload.additional_rate is None
            or payload.base_threshold is None
        ):
            raise HTTPException(
                status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="base_amount, additional_rate and base_threshold are required",
            )
        if payload.base_threshold <= 0:
            raise HTTPException(
                status.HTTP_422_UNPROCESSABLE_ENTITY, detail="base_threshold must be positive"
            )
        keys = setting_keys_for(calc, fee_type.key)
        rows = [
            (keys[0], Decimal(str(payload.base_amount)), unit),
            (keys[1], Decimal(str(payload.additional_rate)), unit),
            (keys[2], Decimal(str(payload.base_threshold)), None),
        ]
    elif calc == CALC_HEAD_ADDITIONAL:
        if payload.head_fee is None or payload.additional_head_fee is None:
            raise HTTPException(
                status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="head_fee and additional_head_fee are required",
            )
        head_key, additional_key = setting_keys_for(
            calc, fee_type.key, fee_type.head_setting_key, fee_type.additional_setting_key
        )
        rows = [
            (head_key, Decimal(str(payload.head_fee)), unit),
            (additional_key, Decimal(str(payload.additional_head_fee)), unit),
        ]
    elif calc == CALC_VARIABLE:
        if payload.min_amount is None and payload.max_amount is None:
            raise HTTPException(
                status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Provide at least one of min_amount / max_amount",
            )
        min_key, max_key = variable_setting_keys(fee_type.key)
        rows = []
        if payload.min_amount is not None:
            rows.append((min_key, Decimal(str(payload.min_amount)), unit))
        if payload.max_amount is not None:
            rows.append((max_key, Decimal(str(payload.max_amount)), None))
    else:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY, detail=f"Unsupported calculation type {calc!r}"
        )

    for setting_key, value, setting_unit in rows:
        await _create_setting_version(
            db,
            admin,
            key=setting_key,
            value=value,
            unit=setting_unit,
            start_date=start_date,
            fee_key=fee_type.key,
            fee_category=fee_type.fee_category,
        )
    await db.commit()
    return await list_fee_type_versions(key, db, admin)


@router.post("/fee-types/{key}/calculate")
async def calculate_fee_type(
    key: str,
    payload: FeeTypeCalculateIn,
    db: AsyncSession = Depends(get_db),
    _admin: AdminUser = Depends(require_permission("manage_fee_settings")),
) -> dict:
    """Live calculator preview; reuses the same version resolution and math
    the real payment flows use, so the quoted amount can never diverge."""
    fee_type = await _get_fee_type(db, key)
    on_date = payload.on_date or date.today()
    calc = fee_type.calculation_type

    if calc == CALC_FIXED:
        versions = await resolve_active_fee_versions(db, (fee_type.key,), on_date)
        if versions is None:
            raise HTTPException(
                status.HTTP_409_CONFLICT, detail=f"No active version configured for '{key}'"
            )
        value = Decimal(str(versions[fee_type.key].value))
        return {
            "calculation_type": calc,
            "total": float(value),
            "breakdown": {"amount": float(value)},
        }

    if calc == CALC_TIERED:
        keys = setting_keys_for(calc, fee_type.key)
        if payload.land_size is None or payload.land_size <= 0:
            raise HTTPException(
                status.HTTP_422_UNPROCESSABLE_ENTITY, detail="land_size must be greater than zero"
            )
        versions = await resolve_active_fee_versions(db, tuple(keys), on_date)
        if versions is None:
            raise HTTPException(
                status.HTTP_409_CONFLICT, detail=f"No active version configured for '{key}'"
            )
        base = Decimal(str(versions[keys[0]].value))
        rate = Decimal(str(versions[keys[1]].value))
        threshold = Decimal(str(versions[keys[2]].value))
        land = Decimal(str(payload.land_size))
        if land <= threshold:
            total = base
            extra_units = 0
        else:
            extra_units = int((land - threshold).to_integral_value(rounding=ROUND_CEILING))
            total = base + extra_units * rate
        return {
            "calculation_type": calc,
            "total": float(total),
            "breakdown": {
                "base": float(base),
                "threshold": float(threshold),
                "additional_rate": float(rate),
                "extra_units": extra_units,
            },
        }

    if calc == CALC_HEAD_ADDITIONAL:
        head_key, additional_key = setting_keys_for(
            calc, fee_type.key, fee_type.head_setting_key, fee_type.additional_setting_key
        )
        heads = payload.additional_heads or 0
        if heads < 0:
            raise HTTPException(
                status.HTTP_422_UNPROCESSABLE_ENTITY, detail="additional_heads must not be negative"
            )
        versions = await resolve_active_fee_versions(db, (head_key, additional_key), on_date)
        if versions is None:
            raise HTTPException(
                status.HTTP_409_CONFLICT, detail=f"No active version configured for '{key}'"
            )
        head_price = Decimal(str(versions[head_key].value))
        additional_price = Decimal(str(versions[additional_key].value))
        total = head_price + additional_price * heads
        return {
            "calculation_type": calc,
            "total": float(total),
            "breakdown": {
                "head_price": float(head_price),
                "additional_price": float(additional_price),
                "additional_heads": heads,
            },
        }

    # variable: bounds only - the member enters the amount at payment time.
    min_key, max_key = variable_setting_keys(fee_type.key)
    versions = await resolve_active_fee_versions(db, (min_key, max_key), on_date)
    minimum = (
        float(versions[min_key].value) if versions is not None and min_key in versions else None
    )
    maximum = (
        float(versions[max_key].value) if versions is not None and max_key in versions else None
    )
    if payload.amount is not None and payload.amount <= 0:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY, detail="amount must be greater than zero"
        )
    if payload.amount is not None and minimum is not None and payload.amount < minimum:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY, detail=f"Amount is below the minimum ({minimum})"
        )
    if payload.amount is not None and maximum is not None and payload.amount > maximum:
        raise HTTPException(
            status.HTTP_422_UNPROCESSABLE_ENTITY, detail=f"Amount is above the maximum ({maximum})"
        )
    return {
        "calculation_type": calc,
        "total": payload.amount,
        "breakdown": {"min": minimum, "max": maximum},
    }
