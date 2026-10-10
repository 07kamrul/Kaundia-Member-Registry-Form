import { describe, expect, it } from 'vitest';
import { parseDeclaredShotangsho, validateDrawing } from './boundary-validation';

const BBOX = '90.34,23.72,90.44,23.82';

const INSIDE_SQUARE = {
  type: 'Polygon' as const,
  coordinates: [
    [
      [90.39, 23.77],
      [90.4, 23.77],
      [90.4, 23.78],
      [90.39, 23.78],
      [90.39, 23.77],
    ],
  ],
};

const BOW_TIE = {
  type: 'Polygon' as const,
  coordinates: [
    [
      [90.39, 23.77],
      [90.41, 23.79],
      [90.41, 23.77],
      [90.39, 23.79],
      [90.39, 23.77],
    ],
  ],
};

const OUTSIDE = {
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

function geometryCloseTo(actual: number | null, expected: number, precision = 3): boolean {
  return actual !== null && Math.abs(actual - expected) < Math.pow(10, -precision);
}

describe('validateDrawing', () => {
  it('marks an incomplete shape invalid with no diagnostics', () => {
    const result = validateDrawing(null, '5', BBOX);
    expect(result.valid).toBe(false);
    expect(result.areaSqM).toBeNull();
  });

  it('detects self-intersection in a bow tie', () => {
    const result = validateDrawing(BOW_TIE, null, BBOX);
    expect(result.selfIntersection).toBe(true);
    expect(result.valid).toBe(false);
  });

  it('detects polygons outside the society bbox', () => {
    const result = validateDrawing(OUTSIDE, null, BBOX);
    expect(result.outsideSociety).toBe(true);
    expect(result.valid).toBe(false);
  });

  it('accepts a clean polygon inside the society area', () => {
    const result = validateDrawing(INSIDE_SQUARE, null, BBOX);
    expect(result.valid).toBe(true);
    expect(result.selfIntersection).toBe(false);
    expect(result.outsideSociety).toBe(false);
    expect(result.areaSqM).toBeGreaterThan(900_000);
    expect(geometryCloseTo(result.areaShotangsho, result.areaSqM! / 40.47)).toBe(true);
  });

  it('warns when the drawn area mismatches the declared shotangsho', () => {
    const result = validateDrawing(INSIDE_SQUARE, '5', BBOX);
    expect(result.areaMismatch).toBe(true);
    // Validity survives an area warning - it is advisory only.
    expect(result.valid).toBe(true);
  });

  it('accepts when the declared quantity matches the drawn area', () => {
    const measured = validateDrawing(INSIDE_SQUARE, null, BBOX);
    const result = validateDrawing(
      INSIDE_SQUARE,
      measured.areaShotangsho!.toFixed(2),
      BBOX,
    );
    expect(result.areaMismatch).toBe(false);
  });

  it('ignores non-numeric declared quantities for the area check', () => {
    const result = validateDrawing(INSIDE_SQUARE, '5/1 share', BBOX);
    expect(result.areaMismatch).toBe(false);
  });

  it('falls back to a world bbox when the config string is invalid', () => {
    const result = validateDrawing(INSIDE_SQUARE, null, 'not-a-bbox');
    expect(result.outsideSociety).toBe(false);
    expect(result.valid).toBe(true);
  });
});

describe('parseDeclaredShotangsho', () => {
  it('parses numeric values including Bangla digits', () => {
    expect(parseDeclaredShotangsho('5')).toBe(5);
    expect(parseDeclaredShotangsho('৫')).toBe(5);
    expect(parseDeclaredShotangsho('12.5')).toBe(12.5);
  });

  it('returns null for share text or empty values', () => {
    expect(parseDeclaredShotangsho('3/1')).toBeNull();
    expect(parseDeclaredShotangsho(null)).toBeNull();
    expect(parseDeclaredShotangsho('')).toBeNull();
  });
});
