"""Pure-Python geodesic helpers for plot-boundary polygons.

Boundaries are stored as RFC 7946 GeoJSON rings: ``[[lng, lat], ...]`` with
the first point repeated at the end. The dev database is SQLite and production
may run without PostGIS, so area, overlap and validity are computed here
instead of in the database. If PostGIS is introduced later, these functions
remain the reference implementation for the tests.

Coordinate order is validated loudly: the classic bug is a client sending
``[lat, lng]``. ``normalize_ring`` rejects rings whose points cannot be
Bangladesh coordinates when a bounds check is requested.
"""

import math
from dataclasses import dataclass

# Authalic Earth radius (IGRF), the same value PostGIS geography uses.
EARTH_RADIUS_M = 6371007.181

# 1 শতাংশ (shotangsho/decimal) = 435.6 sq ft.
SQM_PER_SHOTANGSHO = 435.6 * 0.09290304  # ≈ 40.4686 m²

_MIN_RING_VERTICES = 3


@dataclass(frozen=True)
class Bounds:
    min_lng: float
    min_lat: float
    max_lng: float
    max_lat: float

    def contains(self, lng: float, lat: float) -> bool:
        return self.min_lng <= lng <= self.max_lng and self.min_lat <= lat <= self.max_lat


def parse_bounds(raw: str) -> Bounds:
    parts = [float(p) for p in raw.split(",")]
    if len(parts) != 4:
        raise ValueError(f"bbox must be 'minLng,minLat,maxLng,maxLat', got {raw!r}")
    return Bounds(*parts)


def _is_ring(coords: object) -> bool:
    return (
        isinstance(coords, list)
        and len(coords) >= 4
        and all(isinstance(p, list) and len(p) == 2 for p in coords)
        and coords[0] == coords[-1]
    )


def distinct_vertices(coords: list[list[float]]) -> int:
    """Number of unique vertices, ignoring the closing repeat."""
    return len({tuple(p) for p in coords[:-1]})


def normalize_geometry(geometry: dict) -> list[list[float]]:
    """Validate a GeoJSON Polygon and return its closed outer ring.

    Raises ValueError with a caller-presentable message on any malformation.
    Only the outer ring is accepted; holes are not meaningful for member plots.
    """
    if not isinstance(geometry, dict) or geometry.get("type") != "Polygon":
        raise ValueError("geometry must be a GeoJSON Polygon")
    coordinates = geometry.get("coordinates")
    if not isinstance(coordinates, list) or len(coordinates) != 1:
        raise ValueError("geometry.coordinates must contain exactly one ring")
    ring = coordinates[0]
    if not _is_ring(ring):
        raise ValueError("ring must be closed (first point repeated last) with [lng, lat] points")
    for lng, lat in ring:
        if not (math.isfinite(lng) and math.isfinite(lat)):
            raise ValueError("coordinates must be finite numbers")
        if not (-180 <= lng <= 180 and -90 <= lat <= 90):
            raise ValueError("coordinates out of lng/lat range; expected [lng, lat] order")
    if distinct_vertices(ring) < _MIN_RING_VERTICES:
        raise ValueError("a polygon needs at least 3 distinct vertices")
    return [list(p) for p in ring]


# --- segment geometry ---------------------------------------------------------------


def _orientation(a, b, p) -> int:
    v = (b[0] - a[0]) * (p[1] - a[1]) - (b[1] - a[1]) * (p[0] - a[0])
    if v > 1e-12:
        return 1
    if v < -1e-12:
        return -1
    return 0


def _on_segment(a, b, p) -> bool:
    return (
        min(a[0], b[0]) - 1e-12 <= p[0] <= max(a[0], b[0]) + 1e-12
        and min(a[1], b[1]) - 1e-12 <= p[1] <= max(a[1], b[1]) + 1e-12
    )


def _segments_cross(p1, p2, q1, q2) -> bool:
    """Proper crossing between two segments (shared endpoints do not count)."""
    o1 = _orientation(p1, p2, q1)
    o2 = _orientation(p1, p2, q2)
    o3 = _orientation(q1, q2, p1)
    o4 = _orientation(q1, q2, p2)
    return o1 != o2 and o3 != o4 and 0 not in (o1, o2, o3, o4)


def has_self_intersection(ring: list[list[float]]) -> bool:
    """True when any two non-adjacent edges of the ring properly cross."""
    n = len(ring) - 1  # ring is closed; edge i = ring[i] -> ring[i+1]
    for i in range(n):
        for j in range(i + 1, n):
            if abs(i - j) <= 1 or (i == 0 and j == n - 1):
                continue  # adjacent edges legitimately share a vertex
            if _segments_cross(ring[i], ring[i + 1], ring[j], ring[j + 1]):
                return True
    return False


def point_in_ring(point: list[float], ring: list[list[float]]) -> bool:
    """Ray-casting containment test for a point against a closed ring."""
    lng, lat = point
    inside = False
    n = len(ring) - 1
    for i in range(n):
        x1, y1 = ring[i]
        x2, y2 = ring[i + 1]
        if (y1 > lat) != (y2 > lat):
            x_at = x1 + (lat - y1) * (x2 - x1) / (y2 - y1)
            if lng < x_at:
                inside = not inside
    return inside


def _on_any_edge(point: list[float], ring: list[list[float]]) -> bool:
    n = len(ring) - 1
    for i in range(n):
        a, b = ring[i], ring[i + 1]
        if _orientation(a, b, point) == 0 and _on_segment(a, b, point):
            return True
    return False


def polygons_overlap(ring_a: list[list[float]], ring_b: list[list[float]]) -> bool:
    """True when two closed rings share area (edge-touching does not count).

    Overlap means: a vertex of one ring strictly inside the other, or any
    edge pair properly crossing. Sharing only an edge or corner is touching,
    which is normal between adjacent plots and must not raise a dispute.
    """
    # Identical or exactly stacked rings have no strictly-interior vertex and
    # no crossing edges — still a full overlap, not a touch.
    if all(_on_any_edge(p, ring_b) for p in ring_a[:-1]) and all(
        _on_any_edge(p, ring_a) for p in ring_b[:-1]
    ):
        return True
    for p in ring_a[:-1]:
        if not _on_any_edge(p, ring_b) and point_in_ring(p, ring_b):
            return True
    for p in ring_b[:-1]:
        if not _on_any_edge(p, ring_a) and point_in_ring(p, ring_a):
            return True
    n_a, n_b = len(ring_a) - 1, len(ring_b) - 1
    for i in range(n_a):
        for j in range(n_b):
            if _segments_cross(ring_a[i], ring_a[i + 1], ring_b[j], ring_b[j + 1]):
                return True
    return False


def intersection_area_sqm(ring_a: list[list[float]], ring_b: list[list[float]]) -> float:
    """Geodesic area of the overlap of two rings, via Sutherland–Hodgman
    clipping against a convexised clip ring and spherical-excess area.

    The clip ring is replaced by its convex hull, so for non-convex clip
    polygons the reported overlap area is an upper bound — always sufficient
    for the committee's "how big is the dispute" figure.
    """
    if not polygons_overlap(ring_a, ring_b):
        return 0.0
    # Drop the closing duplicate before clipping; degenerate zero-length
    # edges corrupt the half-plane tests.
    clipped = [tuple(p) for p in ring_a[:-1]]
    hull = _convex_hull([tuple(p) for p in ring_b[:-1]])
    if len(hull) >= 3:
        # Ensure the hull ring is counter-clockwise for inside tests.
        if signed_area(hull) < 0:
            hull = hull[::-1]
        for i in range(len(hull)):
            a, b = hull[i], hull[(i + 1) % len(hull)]
            clipped = _clip_half_plane(clipped, a, b)
            if not clipped:
                return 0.0
    closed = [list(p) for p in clipped] + [list(clipped[0])]
    return abs(spherical_excess_area_sqm(closed))


def _clip_half_plane(poly: list[tuple[float, float]], a, b) -> list[tuple[float, float]]:
    def inside(p) -> bool:
        return _orientation(a, b, p) >= 0

    out: list[tuple[float, float]] = []
    n = len(poly)
    for i in range(n):
        cur, nxt = poly[i], poly[(i + 1) % n]
        if inside(cur):
            out.append(cur)
        if inside(cur) != inside(nxt):
            t = _segment_plane_intersection(cur, nxt, a, b)
            if t is not None:
                out.append(t)
    return out


def _segment_plane_intersection(p1, p2, a, b):
    denom = (b[0] - a[0]) * (p2[1] - p1[1]) - (b[1] - a[1]) * (p2[0] - p1[0])
    if abs(denom) < 1e-15:
        return None
    t = ((b[0] - a[0]) * (a[1] - p1[1]) - (b[1] - a[1]) * (a[0] - p1[0])) / denom
    if not (-1e-9 <= t <= 1 + 1e-9):
        return None
    return (p1[0] + t * (p2[0] - p1[0]), p1[1] + t * (p2[1] - p1[1]))


def _convex_hull(points: list[tuple[float, float]]) -> list[tuple[float, float]]:
    pts = sorted(set(points))
    if len(pts) < 3:
        return pts

    def cross(o, a, b) -> float:
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower: list = []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    upper: list = []
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


# --- area ---------------------------------------------------------------------------


def signed_area(ring: list[tuple[float, float]]) -> float:
    """Planar signed area in squared degrees; sign gives ring orientation."""
    total = 0.0
    for i in range(len(ring)):
        x1, y1 = ring[i]
        x2, y2 = ring[(i + 1) % len(ring)]
        total += x1 * y2 - x2 * y1
    return total / 2


def spherical_excess_area_sqm(ring: list[list[float]]) -> float:
    """Geodesic area of a closed ring on the sphere (Chamberlain & Duquette).

    Accurate to well under a percent for parcel-sized polygons — the right
    order for comparing against a declared land quantity; not a survey value.
    """
    total = 0.0
    n = len(ring) - 1
    for i in range(n):
        lng1, lat1 = ring[i]
        lng2, lat2 = ring[i + 1]
        total += math.radians(lng2 - lng1) * (2 + math.sin(math.radians(lat1)) + math.sin(math.radians(lat2)))
    return total * EARTH_RADIUS_M**2 / 2


def geodesic_area_sqm(ring: list[list[float]]) -> float:
    return abs(spherical_excess_area_sqm(ring))


def to_shotangsho(area_sqm: float) -> float:
    return area_sqm / SQM_PER_SHOTANGSHO
