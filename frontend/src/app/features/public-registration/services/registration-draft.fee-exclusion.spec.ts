import { FormBuilder, FormGroup, FormArray } from '@angular/forms';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { RegistrationDraftService } from './registration-draft.service';

const DRAFT_KEY = 'ukams_registration_draft';

class MemoryStorage {
  private readonly entries = new Map<string, string>();
  get length(): number {
    return this.entries.size;
  }
  clear(): void {
    this.entries.clear();
  }
  getItem(key: string): string | null {
    return this.entries.has(key) ? (this.entries.get(key) as string) : null;
  }
  key(index: number): string | null {
    return [...this.entries.keys()][index] ?? null;
  }
  removeItem(key: string): void {
    this.entries.delete(key);
  }
  setItem(key: string, value: string): void {
    this.entries.set(key, String(value));
  }
}

/** A payment-step-like form: fee fields sit at the root next to regular ones. */
function buildRegistrationForm(fb: FormBuilder): FormGroup {
  return fb.group({
    fullName: [''],
    mobile: [''],
    admissionFee: [''],
    subscription: [''],
    properties: fb.array([]),
    nominees: fb.array([]),
  });
}

describe('RegistrationDraftService fee-field exclusion (stale-fee regression)', () => {
  let service: RegistrationDraftService;
  let fb: FormBuilder;

  beforeEach(() => {
    Object.defineProperty(globalThis, 'localStorage', {
      value: new MemoryStorage(),
      configurable: true,
      writable: true,
    });
    vi.useFakeTimers();
    service = new RegistrationDraftService();
    fb = new FormBuilder();
  });

  afterEach(() => {
    service.unwatch();
    vi.useRealTimers();
  });

  it('never stores admissionFee/subscription in the saved draft', () => {
    const form = buildRegistrationForm(fb);
    form.patchValue({ fullName: 'A', admissionFee: '500', subscription: '120' });
    service.saveNow(form, 4);

    const draft = service.peekDraft()!;
    expect(draft).not.toBeNull();
    expect(draft.formValue).not.toHaveProperty('admissionFee');
    expect(draft.formValue).not.toHaveProperty('subscription');
    expect(draft.formValue['fullName']).toBe('A');
  });

  it('never restores admissionFee/subscription from a stale draft, but restores other fields', () => {
    // A draft written before fee fields were excluded from the payload.
    localStorage.setItem(
      DRAFT_KEY,
      JSON.stringify({
        schemaVersion: 1,
        currentStep: 4,
        lastSaved: '2026-09-01T00:00:00.000Z',
        formValue: {
          fullName: 'Stale Draft Holder',
          mobile: '01700000000',
          admissionFee: '300',
          subscription: '999',
          properties: [{ myShareQuantity: '3', applicableDocs: [] }],
        },
      }),
    );

    const form = buildRegistrationForm(fb);
    (form.get('properties') as FormArray).push(fb.group({ myShareQuantity: ['2'] }));
    const nominees = form.get('nominees') as FormArray;
    nominees.push(fb.group({ name: [''] }));

    const draft = service.peekDraft()!;
    service.restore(form, fb, draft);

    expect(form.get('fullName')!.value).toBe('Stale Draft Holder');
    expect(form.get('mobile')!.value).toBe('01700000000');
    // The live fee settings always win over the stale stored amounts.
    expect(form.get('admissionFee')!.value).toBe('');
    expect(form.get('subscription')!.value).toBe('');
    expect((form.get('properties') as FormArray).length).toBe(1);
    expect(nominees.length).toBe(1);
  });

  it('saving after a restore keeps the fee fields excluded', () => {
    localStorage.setItem(
      DRAFT_KEY,
      JSON.stringify({
        schemaVersion: 1,
        currentStep: 4,
        lastSaved: '2026-09-01T00:00:00.000Z',
        formValue: { fullName: 'X', admissionFee: '300', subscription: '999' },
      }),
    );
    const form = buildRegistrationForm(fb);
    (form.get('nominees') as FormArray).push(fb.group({ name: [''] }));
    service.restore(form, fb, service.peekDraft()!);

    // The step then loads the real fee values into the form.
    form.patchValue({ admissionFee: '500', subscription: '120' });
    service.saveNow(form, 4);

    const draft = service.peekDraft()!;
    expect(draft.formValue).not.toHaveProperty('admissionFee');
    expect(draft.formValue).not.toHaveProperty('subscription');
  });
});
