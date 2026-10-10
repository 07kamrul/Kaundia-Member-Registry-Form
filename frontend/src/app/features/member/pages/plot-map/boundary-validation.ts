import {
  polygonAreaSqM,
  polygonKinks,
  polygonOutsideBbox,
  parseSocietyBbox,
  sqmToShotangsho,
  type SocietyBbox,
} from '../../../../core/services/geo.helper';
import type { PolygonGeometry } from '../../../../core/models/plot-boundary.model';

/**
 * Pure client-side draw validation - kept out of the component so it can be
 * unit tested without Leaflet. The backend re-validates everything; these are
 * the live hints while drawing/vertex-editing.
 */

export interface DrawValidation {
  selfIntersection: boolean;
  outsideSociety: boolean;
  areaMismatch: boolean;
  areaSqM: number | null;
  areaShotangsho: number | null;
  valid: boolean;
}

const NUMERIC_QUANTITY = /^\d+(\.\d+)?$/;
/** Areas differing by more than this fraction trigger the warning. */
const AREA_MISMATCH_TOLERANCE = 0.35;
/** Rough backend limit for vertices per ring. */
export const MAX_VERTICES = 100;

/**
 * Declared land quantity is a free-text shotangsho value ("5", "৫", "3/1"
 * shares etc.) - only a clean numeric value participates in the area check.
 */
export function parseDeclaredShotangsho(quantity: string | null | undefined): number | null {
  if (!quantity) return null;
  const ascii = quantity.replace(/[০-৯]/g, (d) => String('০১২৩৪৫৬৭৮৯'.indexOf(d)));
  return NUMERIC_QUANTITY.test(ascii.trim()) ? Number(ascii.trim()) : null;
}

export function validateDrawing(
  geometry: PolygonGeometry | null,
  declaredQuantity: string | null | undefined,
  societyBboxRaw: string,
): DrawValidation {
  const none: DrawValidation = {
    selfIntersection: false,
    outsideSociety: false,
    areaMismatch: false,
    areaSqM: null,
    areaShotangsho: null,
    valid: false,
  };
  if (!geometry || geometry.coordinates[0].length < 4) return none;

  let society: SocietyBbox;
  try {
    society = parseSocietyBbox(societyBboxRaw);
  } catch {
    society = [-180, -90, 180, 90];
  }

  const kinkList = polygonKinks(geometry);
  const outside = polygonOutsideBbox(geometry, society);
  const areaSqM = polygonAreaSqM(geometry);
  const shotangsho = sqmToShotangsho(areaSqM);
  const declared = parseDeclaredShotangsho(declaredQuantity);
  const areaMismatch =
    declared !== null &&
    declared > 0 &&
    Math.abs(shotangsho - declared) / declared > AREA_MISMATCH_TOLERANCE;

  const vertexCount = geometry.coordinates[0].length - 1; // closing point repeats
  const tooManyVertices = vertexCount > MAX_VERTICES;

  return {
    selfIntersection: kinkList.length > 0,
    outsideSociety: outside,
    areaMismatch,
    areaSqM,
    areaShotangsho: shotangsho,
    valid: kinkList.length === 0 && !outside && areaSqM > 0 && !tooManyVertices,
  };
}
