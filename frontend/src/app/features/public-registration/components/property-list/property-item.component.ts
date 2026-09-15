import { Component, EventEmitter, Input, Output } from '@angular/core';
import { FormArray, FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import {
  ALLOWED_DOC_MIME_TYPES,
  DOCUMENT_OPTIONS,
  MAX_DOC_FILE_BYTES,
  OWNERSHIP_TYPES,
  PROPERTY_TYPES,
} from '../../../../core/models/registration.model';
import {
  buildApplicableDocGroup,
  buildCoOwnerGroup,
  coOwnersArray,
  applicableDocsArray,
} from '../../registration-form.builder';

@Component({
  selector: 'app-property-item',
  standalone: true,
  imports: [ReactiveFormsModule],
  templateUrl: './property-item.component.html',
})
export class PropertyItemComponent {
  @Input({ required: true }) property!: FormGroup;
  @Input({ required: true }) index = 0;
  @Input() submitAttempted = false;
  @Output() removeProperty = new EventEmitter<void>();

  readonly propertyTypes = PROPERTY_TYPES;
  readonly ownershipTypes = OWNERSHIP_TYPES;
  readonly documentOptions = DOCUMENT_OPTIONS;
  readonly maxDocFileMb = MAX_DOC_FILE_BYTES / (1024 * 1024);
  docFileErrors: Record<string, string> = {};

  constructor(private fb: FormBuilder) {}

  get coOwners(): FormArray {
    return coOwnersArray(this.property);
  }

  get applicableDocs(): FormArray {
    return applicableDocsArray(this.property);
  }

  coOwnerGroup(i: number): FormGroup {
    return this.coOwners.at(i) as FormGroup;
  }

  isTypeChecked(type: string): boolean {
    return (this.property.get('propertyType')?.value as string[]).includes(type);
  }

  toggleType(type: string): void {
    const current = this.property.get('propertyType')?.value as string[];
    const next = current.includes(type)
      ? current.filter((t) => t !== type)
      : [...current, type];
    this.property.get('propertyType')?.setValue(next);
  }

  setOwnership(ownership: string): void {
    this.property.get('ownership')?.setValue(ownership);
    if (ownership === 'যৌথ') {
      if (this.coOwners.length === 0) {
        this.coOwners.push(buildCoOwnerGroup(this.fb));
      }
    } else {
      this.coOwners.clear();
    }
  }

  addCoOwner(): void {
    this.coOwners.push(buildCoOwnerGroup(this.fb));
  }

  removeCoOwner(i: number): void {
    this.coOwners.removeAt(i);
  }

  findDocEntry(type: string): FormGroup | undefined {
    return this.applicableDocs.controls.find(
      (c) => c.get('type')?.value === type,
    ) as FormGroup | undefined;
  }

  isDocChecked(type: string): boolean {
    return !!this.findDocEntry(type);
  }

  toggleDoc(type: string): void {
    const existingIndex = this.applicableDocs.controls.findIndex(
      (c) => c.get('type')?.value === type,
    );
    if (existingIndex >= 0) {
      this.applicableDocs.removeAt(existingIndex);
      delete this.docFileErrors[type];
    } else {
      this.applicableDocs.push(buildApplicableDocGroup(this.fb, type));
    }
  }

  onDocFileChange(type: string, event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    input.value = '';
    if (!file) return;

    if (!ALLOWED_DOC_MIME_TYPES.includes(file.type)) {
      this.docFileErrors = {
        ...this.docFileErrors,
        [type]: 'শুধুমাত্র JPG, PNG বা PDF ফাইল গ্রহণযোগ্য',
      };
      return;
    }
    if (file.size > MAX_DOC_FILE_BYTES) {
      this.docFileErrors = {
        ...this.docFileErrors,
        [type]: `ফাইলের সাইজ সর্বোচ্চ ${this.maxDocFileMb} এমবি হতে হবে`,
      };
      return;
    }
    const { [type]: _removed, ...rest } = this.docFileErrors;
    this.docFileErrors = rest;

    const reader = new FileReader();
    reader.onload = () => {
      const group = this.findDocEntry(type);
      group?.patchValue({ fileName: file.name, fileDataUrl: reader.result as string });
    };
    reader.readAsDataURL(file);
  }

  removeDocFile(type: string): void {
    const group = this.findDocEntry(type);
    group?.patchValue({ fileName: '', fileDataUrl: '' });
  }

  isDocMissing(type: string): boolean {
    const entry = this.findDocEntry(type);
    return this.submitAttempted && !!entry && !entry.get('fileDataUrl')?.value;
  }

  showPropertyTypeError(): boolean {
    const value = this.property.get('propertyType')?.value as string[];
    return this.submitAttempted && (!value || value.length === 0);
  }

  showOwnershipError(): boolean {
    return this.submitAttempted && !this.property.get('ownership')?.value;
  }

  showCoOwnerError(controlName: 'ownerName' | 'ownerPhone', index: number): boolean {
    const control = this.coOwnerGroup(index).get(controlName);
    return this.submitAttempted && !control?.value?.trim();
  }
}
