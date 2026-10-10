"""Local land-record data provider (Uttar Kaundia BDS mouza map).

Replaces the former runtime proxies to the government map portals: the whole
dataset is ingested ahead of time by ``scripts/ingest_land_data/`` and shipped
as JSON/GeoJSON under ``data/uttar-kaundia/``. This module is the single
abstraction the app reads it through — nothing here performs network I/O.

Startup behaviour is fail-fast: missing files, corrupt JSON, or a checksum
mismatch against ``meta.json`` raise ``LandDataError``, which the app turns
into a clear boot failure (the map feature cannot work without the dataset,
and silently serving an empty map would hide the problem).

The map layer contains no personal data — only dag numbers and geometry.
"""

from __future__ import annotations

import hashlib
import json
import logging
import math
from abc import ABC, abstractmethod
from collections.abc import Iterable
from functools import lru_cache
from pathlib import Path

from app.core.config import get_settings

logger = logging.getLogger(__name__)

BBox = tuple[float, float, float, float]  # min_lng, min_lat, max_lng, max_lat


class LandDataError(RuntimeError):
    """Raised when the local land dataset is missing, corrupt or tampered."""


class LandDataProvider(ABC):
    """Read-only view over the ingested land dataset."""

    @abstractmethod
    def list_sheets(self, survey: str) -> list[str]: ...

    @abstractmethod
    def get_dag(self, survey: str, sheet: str, dag: str) -> dict | None:
        """Full GeoJSON feature for one dag, or None."""

    @abstractmethod
    def find_dags(self, survey: str, dag_no: str) -> list[dict]:
        """All features whose dag number equals ``dag_no`` in the survey."""

    @abstractmethod
    def features_in_bbox(self, bbox: BBox, limit: int = 500) -> list[dict]:
        """Features whose centroid intersects the bbox, capped at ``limit``."""

    @abstractmethod
    def dataset_meta(self) -> dict: ...

    @abstractmethod
    def masterplan_features_in_bbox(self, bbox: BBox, limit: int = 500) -> list[dict]:
        """RAJUK DAP overlay plots (may be empty when the overlay wasn't ingested)."""

    @abstractmethod
    def masterplan_find(self, rs_plot_no: str) -> list[dict]:
        """All overlay plots whose RS number equals ``rs_plot_no``."""


def _ascii_digits(text: str) -> str:
    return (text or "").translate(str.maketrans("০১২৩৪৫৬৭৮৯", "0123456789")).strip()


def _normalize_sheet(sheet: str) -> str:
    """Sheets are zero-padded 3-digit strings ("001"); accept "1" too."""
    s = _ascii_digits(str(sheet))
    if s.isdigit() and len(s) < 3:
        s = s.zfill(3)
    return s


def _normalize_rs(rs_plot_no: str) -> str:
    """RS plots are stored as "RS-4611"; index and query them by digits only,
    so "4611", "RS-4611" and Bangla digits all match the same plot."""
    return _ascii_digits(str(rs_plot_no)).upper().replace("RS-", "").strip()


class LocalJsonLandDataProvider(LandDataProvider):
    """Loads data/uttar-kaundia into memory once and serves lookups from it."""

    def __init__(self, root: Path):
        self.root = root
        self._meta = self._load_and_verify()
        self._sheets: dict[str, list[str]] = self._meta_sheets()
        self._features: dict[str, dict] = {}  # "survey:sheet:dag" -> feature
        self._by_dag: dict[str, list[str]] = {}  # "survey:dag" -> keys
        self._centroids: dict[str, tuple[float, float]] = {}
        self._build_index()
        self._masterplan = self._load_masterplan()

    # -- loading -----------------------------------------------------------

    def _load_and_verify(self) -> dict:
        meta_path = self.root / "meta.json"
        if not meta_path.is_file():
            raise LandDataError(
                f"Land dataset meta file missing: {meta_path}. "
                "Run scripts/ingest_land_data/ingest.py to produce it."
            )
        try:
            meta = json.loads(meta_path.read_text())
        except json.JSONDecodeError as exc:
            raise LandDataError(f"Land dataset meta.json is corrupt: {exc}") from exc

        for rel, expected in (meta.get("sha256") or {}).items():
            path = self.root / rel
            if not path.is_file():
                raise LandDataError(f"Land dataset file missing: {path}")
            actual = hashlib.sha256(path.read_bytes()).hexdigest()
            if actual != expected:
                raise LandDataError(
                    f"Land dataset checksum mismatch for {rel} — "
                    "the file changed after ingestion; re-run the ingest script."
                )
        return meta

    def _meta_sheets(self) -> dict[str, list[str]]:
        sheets_path = self.root / "sheets.json"
        if not sheets_path.is_file():
            raise LandDataError(f"Land dataset file missing: {sheets_path}")
        raw = json.loads(sheets_path.read_text())
        return {survey: sorted(sheets) for survey, sheets in raw.items()}

    def _build_index(self) -> None:
        count = 0
        for survey in self._sheets:
            for sheet in self._sheets[survey]:
                path = self.root / "dags" / survey / f"{sheet}.geojson"
                if not path.is_file():
                    raise LandDataError(f"Land dataset file missing: {path}")
                try:
                    fc = json.loads(path.read_text())
                except json.JSONDecodeError as exc:
                    raise LandDataError(f"Land dataset file corrupt ({path}): {exc}") from exc
                for feature in fc.get("features", []):
                    props = feature.get("properties", {})
                    dag = _ascii_digits(str(props.get("dag", "")))
                    if not dag:
                        continue
                    key = f"{survey}:{sheet}:{dag}"
                    self._features[key] = feature
                    self._by_dag.setdefault(f"{survey}:{dag}", []).append(key)
                    self._centroids[key] = self._centroid_of(feature)
                    count += 1
        expected = (self._meta.get("counts") or {}).get("dags")
        if expected is not None and expected != count:
            raise LandDataError(
                f"Land dataset inconsistent: meta.json says {expected} dags, "
                f"files contain {count}."
            )
        logger.info(
            "Land dataset loaded: %s dags, %s surveys, dataset_version=%s",
            count, len(self._sheets), self._meta.get("dataset_version"),
        )

    @staticmethod
    def _centroid_of(feature: dict) -> tuple[float, float]:
        ring = feature["geometry"]["coordinates"][0]
        pts = ring[:-1] if ring[0] == ring[-1] else ring
        lng = sum(p[0] for p in pts) / len(pts)
        lat = sum(p[1] for p in pts) / len(pts)
        return (lng, lat)

    def _load_masterplan(self) -> list[tuple[dict, tuple[float, float]]]:
        """RAJUK DAP overlay, optional — an absent file is not an error."""
        self._masterplan_by_rs: dict[str, list[dict]] = {}
        path = self.root / "masterplan.geojson"
        if not path.is_file():
            return []
        try:
            fc = json.loads(path.read_text())
        except json.JSONDecodeError as exc:
            raise LandDataError(f"Land dataset file corrupt ({path}): {exc}") from exc
        out = []
        for feature in fc.get("features", []):
            out.append((feature, self._centroid_of(feature)))
            rs = feature.get("properties", {}).get("rs_plot_no")
            if rs:
                self._masterplan_by_rs.setdefault(_normalize_rs(rs), []).append(feature)
        return out

    # -- LandDataProvider ----------------------------------------------------

    def list_sheets(self, survey: str) -> list[str]:
        return list(self._sheets.get(survey, []))

    def get_dag(self, survey: str, sheet: str, dag: str) -> dict | None:
        return self._features.get(f"{survey}:{_normalize_sheet(sheet)}:{_ascii_digits(dag)}")

    def find_dags(self, survey: str, dag_no: str) -> list[dict]:
        keys = self._by_dag.get(f"{survey}:{_ascii_digits(dag_no)}", [])
        return [self._features[k] for k in keys]

    def features_in_bbox(self, bbox: BBox, limit: int = 500) -> list[dict]:
        min_lng, min_lat, max_lng, max_lat = bbox
        out: list[dict] = []
        for key, (lng, lat) in self._centroids.items():
            if min_lng <= lng <= max_lng and min_lat <= lat <= max_lat:
                out.append(self._features[key])
                if len(out) >= limit:
                    break
        return out

    def dataset_meta(self) -> dict:
        # Checksums are an integrity mechanism, not client data.
        meta = dict(self._meta)
        meta.pop("sha256", None)
        return meta

    def masterplan_features_in_bbox(self, bbox: BBox, limit: int = 500) -> list[dict]:
        min_lng, min_lat, max_lng, max_lat = bbox
        out: list[dict] = []
        for feature, (lng, lat) in self._masterplan:
            if min_lng <= lng <= max_lng and min_lat <= lat <= max_lat:
                out.append(feature)
                if len(out) >= limit:
                    break
        return out

    def masterplan_find(self, rs_plot_no: str) -> list[dict]:
        return list(self._masterplan_by_rs.get(_normalize_rs(rs_plot_no), []))


@lru_cache(maxsize=1)
def get_land_data_provider() -> LocalJsonLandDataProvider:
    """Process-wide provider. Raises LandDataError at first use (startup)."""
    settings = get_settings()
    return LocalJsonLandDataProvider(Path(settings.land_data_dir))


def point_in_polygon(lng: float, lat: float, feature: dict) -> bool:
    ring = feature["geometry"]["coordinates"][0]
    inside = False
    j = len(ring) - 1
    for i in range(len(ring)):
        xi, yi = ring[i]
        xj, yj = ring[j]
        if (yi > lat) != (yj > lat) and lng < (xj - xi) * (lat - yi) / (yj - yi) + xi:
            inside = not inside
        j = i
    return inside


__all__ = [
    "BBox",
    "LandDataError",
    "LandDataProvider",
    "LocalJsonLandDataProvider",
    "get_land_data_provider",
    "point_in_polygon",
]
