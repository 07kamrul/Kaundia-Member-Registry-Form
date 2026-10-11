"""Catalog of general fee types members can pay from the unified Fees page.

Each type may carry a suggested amount in Fee Settings under the key
``fee_<key>_amount`` (versioned like every other fee setting). When no
version is configured the member simply enters the amount themselves, which
is the normal case for one-off "extra" fees.
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class FeeType:
    key: str
    setting_key: str | None  # FeeSetting key holding the suggested amount


FEE_TYPES: tuple[FeeType, ...] = (
    FeeType(key="installment", setting_key="fee_installment_amount"),
    FeeType(key="picnic", setting_key="fee_picnic_amount"),
    FeeType(key="maintenance", setting_key="fee_maintenance_amount"),
    FeeType(key="development", setting_key="fee_development_amount"),
    FeeType(key="donation", setting_key=None),
    FeeType(key="extra", setting_key=None),
)

FEE_TYPE_KEYS = frozenset(fee_type.key for fee_type in FEE_TYPES)


def fee_type_or_none(key: str) -> FeeType | None:
    return next((fee_type for fee_type in FEE_TYPES if fee_type.key == key), None)

# Calculation types supported by the generic FeeType catalog (fee_types table).
CALC_FIXED = "fixed"
CALC_TIERED = "tiered"
CALC_HEAD_ADDITIONAL = "head_additional"
CALC_VARIABLE = "variable"
CALCULATION_TYPES = (CALC_FIXED, CALC_TIERED, CALC_HEAD_ADDITIONAL, CALC_VARIABLE)

# fee_types.fee_category values: installment fees surface on the Installments
# flow, everything else on the Other Fees page.
CATEGORY_INSTALLMENT = "installment"
CATEGORY_OTHER = "other"
FEE_CATEGORIES = (CATEGORY_INSTALLMENT, CATEGORY_OTHER)


def setting_keys_for(
    calculation_type: str,
    key: str,
    head_setting_key: str | None = None,
    additional_setting_key: str | None = None,
) -> list[str]:
    """FeeSetting keys a fee type's versions are stored under. Tiered fees map
    to the three monthly-subscription-style rows; head+additional fees to a
    pair (legacy picnic keys override the derived ones); variable fees keep
    their optional bounds under dedicated keys (see variable_setting_keys)."""
    if calculation_type == CALC_FIXED:
        return [key]
    if calculation_type == CALC_TIERED:
        return [
            f"{key}_base_amount",
            f"{key}_additional_rate",
            f"{key}_base_threshold",
        ]
    if calculation_type == CALC_HEAD_ADDITIONAL:
        return [head_setting_key or key, additional_setting_key or f"{key}_additional_head"]
    return []


def variable_setting_keys(key: str) -> list[str]:
    return [f"{key}_min", f"{key}_max"]


# Historic payment-ledger fee_type strings that predate the fee_types catalog
# but count as "payment history" for the matching definition.
PAYMENT_TYPE_ALIASES: dict[str, tuple[str, ...]] = {
    "picnic_fee": ("picnic",),
    "admission_fee": ("admission",),
}
