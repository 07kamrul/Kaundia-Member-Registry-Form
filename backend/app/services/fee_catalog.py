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
