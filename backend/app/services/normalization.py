"""Normalization for applicant identity fields (NID, mobile, email).

These are the canonical forms stored on `Member.nid`/`mobile`/`email` and
used for duplicate-submission lookups, so a stored value and a freshly
normalized comparison value are always byte-for-byte comparable.
"""
import re

_NON_DIGITS = re.compile(r"\D+")


def normalize_nid(nid: str) -> str:
    """Digits only, matching the `^\\d{10,17}$` format enforced client-side."""
    return _NON_DIGITS.sub("", nid.strip())


def normalize_mobile(mobile: str) -> str:
    """Digits only, matching the `^01[3-9]\\d{8}$` format enforced client-side."""
    return _NON_DIGITS.sub("", mobile.strip())


def normalize_email(email: str) -> str:
    return email.strip().lower()
