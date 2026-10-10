"""Unit tests for the pure-Python geodesic helpers in app/services/geo.py."""

import math

import pytest

from app.services import geo


def _square(lng: float, lat: float, side_deg_lng: float, side_deg_lat: float) -> list[list[float]]:
    return [
        [lng, lat],
        [lng + side_deg_lng, lat],
        [lng + side_deg_lng, lat + side_deg_lat],
        [lng, lat + side_deg_lat],
        [lng, lat],
    ]


class TestRingValidation:
    def test_accepts_a_valid_closed_ring(self):
        ring = geo.normalize_geometry(
            {"type": "Polygon", "coordinates": [[[90.4, 23.8], [90.41, 23.8], [90.41, 23.81], [90.4, 23.8]]]}
        )
        assert len(ring) == 4

    def test_rejects_non_polygon(self):
        with pytest.raises(ValueError):
            geo.normalize_geometry({"type": "Point", "coordinates": [90.4, 23.8]})

    def test_rejects_unclosed_ring(self):
        with pytest.raises(ValueError):
            geo.normalize_geometry({"type": "Polygon", "coordinates": [[[90.4, 23.8], [90.41, 23.8], [90.41, 23.81]]]})

    def test_rejects_fewer_than_three_distinct_vertices(self):
        with pytest.raises(ValueError):
            geo.normalize_geometry({"type": "Polygon", "coordinates": [[[90.4, 23.8], [90.41, 23.8], [90.4, 23.8]]]})

    def test_rejects_out_of_range_coordinates(self):
        with pytest.raises(ValueError):
            geo.normalize_geometry({"type": "Polygon", "coordinates": [[[190, 23.8], [191, 23.8], [191, 24], [190, 23.8]]]})


class TestArea:
    def test_geodesic_area_of_a_known_square(self):
        # 0.001° lng at lat 23.8 ≈ 101.4 m; 0.001° lat ≈ 110.6 m → ≈ 11,215 m²
        ring = _square(90.4, 23.8, 0.001, 0.001)
        area = geo.geodesic_area_sqm(ring)
        assert 11000 < area < 11500

    def test_bigger_square_scales_linearly(self):
        small = geo.geodesic_area_sqm(_square(90.4, 23.8, 0.001, 0.001))
        big = geo.geodesic_area_sqm(_square(90.4, 23.8, 0.002, 0.001))
        assert big == pytest.approx(2 * small, rel=1e-6)

    def test_shotangsho_conversion(self):
        assert geo.to_shotangsho(geo.SQM_PER_SHOTANGSHO) == pytest.approx(1.0)
        assert 40 < geo.SQM_PER_SHOTANGSHO < 41  # 1 শতাংশ = 435.6 sq ft ≈ 40.47 m²


class TestSelfIntersection:
    def test_bowtie_is_self_intersecting(self):
        ring = [[0, 0], [2, 2], [2, 0], [0, 2], [0, 0]]
        assert geo.has_self_intersection(ring)

    def test_simple_square_is_not(self):
        assert not geo.has_self_intersection(_square(0, 0, 1, 1))

    def test_concave_l_shape_is_not(self):
        ring = [[0, 0], [3, 0], [3, 1], [1, 1], [1, 3], [0, 3], [0, 0]]
        assert not geo.has_self_intersection(ring)


class TestOverlap:
    def test_overlapping_squares_overlap(self):
        a = _square(0, 0, 2, 2)
        b = _square(1, 1, 2, 2)
        assert geo.polygons_overlap(a, b)
        area = geo.intersection_area_sqm(a, b)
        assert 0 < area < geo.geodesic_area_sqm(a)

    def test_edge_touching_is_not_overlap(self):
        a = _square(0, 0, 1, 1)
        b = _square(1, 0, 1, 1)  # shares the edge x=1
        assert not geo.polygons_overlap(a, b)
        assert geo.intersection_area_sqm(a, b) == 0.0

    def test_corner_touching_is_not_overlap(self):
        a = _square(0, 0, 1, 1)
        b = _square(1, 1, 1, 1)
        assert not geo.polygons_overlap(a, b)

    def test_disjoint_is_not_overlap(self):
        assert not geo.polygons_overlap(_square(0, 0, 1, 1), _square(5, 5, 1, 1))

    def test_containment_overlaps(self):
        a = _square(0, 0, 4, 4)
        b = _square(1, 1, 1, 1)
        assert geo.polygons_overlap(a, b)
        assert geo.intersection_area_sqm(a, b) == pytest.approx(geo.geodesic_area_sqm(b), rel=0.05)


class TestBounds:
    def test_parse_and_contains(self):
        bounds = geo.parse_bounds("88.0,20.5,92.7,26.7")
        assert bounds.contains(90.4, 23.8)
        assert not bounds.contains(10.0, 23.8)
        with pytest.raises(ValueError):
            geo.parse_bounds("1,2,3")
