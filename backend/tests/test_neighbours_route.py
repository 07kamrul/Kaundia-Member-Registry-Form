"""GET /api/member/neighbours: authentication, approved-only visibility,
own-dag scoping, the response field whitelist, the contact opt-out, the
rate limit and the per-lookup audit row."""

import itertools

import pytest
from httpx import AsyncClient
from sqlalchemy import select

from app.api.routes import neighbours as neighbours_route
from app.core import permissions
from app.core.rate_limit import SlidingWindowRateLimiter
from app.core.security import create_access_token
from app.models.audit_log import AuditLog
from app.models.member import Member, MemberStatus
from app.models.property import Property

pytestmark = pytest.mark.asyncio

URL = "/api/member/neighbours"

OWNER_FIELDS = {"owner_name", "mobile", "contact_hidden", "land_quantity", "rs_dag", "cs_dag", "position_label"}
OWN_FIELDS = {"property_id", "rs_dag", "cs_dag", "land_quantity", "dag_number"}

_sequence = itertools.count(1)


@pytest.fixture(autouse=True)
def _fresh_rate_limiter(monkeypatch):
    """The limiter is process-wide; give every test its own generous window."""
    monkeypatch.setattr(
        neighbours_route, "_lookup_limiter", SlidingWindowRateLimiter(max_requests=1000, window_seconds=60)
    )


async def _member(
    db_session,
    name: str,
    *,
    plots: tuple[tuple[str | None, str | None], ...] = (),
    status: MemberStatus = MemberStatus.APPROVED,
    shows_contact: bool = True,
) -> Member:
    n = next(_sequence)
    member = Member(
        status=status,
        full_name=name,
        father_or_husband=f"FatherSecret{n}",
        mother=f"MotherSecret{n}",
        dob="1970-02-03",
        nationality="Bangladeshi",
        occupation="OccupationSecret",
        nid=f"99887766{n:04d}",
        mobile=f"0171100{n:04d}",
        gender="পুরুষ",
        email=f"secret{n}@example.com",
        permanent_house="HouseSecret",
        admission_fee="500",
        subscription="100",
        receipt_no=f"RCPT-SECRET-{n}",
        payment_method="Cash",
        submission_date="2026-01-01",
        show_in_neighbour_directory=shows_contact,
    )
    member.properties = [
        Property(
            property_type=["plot"],
            khatian_no=f"KHATIAN-SECRET-{n}",
            dag_no_rs=rs,
            dag_no_cs=cs,
            land_quantity="5",
            ownership="single",
        )
        for rs, cs in plots
    ]
    db_session.add(member)
    await db_session.commit()
    # Load the relationship eagerly: lazy loads cannot run under AsyncSession.
    await db_session.refresh(member, attribute_names=["properties"])
    return member


def _headers(member: Member) -> dict:
    return {"Authorization": f"Bearer {create_access_token(str(member.id), 'member')}"}


def _names(entries: list[dict]) -> list[str]:
    return [entry["owner_name"] for entry in entries]


# --- access -----------------------------------------------------------------------


async def test_anonymous_request_is_rejected_with_401(client: AsyncClient) -> None:
    response = await client.get(URL)

    assert response.status_code == 401


async def test_admin_token_is_rejected(client: AsyncClient, admin_user) -> None:
    token = create_access_token(str(admin_user.id), admin_user.role.value)

    response = await client.get(URL, headers={"Authorization": f"Bearer {token}"})

    assert response.status_code == 403


async def test_member_without_the_neighbour_permission_is_forbidden(
    client: AsyncClient, db_session, monkeypatch
) -> None:
    caller = await _member(db_session, "Caller", plots=(("100", None),))
    revoked = tuple(k for k in permissions.ROLE_DEFAULT_PERMISSIONS["member"] if k != "neighbour.view")
    monkeypatch.setitem(permissions.ROLE_DEFAULT_PERMISSIONS, "member", revoked)

    response = await client.get(URL, headers=_headers(caller))

    assert response.status_code == 403


@pytest.mark.parametrize("status", [MemberStatus.PENDING, MemberStatus.REJECTED])
async def test_caller_who_is_not_approved_is_forbidden(
    client: AsyncClient, db_session, status: MemberStatus
) -> None:
    caller = await _member(db_session, "Caller", plots=(("100", None),), status=status)

    response = await client.get(URL, headers=_headers(caller))

    assert response.status_code == 403
    assert response.json()["detail"]["code"] == "NEIGHBOUR_DIRECTORY_APPROVED_ONLY"


async def test_login_grants_members_the_neighbour_permission(client: AsyncClient) -> None:
    from app.api.routes.auth import MEMBER_PERMISSIONS

    assert "neighbour.view" in MEMBER_PERMISSIONS


# --- visibility and scoping --------------------------------------------------------


async def test_lists_same_dag_owners_and_nearest_dags_of_approved_members_only(
    client: AsyncClient, db_session
) -> None:
    caller = await _member(db_session, "Caller", plots=(("100", "900"),))
    await _member(db_session, "Same Dag", plots=(("১০০", None),))
    await _member(db_session, "Next Door", plots=(("101", None),))
    await _member(db_session, "Further", plots=(("150", None),))
    await _member(db_session, "Pending", plots=(("99", None),), status=MemberStatus.PENDING)
    await _member(db_session, "Rejected", plots=(("100", None),), status=MemberStatus.REJECTED)

    response = await client.get(URL, headers=_headers(caller))

    assert response.status_code == 200
    body = response.json()
    assert (body["dag_type"], body["plot_limit"]) == ("rs", 5)
    (group,) = body["properties"]
    assert group["own"]["property_id"] == caller.properties[0].id
    assert group["own"]["dag_number"] == 100
    assert _names(group["same_dag_owners"]) == ["Same Dag"]
    assert _names(group["neighbours"]) == ["Next Door", "Further"]
    assert [n["position_label"] for n in group["neighbours"]] == ["adjacent", "near"]


async def test_response_exposes_only_whitelisted_fields(client: AsyncClient, db_session) -> None:
    caller = await _member(db_session, "Caller", plots=(("100", "900"),))
    neighbour = await _member(db_session, "Neighbour", plots=(("100", "901"),))

    response = await client.get(URL, headers=_headers(caller))

    body = response.json()
    assert set(body) == {"dag_type", "plot_limit", "properties"}
    (group,) = body["properties"]
    assert set(group) == {"own", "same_dag_owners", "neighbours"}
    assert set(group["own"]) == OWN_FIELDS
    (entry,) = group["same_dag_owners"]
    assert set(entry) == OWNER_FIELDS
    for secret in (
        neighbour.nid,
        neighbour.email,
        neighbour.father_or_husband,
        neighbour.mother,
        neighbour.receipt_no,
        "HouseSecret",
        "OccupationSecret",
        "1970-02-03",
        "KHATIAN-SECRET",
    ):
        assert secret not in response.text


async def test_lookup_is_derived_from_the_callers_own_plots_and_ignores_injected_params(
    client: AsyncClient, db_session
) -> None:
    caller = await _member(db_session, "Caller", plots=(("10", None),))
    other = await _member(db_session, "Other", plots=(("500", None),))

    response = await client.get(
        URL,
        params={"member_id": other.id, "dag": "500", "property_id": other.properties[0].id},
        headers=_headers(caller),
    )

    assert response.status_code == 200
    groups = response.json()["properties"]
    assert [g["own"]["property_id"] for g in groups] == [caller.properties[0].id]
    assert [g["own"]["dag_number"] for g in groups] == [10]


async def test_member_with_several_plots_gets_a_group_per_plot(client: AsyncClient, db_session) -> None:
    caller = await _member(db_session, "Caller", plots=(("10", None), ("500", None)))
    await _member(db_session, "Near Ten", plots=(("11", None),))
    await _member(db_session, "Near Five Hundred", plots=(("499", None),))

    response = await client.get(URL, headers=_headers(caller))

    groups = response.json()["properties"]
    assert [g["own"]["dag_number"] for g in groups] == [10, 500]
    assert [_names(g["neighbours"])[0] for g in groups] == ["Near Ten", "Near Five Hundred"]


async def test_cs_lookup_compares_cs_dags_and_defaults_when_only_cs_is_known(
    client: AsyncClient, db_session
) -> None:
    caller = await _member(db_session, "Caller", plots=((None, "300"),))
    await _member(db_session, "CS Neighbour", plots=(("1", "301"),))

    default = await client.get(URL, headers=_headers(caller))
    explicit_rs = await client.get(URL, params={"dag_type": "rs"}, headers=_headers(caller))

    assert default.json()["dag_type"] == "cs"
    assert _names(default.json()["properties"][0]["neighbours"]) == ["CS Neighbour"]
    rs_group = explicit_rs.json()["properties"][0]
    assert rs_group["own"]["dag_number"] is None
    assert rs_group["neighbours"] == []


async def test_unknown_dag_type_is_rejected_with_422(client: AsyncClient, db_session) -> None:
    caller = await _member(db_session, "Caller", plots=(("10", None),))

    response = await client.get(URL, params={"dag_type": "sa"}, headers=_headers(caller))

    assert response.status_code == 422


# --- opt-out flag --------------------------------------------------------------------


async def test_opted_out_member_is_listed_name_only(client: AsyncClient, db_session) -> None:
    caller = await _member(db_session, "Caller", plots=(("10", None),))
    neighbour = await _member(db_session, "Private Person", plots=(("11", None),))

    profile = await client.get("/api/member/me", headers=_headers(neighbour))
    opt_out = await client.patch(
        "/api/member/profile", json={"show_in_neighbour_directory": False}, headers=_headers(neighbour)
    )
    response = await client.get(URL, headers=_headers(caller))

    assert profile.json()["show_in_neighbour_directory"] is True
    assert opt_out.status_code == 200
    assert opt_out.json()["show_in_neighbour_directory"] is False
    assert opt_out.json()["status"] == "approved"  # not a core field: no re-review
    (entry,) = response.json()["properties"][0]["neighbours"]
    assert entry["owner_name"] == "Private Person"
    assert (entry["mobile"], entry["contact_hidden"]) == (None, True)
    assert neighbour.mobile not in response.text


async def test_profile_rejects_a_null_opt_out_flag(client: AsyncClient, db_session) -> None:
    member = await _member(db_session, "Member", plots=(("10", None),))

    response = await client.patch(
        "/api/member/profile", json={"show_in_neighbour_directory": None}, headers=_headers(member)
    )

    assert response.status_code == 422


# --- rate limit and audit -------------------------------------------------------------


async def test_lookups_beyond_the_rate_limit_get_429_with_retry_after(
    client: AsyncClient, db_session, monkeypatch
) -> None:
    caller = await _member(db_session, "Caller", plots=(("10", None),))
    monkeypatch.setattr(
        neighbours_route, "_lookup_limiter", SlidingWindowRateLimiter(max_requests=2, window_seconds=60)
    )

    statuses = [(await client.get(URL, headers=_headers(caller))).status_code for _ in range(2)]
    limited = await client.get(URL, headers=_headers(caller))

    assert statuses == [200, 200]
    assert limited.status_code == 429
    assert limited.json()["detail"]["code"] == "NEIGHBOUR_LOOKUP_RATE_LIMITED"
    assert 1 <= int(limited.headers["Retry-After"]) <= 60


async def test_each_lookup_writes_an_audit_row(client: AsyncClient, db_session) -> None:
    caller = await _member(db_session, "Caller", plots=(("100", None),))
    await _member(db_session, "Same", plots=(("100", None),))
    await _member(db_session, "Next", plots=(("101", None),))

    await client.get(URL, headers=_headers(caller))

    rows = (await db_session.execute(select(AuditLog).where(AuditLog.action == "neighbour.lookup"))).scalars().all()
    (row,) = rows
    assert (row.entity_type, row.entity_id, row.actor_admin_id) == ("member", str(caller.id), None)
    assert row.detail == "dag_type=rs dags=[100] returned=2"
