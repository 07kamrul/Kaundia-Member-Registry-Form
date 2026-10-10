"""Dag detail endpoint (official-style khatian dialog) and its privacy guards.

Uses a tiny synthetic dataset (synthetic owner names only) injected through the
provider dependency, so the suite passes offline and independently of the real
ingest. The leak guard at the bottom scans the real shipped files.
"""

import hashlib
import json
import socket
from pathlib import Path

import pytest
from sqlalchemy import select

from app.api.routes import land_data as land_routes
from app.core.rate_limit import SlidingWindowRateLimiter
from app.main import app
from app.models.audit_log import AuditLog
from app.models.member import MemberStatus
from app.services.land_data import (
    LandDataError,
    LocalJsonLandDataProvider,
    get_land_data_provider,
)
from tests.test_land_data import _approved_member, _member_headers

pytestmark = pytest.mark.asyncio

REAL_DATA = Path(__file__).resolve().parents[1] / "data" / "uttar-kaundia"
OWNER_ALPHA = "টেস্ট মালিক আলফা"
OWNER_BETA = "টেস্ট মালিক বিটা"
OWNER_GAMMA = "টেস্ট মালিক গামা"
MOUZA = {
    "name_bn": "উত্তর কাউন্দিয়া",
    "name_en": "Uttar Kaundia",
    "upazila_bn": "সাভার",
    "upazila_en": "Savar",
    "district_bn": "ঢাকা",
    "district_en": "Dhaka",
}
RATE_LIMIT = 3


@pytest.fixture(autouse=True)
def _no_network(monkeypatch):
    def _blocked(*args, **kwargs):
        raise AssertionError(f"network access attempted: {args}")

    monkeypatch.setattr(socket, "create_connection", _blocked)
    monkeypatch.setattr(socket.socket, "connect", _blocked)


def _sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _polygon(dag: str) -> dict:
    ring = [[90.33, 23.82], [90.331, 23.82], [90.331, 23.821], [90.33, 23.82]]
    return {
        "type": "Feature",
        "properties": {"survey": "bds", "sheet": "022", "dag": dag, "label_bn": dag, "area_sqm": 3095.0},
        "geometry": {"type": "Polygon", "coordinates": [ring]},
    }


def build_synthetic_dataset(root: Path) -> Path:
    (root / "dags" / "bds").mkdir(parents=True)
    (root / "khatians" / "bds").mkdir(parents=True)
    geo = root / "dags" / "bds" / "022.geojson"
    geo.write_text(json.dumps({"type": "FeatureCollection", "features": [_polygon("22"), _polygon("23")]}))
    (root / "sheets.json").write_text(json.dumps({"bds": ["022"]}))
    khatians = root / "khatians" / "bds" / "022.json"
    khatians.write_text(
        json.dumps(
            {
                "22": {
                    "total_land": {"value": 0.7649, "unit": "acre"},
                    "khatians": [
                        {
                            "khatian_no": "12012",
                            "owners": [OWNER_ALPHA, OWNER_BETA],
                            "stage_code": "objection",
                            "stage_bn": "আপত্তি স্তর",
                        },
                        {"khatian_no": "99", "owners": [OWNER_GAMMA], "stage_code": None, "stage_bn": "অন্য স্তর"},
                    ],
                },
                "23": {
                    "total_land": {"value": 0.7, "unit": "acre"},
                    "khatians": [],
                    "source_note": "hidden_by_source",
                },
            }
        )
    )
    meta = {
        "dataset_version": "test",
        "counts": {"dags": 2},
        "sha256": {"sheets.json": _sha(root / "sheets.json"), "dags/bds/022.geojson": _sha(geo)},
        "khatians": {
            "fetched_at": "2026-10-11T00:00:00+00:00",
            "mouza": MOUZA,
            "land_unit": {"unit": "acre", "verified": True},
            "sha256": {"khatians/bds/022.json": _sha(khatians)},
        },
    }
    (root / "meta.json").write_text(json.dumps(meta))
    return root


@pytest.fixture
def synthetic_root(tmp_path) -> Path:
    return build_synthetic_dataset(tmp_path / "land")


@pytest.fixture
def provider(synthetic_root, monkeypatch):
    instance = LocalJsonLandDataProvider(synthetic_root)
    app.dependency_overrides[get_land_data_provider] = lambda: instance
    monkeypatch.setattr(
        land_routes, "_detail_limiter", SlidingWindowRateLimiter(max_requests=RATE_LIMIT, window_seconds=600)
    )
    yield instance
    app.dependency_overrides.pop(get_land_data_provider, None)


async def _audit_rows(db_session) -> list[AuditLog]:
    result = await db_session.execute(select(AuditLog).where(AuditLog.action == "land.dag_detail_lookup"))
    return list(result.scalars().all())


# ---- provider ---------------------------------------------------------------


async def test_details_shape_and_digit_normalisation(provider):
    details = provider.get_dag_details("bds", "22", "২২")  # short sheet + Bangla digits
    assert details["sheet"] == "022" and details["dag"] == "22"
    assert details["mouza"] == MOUZA
    assert details["total_land"] == {"value": 0.7649, "unit": "acre"}
    assert [k["khatian_no"] for k in details["khatians"]] == ["12012", "99"]
    assert details["khatians"][0]["owners"] == [OWNER_ALPHA, OWNER_BETA]
    assert details["source"]["dataset_version"] == "test"


async def test_hidden_dag_has_empty_khatians(provider):
    details = provider.get_dag_details("bds", "022", "23")
    assert details["khatians"] == [] and details["source_note"] == "hidden_by_source"


async def test_unknown_dag_is_none(provider):
    assert provider.get_dag_details("bds", "022", "999") is None


async def test_dataset_meta_exposes_no_checksums(provider):
    meta = provider.dataset_meta()
    assert "sha256" not in meta and "sha256" not in meta["khatians"]


# ---- startup validation -------------------------------------------------------


async def test_startup_fails_when_khatian_file_missing(synthetic_root):
    (synthetic_root / "khatians" / "bds" / "022.json").unlink()
    with pytest.raises(LandDataError, match="missing"):
        LocalJsonLandDataProvider(synthetic_root)


async def test_startup_fails_when_khatian_file_corrupt(synthetic_root):
    (synthetic_root / "khatians" / "bds" / "022.json").write_text("{not json")
    with pytest.raises(LandDataError, match="checksum"):
        LocalJsonLandDataProvider(synthetic_root)


async def test_startup_fails_when_khatian_block_absent(synthetic_root):
    meta = json.loads((synthetic_root / "meta.json").read_text())
    del meta["khatians"]
    (synthetic_root / "meta.json").write_text(json.dumps(meta))
    with pytest.raises(LandDataError, match="khatian block"):
        LocalJsonLandDataProvider(synthetic_root)


async def test_startup_fails_when_a_dag_has_no_record(synthetic_root):
    path = synthetic_root / "khatians" / "bds" / "022.json"
    records = json.loads(path.read_text())
    del records["23"]
    path.write_text(json.dumps(records))
    meta = json.loads((synthetic_root / "meta.json").read_text())
    meta["khatians"]["sha256"]["khatians/bds/022.json"] = _sha(path)
    (synthetic_root / "meta.json").write_text(json.dumps(meta))
    with pytest.raises(LandDataError, match="incomplete"):
        LocalJsonLandDataProvider(synthetic_root)


# ---- endpoint -------------------------------------------------------------------


async def test_requires_authentication(client, provider):
    assert (await client.get("/api/land/dag/bds/022/22")).status_code == 401


async def test_non_approved_member_is_forbidden(client, db_session, provider):
    member = await _approved_member(db_session, "PendingMember", status=MemberStatus.PENDING)
    resp = await client.get("/api/land/dag/bds/022/22", headers=_member_headers(member))
    assert resp.status_code == 403


async def test_approved_member_gets_details(client, db_session, provider):
    member = await _approved_member(db_session, "ApprovedMember")
    resp = await client.get("/api/land/dag/bds/022/22", headers=_member_headers(member))
    assert resp.status_code == 200
    body = resp.json()
    assert body["khatians"][0]["owners"] == [OWNER_ALPHA, OWNER_BETA]
    assert body["source"]["name"] == "settlement.gov.bd"


async def test_unknown_dag_is_404_with_specific_message(client, db_session, provider):
    member = await _approved_member(db_session, "MissingMember")
    resp = await client.get("/api/land/dag/bds/022/999", headers=_member_headers(member))
    assert resp.status_code == 404
    detail = resp.json()["detail"]
    assert detail["code"] == "DAG_NOT_FOUND" and "999" in detail["message"]


async def test_lookup_writes_audit_row_without_names(client, db_session, provider):
    member = await _approved_member(db_session, "AuditedMember")
    await client.get("/api/land/dag/bds/022/22", headers=_member_headers(member))
    rows = await _audit_rows(db_session)
    assert len(rows) == 1
    assert rows[0].entity_id == "bds:022:22"
    assert f"viewer_member_id={member.id}" in rows[0].detail
    assert OWNER_ALPHA not in (rows[0].detail or "")


async def test_rate_limit_returns_429_and_audits_only_served_lookups(client, db_session, provider):
    member = await _approved_member(db_session, "ScraperMember")
    headers = _member_headers(member)
    for _ in range(RATE_LIMIT):
        assert (await client.get("/api/land/dag/bds/022/22", headers=headers)).status_code == 200
    blocked = await client.get("/api/land/dag/bds/022/22", headers=headers)
    assert blocked.status_code == 429
    assert "Retry-After" in blocked.headers
    assert len(await _audit_rows(db_session)) == RATE_LIMIT


async def test_owner_names_absent_from_list_and_bbox_responses(client, db_session, provider):
    member = await _approved_member(db_session, "ListMember")
    headers = _member_headers(member)
    bbox = {"bbox": "90.0,23.0,91.0,24.0"}
    for url, params in (("/api/land/dags", bbox), ("/api/land/dag/bds/lookup/22", None), ("/api/land/meta", None)):
        resp = await client.get(url, params=params, headers=headers)
        assert resp.status_code == 200
        assert OWNER_ALPHA not in resp.text and "owners" not in resp.text, url


async def test_khatian_catalog_is_not_publicly_served(client):
    for name in ("khatians", "khatians.json"):
        assert (await client.get(f"/api/data/{name}")).status_code == 404


# ---- leak guard on the real shipped files -----------------------------------------


def test_real_owner_names_only_in_khatian_files():
    khatian_files = sorted((REAL_DATA / "khatians").glob("*/*.json"))
    if not khatian_files:
        pytest.skip("real khatian dataset not built yet")
    names = {
        owner
        for path in khatian_files
        for record in json.loads(path.read_text(encoding="utf-8")).values()
        for khatian in record["khatians"]
        for owner in khatian["owners"]
        if len(owner) >= 6
    }
    sample = sorted(names)[:: max(1, len(names) // 400)]
    others = [
        p
        for p in REAL_DATA.rglob("*")
        if p.is_file() and "khatians" not in p.relative_to(REAL_DATA).parts
    ] + list((REAL_DATA.parent / "shared").glob("*.json"))
    for path in others:
        text = path.read_text(encoding="utf-8", errors="ignore")
        leaked = next((n for n in sample if n in text), None)
        assert leaked is None, f"owner name leaked into {path.name}"
    assert '"owners"' not in (REAL_DATA / "meta.json").read_text(encoding="utf-8")
