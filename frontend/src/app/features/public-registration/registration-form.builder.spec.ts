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

describe('buildPropertyGroup zero quantity validation', () => {
  const fb = new FormBuilder();

  it('rejects zero total land quantity', () => {
    const group = buildPropertyGroup(fb);
    group.patchValue({ landQuantity: '0', myShareQuantity: '1' });

    expect(group.get('landQuantity')?.hasError('notPositive')).toBe(true);
  });

  it('rejects zero share quantity', () => {
    const group = buildPropertyGroup(fb);
    group.patchValue({ landQuantity: '6', myShareQuantity: '0' });

    expect(group.get('myShareQuantity')?.hasError('notPositive')).toBe(true);
  });

  it('rejects zero formatted as decimal', () => {
    const group = buildPropertyGroup(fb);
    group.patchValue({ landQuantity: '0.0', myShareQuantity: '0.00' });

    expect(group.get('landQuantity')?.hasError('notPositive')).toBe(true);
    expect(group.get('myShareQuantity')?.hasError('notPositive')).toBe(true);
  });

  it('accepts positive decimal quantities', () => {
    const group = buildPropertyGroup(fb);
    group.patchValue({ landQuantity: '6', myShareQuantity: '1.5' });

    expect(group.get('landQuantity')?.hasError('notPositive')).toBe(false);
    expect(group.get('myShareQuantity')?.hasError('notPositive')).toBe(false);
  });

  it('leaves empty values to the required validator', () => {
    const group = buildPropertyGroup(fb);
    group.patchValue({ landQuantity: '', myShareQuantity: '' });

    expect(group.get('landQuantity')?.hasError('notPositive')).toBe(false);
    expect(group.get('landQuantity')?.hasError('required')).toBe(true);
    expect(group.get('myShareQuantity')?.hasError('notPositive')).toBe(false);
    expect(group.get('myShareQuantity')?.hasError('required')).toBe(true);
  });
});
