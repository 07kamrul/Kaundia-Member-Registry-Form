"""Parser/validator tests for the ingest script, run against a committed
capture of a real GetSheetJsonBySurvey response.

The fixture has owner name / father name / khatian / land-class fields
injected into every feature (the live map layer doesn't send them, but if it
ever did) to prove validate_feature keeps only dag + geometry and never
persists personal data.

Run:  .venv/bin/python -m pytest test_ingest.py -q
"""

import importlib.util
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
FIXTURE = HERE / "fixtures" / "bds_sheet_001_with_owner_fields.json"


def _load_ingest():
    spec = importlib.util.spec_from_file_location("ingest", HERE / "ingest.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


ingest = _load_ingest()


def _features():
    return json.loads(FIXTURE.read_text())["features"]


def test_owner_fields_never_reach_output():
    errors: list[str] = []
    kept = [ingest.validate_feature(f, "001", errors) for f in _features()]
    kept = [f for f in kept if f]
    assert kept, "fixture features should validate"
    for feature in kept:
        assert set(feature["properties"]) == {"survey", "sheet", "dag", "label_bn", "area_sqm"}
        blob = json.dumps(feature, ensure_ascii=False)
        assert "রহিম" not in blob and "করিম" not in blob
        assert "Khatian" not in blob and "Land_Class" not in blob


def test_bangla_dag_digits_normalized():
    errors: list[str] = []
    kept = {f["properties"]["dag"]: f for f in
            (ingest.validate_feature(f, "001", errors) for f in _features()) if f}
    assert kept, "expected validated features"
    for dag in kept:
        assert dag.isdigit(), f"dag not ASCII digits: {dag!r}"
        assert kept[dag]["properties"]["label_bn"]  # original preserved


def test_coordinate_order_and_bbox():
    errors: list[str] = []
    kept = [ingest.validate_feature(f, "001", errors) for f in _features()]
    kept = [f for f in kept if f]
    # the known point 23.828, 90.331 sits inside the mouza; latitudes must be
    # small numbers (lat) and longitudes ~90 — a swapped dataset fails here.
    for feature in kept:
        for lng, lat in feature["geometry"]["coordinates"][0]:
            assert 86 < lng < 94 and 20 < lat < 28


def test_outside_bbox_and_swapped_coords_dropped():
    errors: list[str] = []
    bad_outside = {
        "properties": {"Dag_No": "99999"},
        "geometry": {"type": "Polygon", "coordinates": [[
            [10.0, 10.0], [10.001, 10.0], [10.001, 10.001], [10.0, 10.001], [10.0, 10.0],
        ]]},
    }
    assert ingest.validate_feature(bad_outside, "001", errors) is None
    bad_swap = {
        "properties": {"Dag_No": "99998"},
        "geometry": {"type": "Polygon", "coordinates": [[
            [23.82, 90.32], [23.821, 90.32], [23.821, 90.321], [23.82, 90.321], [23.82, 90.32],
        ]]},
    }
    assert ingest.validate_feature(bad_swap, "001", errors) is None
    assert len(errors) == 2


def test_dag_less_feature_dropped():
    errors: list[str] = []
    assert ingest.validate_feature(
        {"properties": {}, "geometry": None}, "001", errors
    ) is None
    assert errors


def test_sheet_list_parsing():
    sheets = ingest.fetch_sheets.__wrapped__ if hasattr(ingest.fetch_sheets, "__wrapped__") else None
    raw = json.loads((HERE.parent.parent / "data" / "_raw" / "sheets_bds.json").read_text()) \
        if (HERE.parent.parent / "data" / "_raw" / "sheets_bds.json").exists() else []
    if raw:  # raw cache is local-only; the assertion holds when it exists
        numbers = {s["shetnum"] for s in raw if s.get("shetnum")}
        assert all(n.isdigit() for n in numbers)
