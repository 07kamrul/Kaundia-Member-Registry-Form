"""Tests for the external map proxies (BDS mouza + RAJUK DAP plots)."""

import pytest

from app.api.routes import external_maps as em
from app.core.security import create_access_token
from app.models.member import Member, MemberStatus
from app.models.property import Property

pytestmark = pytest.mark.asyncio


def _member_headers(member: Member) -> dict:
    return {"Authorization": f"Bearer {create_access_token(str(member.id), 'member')}"}


async def _approved_member(db_session, name: str) -> Member:
    member = Member(
        status=MemberStatus.APPROVED,
        full_name=name,
        father_or_husband=f"Father{name}",
        mother=f"Mother{name}",
        dob="1970-02-03",
        nationality="Bangladeshi",
        occupation="Farmer",
        nid=f"99776655{name[-2:]}",
        mobile=f"0171122334{name[-2:]}",
        gender="পুরুষ",
        email=f"{name.lower()}@example.com",
        permanent_house="House",
        admission_fee="500",
        subscription="100",
        receipt_no=f"RCPT-{name}",
        payment_method="Cash",
        submission_date="2026-01-01",
        show_in_neighbour_directory=True,
    )
    member.properties = [
        Property(
            property_type=["plot"],
            khatian_no="K-1",
            dag_no_rs="101",
            dag_no_cs="91",
            land_quantity="5",
            ownership="single",
        )
    ]
    db_session.add(member)
    await db_session.commit()
    await db_session.refresh(member, attribute_names=["properties"])
    return member


def _clear_cache() -> None:
    em._cache.clear()


class _StubResponse:
    def __init__(self, payload, status_code=200, text="{}"):
        self._payload = payload
        self.status_code = status_code
        self.text = text

    def json(self):
        return self._payload


class _StubClient:
    """Stands in for the shared httpx client; routes never hit the network."""

    def __init__(self, get_payloads=None, post_payloads=None):
        self.get_payloads = get_payloads or []
        self.post_payloads = post_payloads or []
        self.get_calls: list[str] = []
        self.post_calls: list[str] = []

    async def get(self, url, **kwargs):
        self.get_calls.append(url)
        payload = self.get_payloads.pop(0) if len(self.get_payloads) > 1 else self.get_payloads[0]
        return _StubResponse(payload)

    async def post(self, url, **kwargs):
        self.post_calls.append(url)
        payload = self.post_payloads.pop(0) if len(self.post_payloads) > 1 else self.post_payloads[0]
        return _StubResponse(payload)


def _stub_client(monkeypatch, stub: _StubClient) -> None:
    async def fake_get_client():
        return stub

    monkeypatch.setattr(em, "_get_client", fake_get_client)


async def test_requires_auth(client):
    assert (await client.get("/api/member/external-maps/bds/mouza")).status_code == 401
    assert (
        await client.get("/api/member/external-maps/rajuk/plots?bbox=90.3,23.7,90.5,23.9")
    ).status_code == 401


async def test_bds_mouza_is_proxied_and_cached(client, db_session, monkeypatch):
    member = await _approved_member(db_session, "BdsUser")
    _clear_cache()
    sheet_fc = {
        "type": "FeatureCollection",
        "features": [{"type": "Feature", "properties": {"Dag_No": "5"}, "geometry": None}],
    }
    stub = _StubClient(
        get_payloads=[[{"shetnum": "001"}, {"shetnum": "002"}]],
        post_payloads=[sheet_fc, sheet_fc],
    )
    _stub_client(monkeypatch, stub)

    first = await client.get("/api/member/external-maps/bds/mouza", headers=_member_headers(member))
    assert first.status_code == 200
    body = first.json()
    assert body["type"] == "FeatureCollection"
    assert len(body["features"]) == 2

    # Second call is served from the in-memory cache (no new upstream posts).
    second = await client.get("/api/member/external-maps/bds/mouza", headers=_member_headers(member))
    assert second.json() == body
    assert len(stub.post_calls) == 2
    _clear_cache()


async def test_rajuk_plots_outside_society_bbox_is_empty(client, db_session):
    member = await _approved_member(db_session, "RajukUser")
    response = await client.get(
        "/api/member/external-maps/rajuk/plots?bbox=88.0,22.0,88.1,22.1",
        headers=_member_headers(member),
    )
    assert response.status_code == 200
    assert response.json() == {"type": "FeatureCollection", "features": []}


async def test_rajuk_plots_converts_esri_to_geojson(client, db_session, monkeypatch):
    member = await _approved_member(db_session, "RajukGeo")
    _clear_cache()
    stub = _StubClient(
        get_payloads=[
            {"API_KEY": "test-key"},
            {
                "features": [
                    {
                        "attributes": {
                            "plot_no": 770,
                            "rs_plot_no": "RS-770",
                            "address_search": "770, Uttar Kaundia -JL 245, Savar Upazila",
                        },
                        "geometry": {"rings": [[[90.33, 23.80], [90.34, 23.80], [90.34, 23.81], [90.33, 23.80]]]},
                    }
                ]
            },
        ]
    )
    _stub_client(monkeypatch, stub)

    response = await client.get(
        "/api/member/external-maps/rajuk/plots?bbox=90.3,23.7,90.5,23.9",
        headers=_member_headers(member),
    )
    assert response.status_code == 200
    body = response.json()
    assert len(body["features"]) == 1
    feature = body["features"][0]
    assert feature["geometry"]["type"] == "Polygon"
    assert feature["properties"]["rs_plot_no"] == "RS-770"
    _clear_cache()
