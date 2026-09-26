import { FormBuilder, FormGroup } from '@angular/forms';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { RegistrationDraftService } from './registration-draft.service';

const DRAFT_KEY = 'ukams_registration_draft';

/** Minimal Storage implementation — the test runner's `localStorage` is a stub. */
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

describe('RegistrationDraftService', () => {
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

  it('autosaves a watched form after the debounce window', () => {
    const form: FormGroup = fb.group({ fullName: [''] });
    service.watch(form, () => 2);

    form.get('fullName')!.setValue('A');
    expect(localStorage.getItem(DRAFT_KEY)).toBeNull();

    vi.advanceTimersByTime(500);

    const draft = service.peekDraft();
    expect(draft).not.toBeNull();
    expect(draft!.currentStep).toBe(2);
    expect(draft!.formValue).toEqual({ fullName: 'A' });
    expect(service.lastSaved()).toBe(draft!.lastSaved);
  });

  it('stops observing a form after unwatch(), so abandoned forms never write drafts', () => {
    const watched: FormGroup = fb.group({ fullName: [''] });
    const abandoned: FormGroup = fb.group({ fullName: [''] });

    service.watch(watched, () => 1);
    service.unwatch();
    service.watch(abandoned, () => 1);

    // The replaced watcher must be fully detached: flipping its value after
    // the debounce window must not resurrect a draft for the old form.
    service.unwatch();
    watched.get('fullName')!.setValue('leaked');
    vi.advanceTimersByTime(1000);
    expect(localStorage.getItem(DRAFT_KEY)).toBeNull();
  });

  it('replaces the previous watcher instead of stacking them', () => {
    const first: FormGroup = fb.group({ fullName: [''] });
    const second: FormGroup = fb.group({ fullName: [''] });

    service.watch(first, () => 1);
    service.watch(second, () => 5);

    first.get('fullName')!.setValue('ignored');
    second.get('fullName')!.setValue('kept');

    vi.advanceTimersByTime(1000);

    const draft = service.peekDraft();
    expect(draft).not.toBeNull();
    expect(draft!.currentStep).toBe(5);
    expect(draft!.formValue).toEqual({ fullName: 'kept' });
  });

  it('clears the stored draft and the lastSaved signal', () => {
    const form: FormGroup = fb.group({ fullName: [''] });
    service.watch(form, () => 1);
    form.get('fullName')!.setValue('A');
    vi.advanceTimersByTime(500);
    expect(service.peekDraft()).not.toBeNull();

    service.clear();
    expect(localStorage.getItem(DRAFT_KEY)).toBeNull();
    expect(service.lastSaved()).toBeNull();
  });
});
