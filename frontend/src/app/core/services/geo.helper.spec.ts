import { describe, expect, it } from 'vitest';
import {
  closeRing,
  geoToLatLng,
  latLngToGeo,
  latLngsToGeometry,
  parseSocietyBbox,
  polygonAreaSqM,
  polygonKinks,
  polygonOutsideBbox,
  sqmToShotangsho,
} from './geo.helper';

const SQUARE_KM: number[][][] = [
  [
    [90.39, 23.77],
    [90.4, 23.77],
    [90.4, 23.78],
    [90.39, 23.78],
    [90.39, 23.77],
  ],
];
const squareKm = { type: 'Polygon' as const, coordinates: SQUARE_KM };

describe('geo.helper axis conversion', () => {
  it('converts [lat,lng] to [lng,lat] and back (round trip)', () => {
    const latLng: [number, number] = [23.77, 90.39];
    const geo = latLngToGeo(latLng);
    expect(geo).toEqual([90.39, 23.77]);
    expect(geoToLatLng(geo)).toEqual(latLng);
  });

  it('round-trips every ring vertex through both directions', () => {
    const ring: [number, number][] = [
      [23.77, 90.39],
      [23.78, 90.39],
      [23.78, 90.4],
    ];
    const back = ring.map((p) => geoToLatLng(latLngToGeo(p)));
    expect(back).toEqual(ring);
  });

  it('builds a closed GeoJSON ring from open lat/lng input', () => {
    const geometry = latLngsToGeometry([
      [23.77, 90.39],
      [23.78, 90.39],
      [23.78, 90.4],
    ]);
    const ring = geometry.coordinates[0];
    expect(ring[0]).toEqual(ring[ring.length - 1]);
    // Every vertex must be [lng, lat].
    for (const [lng, lat] of ring) {
      expect(lng).toBeGreaterThan(80);
      expect(lat).toBeLessThan(40);
    }
  });

  it('closeRing keeps an already-closed ring unchanged', () => {
    const ring: [number, number][] = [
      [1, 2],
      [3, 4],
      [1, 2],
    ];
    expect(closeRing(ring)).toEqual(ring);
  });
});

describe('geo.helper measurement', () => {
  it('measures a ~1 km² square in geodesic m²', () => {
    // 0.01 x 0.01 degrees near Dhaka is roughly 1.2 km².
    const area = polygonAreaSqM(squareKm);
    expect(area).toBeGreaterThan(900_000);
    expect(area).toBeLessThan(1_400_000);
  });

  it('converts m² to shotangsho (m² / 40.47)', () => {
    expect(sqmToShotangsho(40.47)).toBeCloseTo(1, 6);
    expect(sqmToShotangsho(404.7)).toBeCloseTo(10, 6);
  });

  it('finds self-intersection points in a bow-tie ring', () => {
    const bowTie = {
      type: 'Polygon' as const,
      coordinates: [
        [
          [0, 0],
          [2, 2],
          [2, 0],
          [0, 2],
          [0, 0],
        ],
      ],
    };
    expect(polygonKinks(bowTie).length).toBeGreaterThan(0);
  });

  it('finds no kinks in a simple square', () => {
    expect(polygonKinks(squareKm)).toHaveLength(0);
  });

  it('parses the society bbox string and flags outside polygons', () => {
    const bbox = parseSocietyBbox('90.34,23.72,90.44,23.82');
    expect(bbox).toEqual([90.34, 23.72, 90.44, 23.82]);
    expect(polygonOutsideBbox(squareKm, bbox)).toBe(false);
    const farAway = {
      type: 'Polygon' as const,
      coordinates: [
        [
          [89.0, 23.77],
          [89.1, 23.77],
          [89.1, 23.78],
          [89.0, 23.78],
          [89.0, 23.77],
        ],
      ],
    };
    expect(polygonOutsideBbox(farAway, bbox)).toBe(true);
  });

  it('rejects malformed bbox strings', () => {
    expect(() => parseSocietyBbox('1,2,3')).toThrow();
  });
});
