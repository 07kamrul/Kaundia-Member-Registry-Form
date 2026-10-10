"""End-to-end route tests for the plot boundary feature: draw → review →
approve → popup → overlap dispute → versions/evidence, plus the privacy,
ownership and validation rules of the version-level workflow."""

import itertools

import pytest
from httpx import AsyncClient
from sqlalchemy import select

from app.api.routes import plot_map as plot_map_route
from app.core import permissions
from app.core.config import get_settings
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
# Shares an edge with SQUARE (overlap ~0 m²): edge-touching is not a dispute.
EDGE_TOUCH = {
    "type": "Polygon",
    "coordinates": [[[p[0] + 0.01, p[1]] for p in SQUARE["coordinates"][0]]],
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


async def _pending_version(db_session, boundary_id: int) -> PlotBoundaryVersion:
    boundary = await db_session.get(PlotBoundary, boundary_id)
    return await db_session.get(PlotBoundaryVersion, boundary.pending_version_id)


async def _approve(client, admin, db_session, boundary_id: int, note="ok"):
    pending = await _pending_version(db_session, boundary_id)
    return await client.post(
        f"/api/admin/plot-boundary-versions/{pending.id}/approve", json={"note": note}, headers=_admin_headers(admin)
    )


async def _reject(client, admin, db_session, boundary_id: int, note="shape unclear"):
    pending = await _pending_version(db_session, boundary_id)
    return await client.post(
        f"/api/admin/plot-boundary-versions/{pending.id}/reject", json={"note": note}, headers=_admin_headers(admin)
    )


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


# --- validation ----------------------------------------------------------------------


async def test_member_can_draw_and_gets_pending_review(client, db_session):
    member = await _member(db_session, "Drawer")
    response = await _draw(client, member)

    assert response.status_code == 201
    body = response.json()
    assert body["review_status"] == "pending"
    assert body["has_pending"] is True
    assert body["current_version"] == 1
    assert body["computed_area_sqm"] > 0
    assert body["computed_area_shotangsho"] == pytest.approx(body["computed_area_sqm"] / 40.47, rel=0.01)
    assert body["live_review_status"] is None  # nothing live before approval


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


# --- visibility: pending is invisible to everyone but the owner -----------------------


async def test_member_cannot_read_others_pending_polygon_details(client, db_session):
    drawer = await _member(db_session, "Drawer", dag="120")
    viewer = await _member(db_session, "Viewer", dag="121")
    boundary_id = (await _draw(client, drawer)).json()["id"]

    mine = await client.get("/api/member/plot-boundaries/mine", headers=_member_headers(drawer))
    others = await client.get(
        f"/api/member/plot-map/{boundary_id}/owner", headers=_member_headers(viewer)
    )

    assert mine.status_code == 200
    (mine_row,) = mine.json()
    assert mine_row["id"] == boundary_id
    assert mine_row["review_status"] == "pending"
    assert others.status_code == 403
    assert others.json()["detail"]["code"] == "BOUNDARY_NOT_APPROVED"


async def test_map_list_has_no_names_or_phones_and_marks_own(client, db_session):
    drawer = await _member(db_session, "Secret Owner", dag="130")
    viewer = await _member(db_session, "Viewer", dag="131")
    boundary_id = (await _draw(client, drawer)).json()["id"]
    admin = await _make_admin(db_session)
    assert (await _approve(client, admin, db_session, boundary_id)).status_code == 200

    response = await client.get(f"/api/member/plot-map?bbox={BBOX}", headers=_member_headers(viewer))

    assert response.status_code == 200
    body = response.json()
    assert body["disclaimer_bn"] == "এটি সদস্য-চিহ্নিত আনুমানিক সীমানা; সরকারি জরিপ বা দলিলের বিকল্প নয়।"
    (feature,) = body["features"]
    assert set(feature) == {
        "boundary_id", "property_id", "rs_dag", "cs_dag",
        "review_status", "status", "is_mine", "is_disputed", "geometry",
    }
    assert feature["review_status"] == "approved"
    assert feature["is_mine"] is False
    assert "Secret Owner" not in response.text
    assert drawer.mobile not in response.text


async def test_own_pending_boundary_is_in_the_map_list_but_not_others(client, db_session):
    drawer = await _member(db_session, "Drawer", dag="140")
    other = await _member(db_session, "Other", dag="141")
    mine_id = (await _draw(client, drawer)).json()["id"]
    other_id = (await _draw(client, other, geometry=SHIFTED)).json()["id"]

    own_view = await client.get(f"/api/member/plot-map?bbox={BBOX}", headers=_member_headers(drawer))
    other_view = await client.get(f"/api/member/plot-map?bbox={BBOX}", headers=_member_headers(other))
    own_ids = [f["boundary_id"] for f in own_view.json()["features"]]
    other_ids = [f["boundary_id"] for f in other_view.json()["features"]]

    assert mine_id in own_ids
    assert other_id not in own_ids
    assert mine_id not in other_ids
    # The other member sees their own pending shape, marked as theirs.
    (other_feature,) = other_view.json()["features"]
    assert other_feature["boundary_id"] == other_id
    assert other_feature["is_mine"] is True
    assert other_feature["review_status"] == "pending"


async def test_admin_token_cannot_use_member_map_endpoints(client, admin_user):
    response = await client.get(f"/api/member/plot-map?bbox={BBOX}", headers=_admin_headers(admin_user))
    # The optional-auth map endpoint treats a non-member token as anonymous;
    # with the public flag off that is still a 401.
    assert response.status_code == 401


async def test_anonymous_gets_401_everywhere_by_default(client, db_session, monkeypatch):
    monkeypatch.setattr(get_settings(), "boundary_map_public_view", False)
    for path in [f"/api/member/plot-map?bbox={BBOX}", "/api/member/plot-boundaries/mine", "/api/admin/plot-boundaries"]:
        assert (await client.get(path)).status_code == 401


async def test_public_view_flag_gives_anonymous_dag_only_data(client, db_session, monkeypatch):
    monkeypatch.setattr(get_settings(), "boundary_map_public_view", True)
    drawer = await _member(db_session, "Public Owner", dag="135")
    admin = await _make_admin(db_session)
    boundary_id = (await _draw(client, drawer)).json()["id"]
    assert (await _approve(client, admin, db_session, boundary_id)).status_code == 200

    body = (await client.get(f"/api/member/plot-map?bbox={BBOX}")).json()
    (feature,) = body["features"]
    assert feature["rs_dag"] == "135"
    assert "Public Owner" not in body["features"][0]["geometry"].__str__()
    assert drawer.mobile not in str(body)

    # Owner details are never public, even with the flag on.
    assert (
        await client.get(f"/api/member/plot-map/{boundary_id}/owner")
    ).status_code == 401


# --- approval workflow ----------------------------------------------------------------


async def test_full_workflow_draw_approve_popup_dispute(client, db_session):
    first = await _member(db_session, "First", dag="150")
    second = await _member(db_session, "Second", dag="151")
    admin = await _make_admin(db_session)

    b1 = (await _draw(client, first)).json()
    approve = await _approve(client, admin, db_session, b1["id"])
    assert approve.status_code == 200
    assert approve.json()["status"] == "approved"

    # Second member's overlapping shape, once approved, opens a dispute.
    b2 = (await _draw(client, second, geometry=SHIFTED)).json()
    approve2 = await _approve(client, admin, db_session, b2["id"])
    assert approve2.status_code == 200
    assert approve2.json()["status"] == "approved"
    assert approve2.json()["is_disputed"] is True

    disputes = (
        await db_session.execute(select(BoundaryDispute).where(BoundaryDispute.status == "open"))
    ).scalars().all()
    assert len(disputes) == 1
    assert disputes[0].overlap_area_sqm and disputes[0].overlap_area_sqm > 0

    # Popup works now and shows live property data.
    popup = await client.get(f"/api/member/plot-map/{b1['id']}/owner", headers=_member_headers(second))
    assert popup.status_code == 200
    body = popup.json()
    assert body["owner_name"] == "First"
    assert body["mobile"].startswith("017")
    assert body["rs_dag"] == "150"

    # Approving decides the submitted version in place: create → approved.
    versions = await client.get(f"/api/admin/plot-boundaries/{b1['id']}/versions", headers=_admin_headers(admin))
    assert versions.status_code == 200
    (only,) = versions.json()
    assert only["change_type"] == "create"
    assert only["review_status"] == "approved"


async def test_edge_touching_does_not_open_a_dispute(client, db_session):
    first = await _member(db_session, "Edge A", dag="152")
    second = await _member(db_session, "Edge B", dag="153")
    admin = await _make_admin(db_session)

    b1 = (await _draw(client, first)).json()
    assert (await _approve(client, admin, db_session, b1["id"])).status_code == 200
    b2 = (await _draw(client, second, geometry=EDGE_TOUCH)).json()
    assert (await _approve(client, admin, db_session, b2["id"])).status_code == 200

    open_disputes = (
        await db_session.execute(select(BoundaryDispute).where(BoundaryDispute.status == "open"))
    ).scalars().all()
    assert open_disputes == []


async def test_edit_keeps_previous_version_live_until_approved(client, db_session):
    member = await _member(db_session, "Editor", dag="160")
    viewer = await _member(db_session, "Viewer", dag="161")
    admin = await _make_admin(db_session)
    boundary_id = (await _draw(client, member)).json()["id"]
    assert (await _approve(client, admin, db_session, boundary_id)).status_code == 200

    edit = await client.put(
        f"/api/member/plot-boundaries/{boundary_id}",
        json={"geometry": SHIFTED},
        headers=_member_headers(member),
    )
    assert edit.status_code == 200
    body = edit.json()
    assert body["review_status"] == "pending"
    assert body["current_version"] == 2
    assert body["live_review_status"] == "approved"  # old shape stays live

    # Others still see the approved shape; the owner also sees the proposal.
    viewer_view = await client.get(f"/api/member/plot-map?bbox={BBOX}", headers=_member_headers(viewer))
    (viewer_feature,) = viewer_view.json()["features"]
    assert viewer_feature["review_status"] == "approved"
    assert viewer_feature["geometry"] == SQUARE

    owner_view = await client.get(f"/api/member/plot-map?bbox={BBOX}", headers=_member_headers(member))
    owner_statuses = sorted(f["review_status"] for f in owner_view.json()["features"])
    assert owner_statuses == ["approved", "pending"]

    # The previously approved geometry is still in the history.
    versions = await client.get(f"/api/admin/plot-boundaries/{boundary_id}/versions", headers=_admin_headers(admin))
    assert [v["version"] for v in versions.json()] == [1, 2]
    assert [v["review_status"] for v in versions.json()] == ["approved", "pending"]


async def test_rejecting_an_edit_leaves_the_live_version_untouched(client, db_session):
    member = await _member(db_session, "Edit Reject", dag="162")
    viewer = await _member(db_session, "Viewer", dag="163")
    admin = await _make_admin(db_session)
    boundary_id = (await _draw(client, member)).json()["id"]
    assert (await _approve(client, admin, db_session, boundary_id)).status_code == 200

    await client.put(
        f"/api/member/plot-boundaries/{boundary_id}", json={"geometry": SHIFTED}, headers=_member_headers(member)
    )
    rejected = await _reject(client, admin, db_session, boundary_id, note="wrong dag")
    assert rejected.status_code == 200

    mine = (await client.get("/api/member/plot-boundaries/mine", headers=_member_headers(member))).json()
    (row,) = mine
    assert row["review_status"] == "rejected"
    assert row["review_note"] == "wrong dag"
    assert row["live_review_status"] == "approved"
    assert row["live_geometry"] == SQUARE

    viewer_view = await client.get(f"/api/member/plot-map?bbox={BBOX}", headers=_member_headers(viewer))
    (feature,) = viewer_view.json()["features"]
    assert feature["geometry"] == SQUARE  # old shape still live for others


async def test_rejected_new_polygon_never_goes_live(client, db_session):
    member = await _member(db_session, "Rejected New", dag="164")
    viewer = await _member(db_session, "Viewer", dag="165")
    admin = await _make_admin(db_session)
    boundary_id = (await _draw(client, member)).json()["id"]

    rejected = await _reject(client, admin, db_session, boundary_id)
    assert rejected.status_code == 200
    assert rejected.json()["status"] == "rejected"

    mine = (await client.get("/api/member/plot-boundaries/mine", headers=_member_headers(member))).json()
    (row,) = mine
    assert row["review_status"] == "rejected"
    assert row["review_note"] == "shape unclear"
    assert row["live_geometry"] is None

    viewer_view = await client.get(f"/api/member/plot-map?bbox={BBOX}", headers=_member_headers(viewer))
    assert viewer_view.json()["features"] == []
    assert (
        await client.get(f"/api/member/plot-map/{boundary_id}/owner", headers=_member_headers(viewer))
    ).status_code == 403

    # Owner can edit and resubmit: back to pending.
    resubmit = await client.put(
        f"/api/member/plot-boundaries/{boundary_id}", json={"geometry": SQUARE}, headers=_member_headers(member)
    )
    assert resubmit.status_code == 200
    assert resubmit.json()["review_status"] == "pending"


async def test_at_most_one_pending_and_a_second_edit_supersedes_the_first(client, db_session):
    member = await _member(db_session, "Serial Editor", dag="166")
    admin = await _make_admin(db_session)
    boundary_id = (await _draw(client, member)).json()["id"]
    await _approve(client, admin, db_session, boundary_id)

    await client.put(
        f"/api/member/plot-boundaries/{boundary_id}", json={"geometry": SHIFTED}, headers=_member_headers(member)
    )
    other = {
        "type": "Polygon",
        "coordinates": [[[p[0], p[1] + 0.005] for p in SQUARE["coordinates"][0]]],
    }
    second_edit = await client.put(
        f"/api/member/plot-boundaries/{boundary_id}", json={"geometry": other}, headers=_member_headers(member)
    )
    assert second_edit.status_code == 200

    versions = await client.get(f"/api/admin/plot-boundaries/{boundary_id}/versions", headers=_admin_headers(admin))
    statuses = [(v["version"], v["review_status"]) for v in versions.json()]
    assert statuses == [(1, "approved"), (2, "superseded"), (3, "pending")]
    pending = await _pending_version(db_session, boundary_id)
    assert pending.version == 3


async def test_withdraw_works_only_on_pending(client, db_session):
    member = await _member(db_session, "Withdrawer", dag="167")
    admin = await _make_admin(db_session)
    boundary_id = (await _draw(client, member)).json()["id"]

    withdrawn = await client.post(
        f"/api/member/plot-boundaries/{boundary_id}/withdraw", headers=_member_headers(member)
    )
    assert withdrawn.status_code == 200
    assert withdrawn.json()["has_pending"] is False
    assert withdrawn.json()["live_geometry"] is None

    # Nothing pending anymore: a second withdraw conflicts, and so does approval.
    again = await client.post(
        f"/api/member/plot-boundaries/{boundary_id}/withdraw", headers=_member_headers(member)
    )
    assert again.status_code == 409
    pending = await _pending_version(db_session, boundary_id)
    assert pending is None

    # Resubmit and withdraw again: history keeps both rows.
    await client.put(
        f"/api/member/plot-boundaries/{boundary_id}", json={"geometry": SHIFTED}, headers=_member_headers(member)
    )
    second = await client.post(
        f"/api/member/plot-boundaries/{boundary_id}/withdraw", headers=_member_headers(member)
    )
    assert second.status_code == 200

    versions = await client.get(f"/api/admin/plot-boundaries/{boundary_id}/versions", headers=_admin_headers(admin))
    assert [v["review_status"] for v in versions.json()] == ["withdrawn", "withdrawn"]


async def test_members_cannot_delete(client, db_session):
    member = await _member(db_session, "No Delete", dag="168")
    boundary_id = (await _draw(client, member)).json()["id"]

    response = await client.delete(f"/api/member/plot-boundaries/{boundary_id}", headers=_member_headers(member))
    assert response.status_code == 405


async def test_pending_count_for_admins(client, db_session):
    member = await _member(db_session, "Counter", dag="169")
    other = await _member(db_session, "Counter2", dag="1691")
    admin = await _make_admin(db_session)

    assert (await client.get("/api/admin/plot-boundaries/pending/count", headers=_admin_headers(admin))).json() == {"count": 0}
    await _draw(client, member)
    await _draw(client, other, geometry=SHIFTED)
    count = await client.get("/api/admin/plot-boundaries/pending/count", headers=_admin_headers(admin))
    assert count.json() == {"count": 2}

    first = (await client.get("/api/admin/plot-boundaries?status=pending", headers=_admin_headers(admin))).json()
    assert len(first) == 2


# --- admin add / edit / delete ---------------------------------------------------------


async def test_admin_add_goes_live_immediately_and_audits(client, db_session):
    member = await _member(db_session, "On Behalf", dag="170")
    admin = await _make_admin(db_session)

    response = await client.post(
        "/api/admin/plot-boundaries",
        json={"member_id": member.id, "property_id": member.properties[0].id, "geometry": SQUARE},
        headers=_admin_headers(admin),
    )
    assert response.status_code == 201
    body = response.json()
    assert body["status"] == "approved"
    assert body["live_version_id"] is not None
    assert body["pending_version_id"] is None

    # A regular member sees it right away, with the popup.
    viewer = await _member(db_session, "Viewer", dag="171")
    view = await client.get(f"/api/member/plot-map?bbox={BBOX}", headers=_member_headers(viewer))
    (feature,) = view.json()["features"]
    assert feature["review_status"] == "approved"
    popup = await client.get(f"/api/member/plot-map/{body['id']}/owner", headers=_member_headers(viewer))
    assert popup.json()["owner_name"] == "On Behalf"

    versions = await client.get(f"/api/admin/plot-boundaries/{body['id']}/versions", headers=_admin_headers(admin))
    (only,) = versions.json()
    assert only["change_type"] == "admin_create"
    assert only["submitted_by_role"] == "admin"

    audits = (
        await db_session.execute(select(AuditLog).where(AuditLog.action == "boundary.admin_create"))
    ).scalars().all()
    assert len(audits) == 1


async def test_admin_edit_goes_live_immediately(client, db_session):
    member = await _member(db_session, "Admin Edited", dag="172")
    admin = await _make_admin(db_session)
    boundary_id = (await _draw(client, member)).json()["id"]
    await _approve(client, admin, db_session, boundary_id)

    # A pending member edit gets superseded by the admin edit.
    await client.put(
        f"/api/member/plot-boundaries/{boundary_id}", json={"geometry": SHIFTED}, headers=_member_headers(member)
    )
    response = await client.put(
        f"/api/admin/plot-boundaries/{boundary_id}",
        json={"property_id": member.properties[0].id, "geometry": EDGE_TOUCH},
        headers=_admin_headers(admin),
    )
    assert response.status_code == 200
    assert response.json()["status"] == "approved"
    assert response.json()["pending_version_id"] is None

    versions = await client.get(f"/api/admin/plot-boundaries/{boundary_id}/versions", headers=_admin_headers(admin))
    statuses = [(v["version"], v["review_status"], v["change_type"]) for v in versions.json()]
    assert statuses == [
        (1, "superseded", "create"),
        (2, "superseded", "edit"),
        (3, "approved", "admin_edit"),
    ]


async def test_admin_delete_requires_a_reason_and_keeps_history(client, db_session):
    member = await _member(db_session, "Deleted", dag="173")
    admin = await _make_admin(db_session)
    boundary_id = (await _draw(client, member)).json()["id"]
    await _approve(client, admin, db_session, boundary_id)

    no_reason = await client.request(
        "DELETE", f"/api/admin/plot-boundaries/{boundary_id}", json={"reason": ""}, headers=_admin_headers(admin)
    )
    assert no_reason.status_code == 422

    deleted = await client.request(
        "DELETE",
        f"/api/admin/plot-boundaries/{boundary_id}",
        json={"reason": "duplicate of boundary 12"},
        headers=_admin_headers(admin),
    )
    assert deleted.status_code == 200
    assert deleted.json()["is_deleted"] is True
    assert deleted.json()["deleted_reason"] == "duplicate of boundary 12"

    # Invisible on the member map; still viewable flagged for admins.
    viewer = await _member(db_session, "Viewer", dag="174")
    view = await client.get(f"/api/member/plot-map?bbox={BBOX}", headers=_member_headers(viewer))
    assert view.json()["features"] == []
    admin_view = await client.get(
        "/api/admin/plot-boundaries?include_deleted=true", headers=_admin_headers(admin)
    )
    (row,) = admin_view.json()
    assert row["status"] == "deleted"

    versions = await client.get(f"/api/admin/plot-boundaries/{boundary_id}/versions", headers=_admin_headers(admin))
    assert versions.json()  # history kept

    audits = (
        await db_session.execute(select(AuditLog).where(AuditLog.action == "boundary.delete"))
    ).scalars().all()
    assert len(audits) == 1


# --- owner endpoint: rate limit, audit, opt-out ----------------------------------------


async def test_owner_lookup_is_rate_limited(client, db_session, monkeypatch):
    drawer = await _member(db_session, "Popular", dag="190")
    viewer = await _member(db_session, "Viewer", dag="191")
    admin = await _make_admin(db_session)
    boundary_id = (await _draw(client, drawer)).json()["id"]
    await _approve(client, admin, db_session, boundary_id)
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
    await _approve(client, admin, db_session, boundary_id)

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
    await _approve(client, admin, db_session, boundary_id)

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
    await _approve(client, admin, db_session, boundary_id)

    response = await client.get(f"/api/admin/plot-boundaries/{boundary_id}/evidence", headers=_admin_headers(admin))

    assert response.status_code == 200
    bundle = response.json()
    assert bundle["disclaimer_bn"].startswith("এটি সদস্য-চিহ্নিত")
    assert [f["properties"]["version"] for f in bundle["features"]] == [1]
    assert bundle["features"][0]["properties"]["review_status"] == "approved"
    assert bundle["boundary"]["owner_name"] == "Owner"
    assert bundle["boundary"]["live_version_id"] is not None


async def test_member_cannot_use_admin_endpoints(client, db_session):
    member = await _member(db_session, "Member", dag="230")
    boundary_id = (await _draw(client, member)).json()["id"]
    pending = await _pending_version(db_session, boundary_id)

    assert (await client.get("/api/admin/plot-boundaries", headers=_member_headers(member))).status_code == 403
    assert (
        await client.post(
            f"/api/admin/plot-boundary-versions/{pending.id}/approve", json={}, headers=_member_headers(member)
        )
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


async def test_member_cannot_touch_another_members_boundary(client, db_session):
    owner = await _member(db_session, "Owned", dag="260")
    attacker = await _member(db_session, "Attacker", dag="261")
    boundary_id = (await _draw(client, owner)).json()["id"]

    edit = await client.put(
        f"/api/member/plot-boundaries/{boundary_id}", json={"geometry": SQUARE}, headers=_member_headers(attacker)
    )
    withdraw = await client.post(
        f"/api/member/plot-boundaries/{boundary_id}/withdraw", headers=_member_headers(attacker)
    )
    mine = await client.get("/api/member/plot-boundaries/mine", headers=_member_headers(attacker))

    assert edit.status_code == 404
    assert withdraw.status_code == 404
    assert mine.json() == []
