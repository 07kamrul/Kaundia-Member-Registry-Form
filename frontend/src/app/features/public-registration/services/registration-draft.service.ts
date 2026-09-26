import { Injectable, signal } from '@angular/core';
import { FormArray, FormBuilder, FormGroup } from '@angular/forms';
import { debounceTime, Subscription } from 'rxjs';
import {
  applicableDocsArray,
  buildApplicableDocGroup,
  buildCoOwnerGroup,
  buildNomineeGroup,
  buildPropertyGroup,
  coOwnersArray,
  nomineesArray,
  propertiesArray,
} from '../registration-form.builder';

const DRAFT_KEY = 'ukams_registration_draft';
const DRAFT_SCHEMA_VERSION = 1;
const AUTOSAVE_DEBOUNCE_MS = 400;

export interface RegistrationDraft {
  schemaVersion: number;
  currentStep: number;
  lastSaved: string;
  formValue: Record<string, unknown>;
}

@Injectable({ providedIn: 'root' })
export class RegistrationDraftService {
  readonly lastSaved = signal<string | null>(null);

  private watchSubscription?: Subscription;

  /**
   * Wires debounced autosave to form value changes; call once per form instance.
   * Replaces any previous watcher so the old form (e.g. after discarding a
   * draft) stops being observed — the root-provided service would otherwise
   * keep every abandoned form subscription alive for the whole session.
   */
  watch(form: FormGroup, getCurrentStep: () => number): void {
    this.unwatch();
    this.watchSubscription = form.valueChanges
      .pipe(debounceTime(AUTOSAVE_DEBOUNCE_MS))
      .subscribe(() => this.save(form, getCurrentStep()));
  }

  /** Stops observing the currently watched form. */
  unwatch(): void {
    this.watchSubscription?.unsubscribe();
    this.watchSubscription = undefined;
  }

  saveNow(form: FormGroup, currentStep: number): void {
    this.save(form, currentStep);
  }

  private save(form: FormGroup, currentStep: number): void {
    const draft: RegistrationDraft = {
      schemaVersion: DRAFT_SCHEMA_VERSION,
      currentStep,
      lastSaved: new Date().toISOString(),
      formValue: form.getRawValue(),
    };
    try {
      localStorage.setItem(DRAFT_KEY, JSON.stringify(draft));
      this.lastSaved.set(draft.lastSaved);
    } catch {
      // localStorage unavailable (private browsing, storage disabled) — degrade silently.
    }
  }

  /** Returns the saved draft, or null if none exists, storage is unavailable, or its schema is stale. */
  peekDraft(): RegistrationDraft | null {
    try {
      const raw = localStorage.getItem(DRAFT_KEY);
      if (!raw) return null;
      const draft = JSON.parse(raw) as RegistrationDraft;
      if (draft.schemaVersion !== DRAFT_SCHEMA_VERSION || !draft.formValue) return null;
      return draft;
    } catch {
      return null;
    }
  }

  /** Rebuilds nested FormArrays to match the draft shape, then patches all values onto the form. */
  restore(form: FormGroup, fb: FormBuilder, draft: RegistrationDraft): void {
    const value = draft.formValue as Record<string, any>;

    const properties = propertiesArray(form);
    const draftProperties = Array.isArray(value['properties']) ? value['properties'] : [];
    properties.clear();
    draftProperties.forEach((draftProperty: Record<string, any>) => {
      const propertyGroup = buildPropertyGroup(fb);
      this.restorePropertyArrays(propertyGroup, fb, draftProperty);
      properties.push(propertyGroup);
    });

    const nominees = nomineesArray(form);
    const draftNominees = Array.isArray(value['nominees']) ? value['nominees'] : [];
    nominees.clear();
    draftNominees.forEach(() => nominees.push(buildNomineeGroup(fb)));
    if (nominees.length === 0) {
      nominees.push(buildNomineeGroup(fb));
    }

    form.patchValue(value);
    this.lastSaved.set(draft.lastSaved);
  }

  private restorePropertyArrays(
    propertyGroup: FormGroup,
    fb: FormBuilder,
    draftProperty: Record<string, any>,
  ): void {
    const coOwners: FormArray = coOwnersArray(propertyGroup);
    const draftCoOwners = Array.isArray(draftProperty['coOwners']) ? draftProperty['coOwners'] : [];
    draftCoOwners.forEach(() => coOwners.push(buildCoOwnerGroup(fb)));

    const applicableDocs: FormArray = applicableDocsArray(propertyGroup);
    const draftDocs = Array.isArray(draftProperty['applicableDocs'])
      ? draftProperty['applicableDocs']
      : [];
    draftDocs.forEach((doc: Record<string, any>) =>
      applicableDocs.push(buildApplicableDocGroup(fb, doc['type'] ?? '')),
    );
  }

  clear(): void {
    try {
      localStorage.removeItem(DRAFT_KEY);
    } catch {
      // localStorage unavailable — nothing to clear.
    }
    this.lastSaved.set(null);
  }
}
