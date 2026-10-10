import type { DagDetails, DagKhatian } from '../../../../../core/services/land-data.service';
import { localizeDigits } from '../../../../../core/services/roadmap.service';

/** 1 acre = 100 শতাংশ (decimal) — the unit local land records are quoted in. */
const SHATAK_PER_ACRE = 100;
const LAND_DECIMALS = 4;
const SHATAK_DECIMALS = 2;

/** One owner row of the khatian table; the first row of a group carries the
 *  spanning khatian-no / stage cells. */
export interface OwnerRow {
  readonly owner: string;
  readonly isFirst: boolean;
  /** Zebra index across the whole table, so striping continues between groups. */
  readonly stripe: 'odd' | 'even';
}

export interface KhatianGroup {
  readonly khatian: DagKhatian;
  readonly rows: readonly OwnerRow[];
}

/** Groups khatians into stacked owner rows with a table-wide zebra index.
 *  A khatian without owners still gets one (blank) row so it stays visible. */
export function groupKhatians(khatians: readonly DagKhatian[]): KhatianGroup[] {
  let index = 0;
  return khatians.map((khatian) => {
    const owners = khatian.owners.length ? khatian.owners : [''];
    const rows = owners.map((owner, i) => {
      const stripe: OwnerRow['stripe'] = index % 2 === 0 ? 'odd' : 'even';
      index += 1;
      return { owner, isFirst: i === 0, stripe };
    });
    return { khatian, rows };
  });
}

export interface LandFigures {
  /** Official number as published, fixed to 4 decimals (digits localised). */
  readonly value: string;
  /** Approximate শতাংশ equivalent for acre values, null for other units. */
  readonly shatak: string | null;
  readonly unit: string;
}

export function landFigures(totalLand: DagDetails['total_land'], lang: string): LandFigures {
  const value = localizeDigits(totalLand.value.toFixed(LAND_DECIMALS), lang);
  const isAcre = totalLand.unit === 'acre';
  const shatak = isAcre
    ? localizeDigits((totalLand.value * SHATAK_PER_ACRE).toFixed(SHATAK_DECIMALS), lang)
    : null;
  return { value, shatak, unit: totalLand.unit };
}

/** "উত্তর কাউন্দিয়া, সাভার, ঢাকা" (or the English names). */
export function mouzaLabel(mouza: DagDetails['mouza'], lang: string): string {
  const parts =
    lang === 'bn'
      ? [mouza.name_bn, mouza.upazila_bn, mouza.district_bn]
      : [mouza.name_en, mouza.upazila_en, mouza.district_en];
  return parts.join(', ');
}
