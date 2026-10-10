import { describe, expect, it } from 'vitest';
import type { DagKhatian } from '../../../../../core/services/land-data.service';
import { groupKhatians, landFigures, mouzaLabel } from './dag-info-format';

function khatian(no: string, owners: string[]): DagKhatian {
  return { khatian_no: no, owners, stage_code: 'objection', stage_bn: 'আপত্তি স্তর' };
}

const MOUZA = {
  name_bn: 'উত্তর কাউন্দিয়া',
  name_en: 'Uttar Kaundia',
  upazila_bn: 'সাভার',
  upazila_en: 'Savar',
  district_bn: 'ঢাকা',
  district_en: 'Dhaka',
};

describe('groupKhatians', () => {
  it('gives a single-owner khatian one first row', () => {
    const [group] = groupKhatians([khatian('1', ['টেস্ট এক'])]);

    expect(group.rows).toHaveLength(1);
    expect(group.rows[0]).toMatchObject({ owner: 'টেস্ট এক', isFirst: true, stripe: 'odd' });
  });

  it('spans a three-owner khatian over three rows with only the first marked', () => {
    const [group] = groupKhatians([khatian('2', ['ক', 'খ', 'গ'])]);

    expect(group.rows.map((r) => r.isFirst)).toEqual([true, false, false]);
    expect(group.rows.map((r) => r.stripe)).toEqual(['odd', 'even', 'odd']);
  });

  it('handles a ten-owner khatian', () => {
    const owners = Array.from({ length: 10 }, (_, i) => `টেস্ট ${i}`);
    const [group] = groupKhatians([khatian('3', owners)]);

    expect(group.rows).toHaveLength(10);
    expect(group.rows.filter((r) => r.isFirst)).toHaveLength(1);
  });

  it('continues the zebra striping across khatians', () => {
    const groups = groupKhatians([khatian('1', ['ক', 'খ', 'গ']), khatian('2', ['ঘ']), khatian('3', ['ঙ'])]);

    expect(groups.map((g) => g.rows.map((r) => r.stripe))).toEqual([['odd', 'even', 'odd'], ['even'], ['odd']]);
  });

  it('keeps an owner-less khatian visible as one blank row', () => {
    const [group] = groupKhatians([khatian('4', [])]);

    expect(group.rows).toEqual([{ owner: '', isFirst: true, stripe: 'odd' }]);
  });

  it('returns nothing for no khatians', () => {
    expect(groupKhatians([])).toEqual([]);
  });
});

describe('landFigures', () => {
  it('shows the official number as-is with an approximate shatak for acres', () => {
    const figures = landFigures({ value: 0.7649, unit: 'acre' }, 'en');

    expect(figures).toEqual({ value: '0.7649', shatak: '76.49', unit: 'acre' });
  });

  it('pads to four decimals like the portal', () => {
    expect(landFigures({ value: 1.5, unit: 'acre' }, 'en').value).toBe('1.5000');
  });

  it('uses Bangla digits in Bangla mode', () => {
    const figures = landFigures({ value: 0.7649, unit: 'acre' }, 'bn');

    expect(figures.value).toBe('০.৭৬৪৯');
    expect(figures.shatak).toBe('৭৬.৪৯');
  });

  it('omits the shatak line for non-acre units', () => {
    expect(landFigures({ value: 2, unit: 'hectare' }, 'en').shatak).toBeNull();
  });
});

describe('mouzaLabel', () => {
  it('joins Bangla names in Bangla mode', () => {
    expect(mouzaLabel(MOUZA, 'bn')).toBe('উত্তর কাউন্দিয়া, সাভার, ঢাকা');
  });

  it('joins English names otherwise', () => {
    expect(mouzaLabel(MOUZA, 'en')).toBe('Uttar Kaundia, Savar, Dhaka');
  });
});
