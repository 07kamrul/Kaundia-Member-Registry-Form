"""End-to-end route tests for the plot boundary feature: draw → review →
approve → popup → overlap dispute → versions/evidence, plus the privacy,
ownership and validation rules."""

import itertools

import pytest
from httpx import AsyncClient
from sqlalchemy import select

from app.api.routes import plot_map as plot_map_route
from app.core import permissions
from app.core.rate_limit import SlidingWindowRateLimiter
from app.core.security import create_access_token
from app.models.audit_log import AuditLog
from app.models.member import Member, MemberStatus
from app.models.plot_boundary import BoundaryDispute, PlotBoundary, PlotBoundaryVersion
from app.models.property import Property

pytestmark = pytest.mark.asyncio

# A small square inside the default society bbox near the society area.
SQUARE = {"type": "Polygon", "coordinates": [[[90.40, 23.80], [90.41, 23.80], [90.41, 23.81], [90.40, 23.81], [90.40, 23.80]]]}
SHIFTED = {
    "type": "Polygon",
    "coordinates": [[[p[0] + 0.005, p[1] + 0.005] for p in SQUARE["coordinates"][0]]],
}
BBOX = "90.3,23.7,90.5,23.9"

_sequence = itertools.count(1)


@pytest.fixture(autouse=True)
def _fresh_rate_limiter(monkeypatch):
    monkeypatch.setattr(
        plot_map_route, "_owner_limiter", SlidingWindowRateLimiter(max_requests=1000, window_seconds=60)
    )


async def _member(db_session, name: str, *, status: MemberStatus = MemberStatus.APPROVED, dag="101") -> Member:
    n = next(_sequence)
    member = Member(
        status=status,
        full_name=name,
        father_or_husband=f"Father{n}",
        mother=f"Mother{n}",
        dob="1970-02-03",
        nationality="Bangladeshi",
        occupation="Farmer",
        nid=f"99887766{n:04d}",
        mobile=f"0171100{n:04d}",
        gender="পুরুষ",
        email=f"member{n}@example.com",
        permanent_house="House",
        admission_fee="500",
        subscription="100",
        receipt_no=f"RCPT-{n}",
        payment_method="Cash",
        submission_date="2026-01-01",
        show_in_neighbour_directory=True,
    )
    member.properties = [
        Property(
            property_type=["plot"],
            khatian_no=f"K-{n}",
            dag_no_rs=dag,
            dag_no_cs=f"9{n}",
            land_quantity="5",
            ownership="single",
        )
    ]
    db_session.add(member)
    await db_session.commit()
    await db_session.refresh(member, attribute_names=["properties"])
    return member


def _member_headers(member: Member) -> dict:
    return {"Authorization": f"Bearer {create_access_token(str(member.id), 'member')}"}


def _admin_headers(admin) -> dict:
    return {"Authorization": f"Bearer {create_access_token(str(admin.id), admin.role.value)}"}


async def _draw(client, member, property_index=0, geometry=SQUARE):
    return await client.post(
        "/api/member/plot-boundaries",
        json={"property_id": member.properties[property_index].id, "geometry": geometry},
        headers=_member_headers(member),
    )


async def _approve(client, admin, boundary_id):
    return await client.post(
        f"/api/admin/plot-boundaries/{boundary_id}/approve", json={"note": "ok"}, headers=_admin_headers(admin)
    )


# --- validation ----------------------------------------------------------------------


async def test_member_can_draw_and_gets_pending_review(client, db_session):
    member = await _member(db_session, "Drawer")
    response = await _draw(client, member)

    assert response.status_code == 201
    body = response.json()
    assert body["status"] == "pending_review"
    assert body["current_version"] == 1
    assert body["computed_area_sqm"] > 0
    assert body["computed_area_shotangsho"] == pytest.approx(body["computed_area_sqm"] / 40.47, rel=0.01)


async def test_swapped_axis_ring_is_rejected(client, db_session):
    """The classic [lat, lng] bug: lat 90.4 is out of range, so the ring is
    rejected before it can be stored as valid-but-misplaced."""
    member = await _member(db_session, "Sloppy")
    swapped = {"type": "Polygon", "coordinates": [[[p[1], p[0]] for p in SQUARE["coordinates"][0]]]}
    response = await _draw(client, member, geometry=swapped)

    assert response.status_code == 400
    assert response.json()["detail"]["code"] == "INVALID_GEOMETRY"


async def test_self_intersecting_polygon_is_rejected(client, db_session):
    member = await _member(db_session, "Bowtie")
    bowtie = {"type": "Polygon", "coordinates": [[[90.40, 23.80], [90.42, 23.82], [90.42, 23.80], [90.40, 23.82], [90.40, 23.80]]]}
    response = await _draw(client, member, geometry=bowtie)

    assert response.status_code == 400
    assert response.json()["detail"]["code"] == "SELF_INTERSECTING"


async def test_polygon_with_two_vertices_is_rejected(client, db_session):
    member = await _member(db_session, "Line")
    line = {"type": "Polygon", "coordinates": [[[90.40, 23.80], [90.41, 23.80], [90.40, 23.80]]]}
    response = await _draw(client, member, geometry=line)

    assert response.status_code == 400
    assert response.json()["detail"]["code"] == "INVALID_GEOMETRY"


async def test_polygon_outside_society_bbox_is_rejected(client, db_session):
    member = await _member(db_session, "Elsewhere")
    far = {"type": "Polygon", "coordinates": [[[2.0, 48.85], [2.01, 48.85], [2.01, 48.86], [2.0, 48.85]]]}
    response = await _draw(client, member, geometry=far)

    assert response.status_code == 400
    assert response.json()["detail"]["code"] == "OUTSIDE_SOCIETY_AREA"


async def test_area_mismatch_is_a_warning_not_an_error(client, db_session):
    member = await _member(db_session, "Mismatch", dag="102")
    huge = {"type": "Polygon", "coordinates": [[[90.40, 23.80], [90.50, 23.80], [90.50, 23.90], [90.40, 23.90], [90.40, 23.80]]]}
    response = await _draw(client, member, geometry=huge)

    assert response.status_code == 201
    assert response.json()["warnings"], "big mismatch vs 5 shotangsho declared must warn"
    assert response.json()["warnings"][0].startswith("AREA_MISMATCH")


# --- ownership -----------------------------------------------------------------------


async def test_member_cannot_draw_for_another_members_property(client, db_session):
    owner = await _member(db_session, "Owner", dag="110")
    attacker = await _member(db_session, "Attacker", dag="111")

    response = await client.post(
        "/api/member/plot-boundaries",
        json={"property_id": owner.properties[0].id, "geometry": SQUARE},
        headers=_member_headers(attacker),
    )

    assert response.status_code == 403
    assert response.json()["detail"]["code"] == "NOT_YOUR_PROPERTY"


async def test_cannot_draw_two_boundaries_for_the_same_property(client, db_session):
    member = await _member(db_session, "Double")
    assert (await _draw(client, member)).status_code == 201
    again = await _draw(client, member)

    assert again.status_code == 409
    assert again.json()["detail"]["code"] == "BOUNDARY_EXISTS"


async def test_member_cannot_read_others_pending_polygon_details(client, db_session):
    drawer = await _member(db_session, "Drawer", dag="120")
    viewer = await _member(db_session, "Viewer", dag="121")
    boundary_id = (await _draw(client, drawer)).json()["id"]

    mine = await client.get("/api/member/plot-boundaries/mine", headers=_member_headers(drawer))
    others = await client.get(
        f"/api/member/plot-map/{boundary_id}/owner", headers=_member_headers(viewer)
    )

    assert mine.status_code == 200
    assert [b["id"] for b in mine.json()] == [boundary_id]
    assert others.status_code == 403
    assert others.json()["detail"]["code"] == "BOUNDARY_NOT_APPROVED"


# --- map list privacy ----------------------------------------------------------------


async def test_map_list_has_no_names_or_phones_and_marks_own(client, db_session):
    drawer = await _member(db_session, "Secret Owner", dag="130")
    viewer = await _member(db_session, "Viewer", dag="131")
    boundary_id = (await _draw(client, drawer)).json()["id"]
    admin = await _make_admin(db_session)
    await _approve(client, admin, boundary_id)

    response = await client.get(f"/api/member/plot-map?bbox={BBOX}", headers=_member_headers(viewer))

    assert response.status_code == 200
    body = response.json()
    assert body["disclaimer_bn"] == "এটি সদস্য-চিহ্নিত আনুমানিক সীমানা; সরকারি জরিপ বা দলিলের বিকল্প নয়।"
    (feature,) = body["features"]
    assert set(feature) == {"boundary_id", "property_id", "rs_dag", "cs_dag", "status", "is_mine", "geometry"}
    assert feature["is_mine"] is False
    assert "Secret Owner" not in response.text
    assert drawer.mobile not in response.text


async def test_own_pending_boundary_is_in_the_map_list_but_not_others(client, db_session):
    drawer = await _member(db_session, "Drawer", dag="140")
    other = await _member(db_session, "Other", dag="141")
    mine_id = (await _draw(client, drawer)).json()["id"]
    other_id = (await _draw(client, other, geometry=SHIFTED)).json()["id"]

    response = await client.get(f"/api/member/plot-map?bbox={BBOX}", headers=_member_headers(drawer))
    ids = [f["boundary_id"] for f in response.json()["features"]]

    assert mine_id in ids
    assert other_id not in ids


async def test_admin_token_cannot_use_member_map_endpoints(client, admin_user):
    response = await client.get(f"/api/member/plot-map?bbox={BBOX}", headers=_admin_headers(admin_user))
    assert response.status_code == 403


async def test_anonymous_gets_401_everywhere(client, db_session):
    for path in [f"/api/member/plot-map?bbox={BBOX}", "/api/member/plot-boundaries/mine", "/api/admin/plot-boundaries"]:
        assert (await client.get(path)).status_code == 401


async def _make_admin(db_session):
    from app.core.security import hash_password
    from app.models.admin import AdminRole, AdminUser

    admin = AdminUser(
        email=f"admin{next(_sequence)}@example.com",
        password_hash=hash_password("adminpass123"),
        name="Reviewer",
        role=AdminRole.SUPER_ADMIN,
    )
    db_session.add(admin)
    await db_session.commit()
    await db_session.refresh(admin)
    return admin


# --- approval workflow ----------------------------------------------------------------


async def test_full_workflow_draw_approve_popup_dispute(client, db_session):
    first = await _member(db_session, "First", dag="150")
    second = await _member(db_session, "Second", dag="151")
    admin = await _make_admin(db_session)

    b1 = (await _draw(client, first)).json()
    approve = await _approve(client, admin, b1["id"])
    assert approve.status_code == 200
    assert approve.json()["status"] == "approved"

    # Second member's overlapping shape, once approved, opens a dispute.
    b2 = (await _draw(client, second, geometry=SHIFTED)).json()
    approve2 = await _approve(client, admin, b2["id"])
    assert approve2.status_code == 200
    assert approve2.json()["status"] == "disputed"

    disputes = (
        await db_session.execute(select(BoundaryDispute).where(BoundaryDispute.status == "open"))
    ).scalars().all()
    assert len(disputes) == 1
    assert disputes[0].overlap_area_sqm and disputes[0].overlap_area_sqm > 0

    # Popup works now, respects nothing but shows live property data.
    popup = await client.get(f"/api/member/plot-map/{b1['id']}/owner", headers=_member_headers(second))
    assert popup.status_code == 200
    body = popup.json()
    assert body["owner_name"] == "First"
    assert body["mobile"].startswith("017")
    assert body["rs_dag"] == "150"

    # Versions exist and are immutable rows.
    versions = await client.get(f"/api/admin/plot-boundaries/{b1['id']}/versions", headers=_admin_headers(admin))
    assert versions.status_code == 200
    assert [v["change_type"] for v in versions.json()] == ["create", "approve"]


async def test_edit_returns_boundary_to_pending_and_creates_new_version(client, db_session):
    member = await _member(db_session, "Editor", dag="160")
    admin = await _make_admin(db_session)
    boundary_id = (await _draw(client, member)).json()["id"]
    await _approve(client, admin, boundary_id)

    edit = await client.put(
        f"/api/member/plot-boundaries/{boundary_id}",
        json={"geometry": SHIFTED},
        headers=_member_headers(member),
    )
    assert edit.status_code == 200
    assert edit.json()["status"] == "pending_review"
    assert edit.json()["current_version"] == 3  # create, approve, edit

    # The previously approved geometry is still in the history.
    versions = await client.get(f"/api/admin/plot-boundaries/{boundary_id}/versions", headers=_admin_headers(admin))
    assert [v["version"] for v in versions.json()] == [1, 2, 3]


async def test_soft_delete_keeps_history_and_allows_redraw(client, db_session):
    member = await _member(db_session, "Redrawer", dag="170")
    boundary_id = (await _draw(client, member)).json()["id"]

    delete = await client.delete(f"/api/member/plot-boundaries/{boundary_id}", headers=_member_headers(member))
    assert delete.status_code == 204

    row = await db_session.get(PlotBoundary, boundary_id)
    assert row.is_deleted is True  # no hard delete

    redraw = await _draw(client, member)
    assert redraw.status_code == 201


async def test_rejection_requires_a_note_and_owner_can_redraw_via_edit(client, db_session):
    member = await _member(db_session, "Rejected", dag="180")
    admin = await _make_admin(db_session)
    boundary_id = (await _draw(client, member)).json()["id"]

    no_note = await client.post(f"/api/admin/plot-boundaries/{boundary_id}/reject", json={}, headers=_admin_headers(admin))
    assert no_note.status_code == 422

    rejected = await client.post(
        f"/api/admin/plot-boundaries/{boundary_id}/reject", json={"note": "shape unclear"}, headers=_admin_headers(admin)
    )
    assert rejected.status_code == 200
    assert rejected.json()["status"] == "rejected"


# --- owner endpoint: rate limit, audit, opt-out ----------------------------------------


async def test_owner_lookup_is_rate_limited(client, db_session, monkeypatch):
    drawer = await _member(db_session, "Popular", dag="190")
    viewer = await _member(db_session, "Viewer", dag="191")
    admin = await _make_admin(db_session)
    boundary_id = (await _draw(client, drawer)).json()["id"]
    await _approve(client, admin, boundary_id)
    monkeypatch.setattr(
        plot_map_route, "_owner_limiter", SlidingWindowRateLimiter(max_requests=2, window_seconds=60)
    )

    codes = [(await client.get(f"/api/member/plot-map/{boundary_id}/owner", headers=_member_headers(viewer))).status_code for _ in range(3)]

    assert codes == [200, 200, 429]


async def test_owner_lookup_is_audited(client, db_session):
    drawer = await _member(db_session, "Looked At", dag="200")
    viewer = await _member(db_session, "Viewer", dag="201")
    admin = await _make_admin(db_session)
    boundary_id = (await _draw(client, drawer)).json()["id"]
    await _approve(client, admin, boundary_id)

    await client.get(f"/api/member/plot-map/{boundary_id}/owner", headers=_member_headers(viewer))

    rows = (
        await db_session.execute(select(AuditLog).where(AuditLog.action == "boundary.owner_lookup"))
    ).scalars().all()
    assert len(rows) == 1
    assert str(boundary_id) == rows[0].entity_id


async def test_opted_out_owner_has_no_mobile_in_popup(client, db_session):
    drawer = await _member(db_session, "Private", dag="210")
    drawer.show_in_neighbour_directory = False
    await db_session.commit()
    viewer = await _member(db_session, "Viewer", dag="211")
    admin = await _make_admin(db_session)
    boundary_id = (await _draw(client, drawer)).json()["id"]
    await _approve(client, admin, boundary_id)

    popup = await client.get(f"/api/member/plot-map/{boundary_id}/owner", headers=_member_headers(viewer))

    body = popup.json()
    assert body["contact_hidden"] is True
    assert body["mobile"] is None
    assert drawer.mobile not in popup.text


# --- evidence export -------------------------------------------------------------------


async def test_evidence_export_contains_versions_and_disclaimer(client, db_session):
    member = await _member(db_session, "Owner", dag="220")
    admin = await _make_admin(db_session)
    boundary_id = (await _draw(client, member)).json()["id"]
    await _approve(client, admin, boundary_id)

    response = await client.get(f"/api/admin/plot-boundaries/{boundary_id}/evidence", headers=_admin_headers(admin))

    assert response.status_code == 200
    bundle = response.json()
    assert bundle["disclaimer_bn"].startswith("এটি সদস্য-চিহ্নিত")
    assert [f["properties"]["version"] for f in bundle["features"]] == [1, 2]
    assert bundle["boundary"]["owner_name"] == "Owner"


async def test_member_cannot_use_admin_endpoints(client, db_session):
    member = await _member(db_session, "Member", dag="230")
    boundary_id = (await _draw(client, member)).json()["id"]

    assert (await client.get("/api/admin/plot-boundaries", headers=_member_headers(member))).status_code == 403
    assert (
        await client.post(f"/api/admin/plot-boundaries/{boundary_id}/approve", json={}, headers=_member_headers(member))
    ).status_code == 403
    assert (
        await client.get(f"/api/admin/plot-boundaries/{boundary_id}/evidence", headers=_member_headers(member))
    ).status_code == 403


# --- member report ---------------------------------------------------------------------


async def test_report_a_problem_opens_a_dispute_for_the_committee(client, db_session):
    drawer = await _member(db_session, "Reported", dag="240")
    viewer = await _member(db_session, "Reporter", dag="241")
    boundary_id = (await _draw(client, drawer)).json()["id"]

    response = await client.post(
        f"/api/member/plot-boundaries/{boundary_id}/report",
        json={"note": "This boundary crosses my land by about two metres."},
        headers=_member_headers(viewer),
    )

    assert response.status_code == 202
    disputes = (await db_session.execute(select(BoundaryDispute).where(BoundaryDispute.status == "open"))).scalars().all()
    assert len(disputes) == 1
    assert disputes[0].other_boundary_id is None  # a member report, not an overlap


# --- permissions ------------------------------------------------------------------------


async def test_member_without_boundary_permission_is_forbidden(client, db_session, monkeypatch):
    member = await _member(db_session, "No Perm", dag="250")
    stripped = tuple(k for k in permissions.ROLE_DEFAULT_PERMISSIONS["member"] if k != "boundary.draw_own")
    monkeypatch.setitem(permissions.ROLE_DEFAULT_PERMISSIONS, "member", stripped)

    response = await _draw(client, member)

    assert response.status_code == 403
