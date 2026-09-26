import { FormBuilder } from '@angular/forms';
import { describe, expect, it } from 'vitest';
import { buildPropertyGroup } from './registration-form.builder';

describe('buildPropertyGroup share quantity validation', () => {
  const fb = new FormBuilder();

  it('flags share quantity greater than total land quantity', () => {
    const group = buildPropertyGroup(fb);
    group.patchValue({ landQuantity: '6', myShareQuantity: '7' });

    expect(group.hasError('shareExceedsTotal')).toBe(true);
  });

  it('allows share quantity equal to total land quantity', () => {
    const group = buildPropertyGroup(fb);
    group.patchValue({ landQuantity: '6', myShareQuantity: '6' });

    expect(group.hasError('shareExceedsTotal')).toBe(false);
  });

  it('allows share quantity less than total land quantity', () => {
    const group = buildPropertyGroup(fb);
    group.patchValue({ landQuantity: '2.5', myShareQuantity: '1.25' });

    expect(group.hasError('shareExceedsTotal')).toBe(false);
  });

  it('does not flag when values are missing or not numbers', () => {
    const group = buildPropertyGroup(fb);
    group.patchValue({ landQuantity: '', myShareQuantity: '' });

    expect(group.hasError('shareExceedsTotal')).toBe(false);
  });
});
