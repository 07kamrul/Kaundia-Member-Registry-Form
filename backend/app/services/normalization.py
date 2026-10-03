"""Normalization for applicant identity fields (NID, mobile, email).

These are the canonical forms stored on `Member.nid`/`mobile`/`email` and
used for duplicate-submission lookups, so a stored value and a freshly
normalized comparison value are always byte-for-byte comparable.
"""
import re

import phonenumbers

_NON_DIGITS = re.compile(r"\D+")


def normalize_nid(nid: str) -> str:
    """Digits only, matching the `^\\d{10,17}$` format enforced client-side."""
    return _NON_DIGITS.sub("", nid.strip())


# Numbers typed without a leading "+" (e.g. legacy "01712345678") are read as
# Bangladeshi, which is also the country the frontend preselects.
DEFAULT_PHONE_REGION = "BD"


def normalize_mobile(mobile: str) -> str:
    """E.164 form (e.g. "+8801712345678") of any country's valid number.

    Raises ValueError when the number cannot be parsed or is not a valid
    number for its country.
    """
    try:
        parsed = phonenumbers.parse(mobile.strip(), DEFAULT_PHONE_REGION)
    except phonenumbers.NumberParseException as exc:
        raise ValueError("invalid phone number") from exc
    if not phonenumbers.is_valid_number(parsed):
        raise ValueError("invalid phone number")
    return phonenumbers.format_number(parsed, phonenumbers.PhoneNumberFormat.E164)


def mobile_lookup_variants(e164_mobile: str) -> list[str]:
    """Every stored form a number may have, for duplicate lookups.

    Rows written before international support hold digits-only national
    numbers ("01712345678"); they are left as-is, so lookups must match both
    that legacy form and the E.164 form new rows are stored in.
    """
    parsed = phonenumbers.parse(e164_mobile)
    variants = {e164_mobile, _NON_DIGITS.sub("", e164_mobile)}
    if phonenumbers.region_code_for_number(parsed) == DEFAULT_PHONE_REGION:
        variants.add(f"0{parsed.national_number}")
    return sorted(variants)


def normalize_email(email: str) -> str:
    return email.strip().lower()
