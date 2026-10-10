import { area, bbox as turfBbox, kinks } from '@turf/turf';
import type { PolygonGeometry } from '../models/plot-boundary.model';

/**
 * The single place where GeoJSON [lng,lat] and Leaflet [lat,lng] pairs are
 * converted. Every map component funnels through these two functions so an
 * axis swap can never happen piecemeal.
 */

/** Leaflet [lat, lng] -> GeoJSON [lng, lat]. */
export function latLngToGeo(point: [number, number]): [number, number] {
  return [point[1], point[0]];
}

/** GeoJSON [lng, lat] -> Leaflet [lat, lng]. */
export function geoToLatLng(point: [number, number]): [number, number] {
  return [point[1], point[0]];
}

/** Geodesic area of a GeoJSON polygon in square metres (turf.area). */
export function polygonAreaSqM(geometry: PolygonGeometry): number {
  return area(geometry);
}

/** 1 শতাংশ = 435.6 sq ft -> m²/40.47, same convention as the backend. */
export function sqmToShotangsho(areaSqM: number): number {
  return areaSqM / 40.47;
}

export interface KinkPoint {
  lng: number;
  lat: number;
}

/** Self-intersection points of a GeoJSON polygon (turf.kinks). */
export function polygonKinks(geometry: PolygonGeometry): KinkPoint[] {
  return kinks(geometry).features.map((f) => ({
    lng: f.geometry.coordinates[0],
    lat: f.geometry.coordinates[1],
  }));
}

export type SocietyBbox = [number, number, number, number]; // minLng,minLat,maxLng,maxLat

/** Parses the "minLng,minLat,maxLng,maxLat" environment string. */
export function parseSocietyBbox(raw: string): SocietyBbox {
  const parts = raw.split(',').map((part) => Number(part.trim()));
  if (parts.length !== 4 || parts.some((n) => !Number.isFinite(n))) {
    throw new Error(`Invalid societyBbox: "${raw}"`);
  }
  return parts as SocietyBbox;
}

/** True when the polygon (any part of it) lies outside the society bbox. */
export function polygonOutsideBbox(geometry: PolygonGeometry, bbox: SocietyBbox): boolean {
  const [minLng, minLat, maxLng, maxLat] = turfBbox(geometry);
  return (
    minLng < bbox[0] ||
    minLat < bbox[1] ||
    maxLng > bbox[2] ||
    maxLat > bbox[3]
  );
}

/** Closes a lat/lng ring in place (first == last) before building GeoJSON. */
export function closeRing(ring: [number, number][]): [number, number][] {
  if (ring.length < 3) return ring;
  const [first] = ring;
  const last = ring[ring.length - 1];
  if (first[0] === last[0] && first[1] === last[1]) return ring;
  return [...ring, [first[0], first[1]]];
}

/** Leaflet lat/lng ring -> closed GeoJSON polygon geometry. */
export function latLngsToGeometry(ring: [number, number][]): PolygonGeometry {
  const geoRing = closeRing(ring).map(latLngToGeo);
  return { type: 'Polygon', coordinates: [geoRing] };
}
