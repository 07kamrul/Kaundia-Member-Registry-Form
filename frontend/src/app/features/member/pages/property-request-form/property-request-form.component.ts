import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  OnInit,
  inject,
} from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import {
  ALLOWED_DOC_MIME_TYPES,
  DOCUMENT_OPTIONS,
  OWNERSHIP_TYPES,
  PROPERTY_TYPES,
} from '../../../../core/models/registration.model';
import {
  MemberService,
  type MemberProfile,
  type MemberProperty,
} from '../../../../core/services/member.service';
import { ConfigListService } from '../../../../core/services/config-list.service';
import { IconComponent } from '../../../../shared/icon/icon.component';

interface ExistingDocRow {
  docType: string;
  filePath?: string;
  keep: boolean;
}

interface NewDocRow {
  docType: string;
  file: File | null;
  error: string;
}

interface CoOwnerRow {
  ownerName: string;
  ownerPhone: string;
}

// The backend caps request doc uploads at 10 MB (JPG/PNG/PDF).
const MAX_DOC_FILE_BYTES = 10 * 1024 * 1024;

@Component({
  selector: 'app-property-request-form',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, IconComponent, TranslatePipe],
  templateUrl: './property-request-form.component.html',
  styleUrl: './property-request-form.component.scss',
})
export class PropertyRequestFormComponent implements OnInit {
  mode: 'add' | 'edit' = 'add';
  propertyId: number | null = null;
  loading = false;
  error = '';
  submitAttempted = false;
  submitting = false;
  submitError = '';
  submitted = false;

  propertyTypes: string[] = PROPERTY_TYPES;
  readonly ownershipTypes = OWNERSHIP_TYPES;
  readonly documentOptions = DOCUMENT_OPTIONS;
  readonly maxDocFileMb = MAX_DOC_FILE_BYTES / (1024 * 1024);

  propertyType: string[] = [];
  propertyTypeOther = '';
  khatianNo = '';
  dagNoCs = '';
  dagNoRs = '';
  holdingNumber = '';
  landQuantity = '';
  myShareQuantity = '';
  ownership = '';
  coOwners: CoOwnerRow[] = [];
  /** Existing property docs (edit mode): kept by default via keep checkbox. */
  existingDocs: ExistingDocRow[] = [];
  /** Docs the member wants to attach with this request (File objects). */
  newDocs: NewDocRow[] = [];

  private readonly cdr = inject(ChangeDetectorRef);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly memberService = inject(MemberService);
  private readonly configListService = inject(ConfigListService);
  private readonly translate = inject(TranslateService);

  ngOnInit(): void {
    const rawId = this.route.snapshot.paramMap.get('propertyId');
    if (rawId) {
      this.mode = 'edit';
      this.propertyId = Number(rawId);
      this.loadProperty();
    }
    this.configListService.getValues('property_type', PROPERTY_TYPES).subscribe((values) => {
      this.propertyTypes = values;
      this.cdr.markForCheck();
    });
  }

  private loadProperty(): void {
    this.loading = true;
    this.memberService.getProfile().subscribe({
      next: (profile: MemberProfile) => {
        const property = profile.properties.find((p) => p.id === this.propertyId) ?? null;
        if (!property) {
          this.error = this.translate.instant('member.propertyRequests.errors.propertyNotFound');
        } else {
          this.prefill(property);
        }
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('member.profile.loadError');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  private prefill(property: MemberProperty): void {
    this.propertyType = [...property.propertyType];
    this.propertyTypeOther = property.propertyTypeOther ?? '';
    this.khatianNo = property.khatianNo ?? '';
    this.dagNoCs = property.dagNoCs ?? '';
    this.dagNoRs = property.dagNoRs ?? '';
    this.holdingNumber = property.holdingNumber ?? '';
    this.landQuantity = property.landQuantity ?? '';
    this.myShareQuantity = property.myShareQuantity ?? '';
    this.ownership = property.ownership ?? '';
    this.coOwners = property.coOwners.map((c) => ({
      ownerName: c.ownerName,
      ownerPhone: c.ownerPhone,
    }));
    this.existingDocs = property.applicableDocs.map((d) => ({
      docType: d.docType,
      filePath: d.filePath,
      keep: true,
    }));
  }

  /* ---------- property type ---------- */

  isTypeChecked(type: string): boolean {
    return this.propertyType.includes(type);
  }

  toggleType(type: string): void {
    this.propertyType = this.propertyType.includes(type)
      ? this.propertyType.filter((t) => t !== type)
      : [...this.propertyType, type];
  }

  /* ---------- co-owners ---------- */

  addCoOwner(): void {
    this.coOwners = [...this.coOwners, { ownerName: '', ownerPhone: '' }];
  }

  removeCoOwner(index: number): void {
    this.coOwners = this.coOwners.filter((_, i) => i !== index);
  }

  /* ---------- docs ---------- */

  addNewDoc(): void {
    this.newDocs = [...this.newDocs, { docType: '', file: null, error: '' }];
  }

  removeNewDoc(index: number): void {
    this.newDocs = this.newDocs.filter((_, i) => i !== index);
  }

  onNewDocFileChange(index: number, event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    input.value = '';
    if (!file) return;
    const error = this.validateDocFile(file);
    this.newDocs = this.newDocs.map((row, i) =>
      i === index ? { ...row, file: error ? null : file, error } : row,
    );
  }

  private validateDocFile(file: File): string {
    if (!ALLOWED_DOC_MIME_TYPES.includes(file.type)) {
      return this.translate.instant('registration.property.docFileTypeError');
    }
    if (file.size > MAX_DOC_FILE_BYTES) {
      return this.translate.instant('registration.property.docFileSizeError', {
        maxMb: this.maxDocFileMb,
      });
    }
    return '';
  }

  hasDocErrors(): boolean {
    return this.newDocs.some((row) => !row.docType || !row.file || !!row.error);
  }

  /* ---------- validation ---------- */

  isPositive(value: string): boolean {
    return /^\d+(\.\d+)?$/.test(value.trim()) && Number(value) > 0;
  }

  showPropertyTypeError(): boolean {
    return this.submitAttempted && this.propertyType.length === 0;
  }

  showKhatianNoError(): boolean {
    return this.submitAttempted && !this.khatianNo.trim();
  }

  showDagNoError(which: 'cs' | 'rs'): boolean {
    const value = which === 'cs' ? this.dagNoCs : this.dagNoRs;
    return this.submitAttempted && !value.trim();
  }

  showLandQuantityError(): boolean {
    return this.submitAttempted && !this.landQuantity.trim();
  }

  showLandQuantityInvalidError(): boolean {
    return (
      this.submitAttempted && !!this.landQuantity.trim() && !this.isPositive(this.landQuantity)
    );
  }

  showMyShareQuantityError(): boolean {
    return this.submitAttempted && !this.myShareQuantity.trim();
  }

  showMyShareQuantityInvalidError(): boolean {
    return (
      this.submitAttempted &&
      !!this.myShareQuantity.trim() &&
      !this.isPositive(this.myShareQuantity)
    );
  }

  showOwnershipError(): boolean {
    return this.submitAttempted && !this.ownership;
  }

  showCoOwnersError(): boolean {
    return (
      this.ownership === 'যৌথ' &&
      this.submitAttempted &&
      this.coOwners.some((c) => !c.ownerName.trim())
    );
  }

  /* ---------- submit ---------- */

  submit(): void {
    this.submitAttempted = true;
    this.submitError = '';
    if (
      this.showPropertyTypeError() ||
      this.showKhatianNoError() ||
      this.showDagNoError('cs') ||
      this.showDagNoError('rs') ||
      this.showLandQuantityError() ||
      this.showLandQuantityInvalidError() ||
      this.showMyShareQuantityError() ||
      this.showMyShareQuantityInvalidError() ||
      this.showOwnershipError() ||
      this.showCoOwnersError() ||
      this.hasDocErrors()
    ) {
      return;
    }

    const docs = [
      ...this.existingDocs
        .filter((row) => row.keep && row.filePath)
        .map((row) => ({ docType: row.docType, keepPath: row.filePath as string })),
      ...this.newDocs.map((row) => ({ docType: row.docType, keepPath: null })),
    ];
    const newDocFiles = this.newDocs.map((row) => row.file as File);

    this.submitting = true;
    this.memberService
      .createPropertyRequest({
        action: this.mode === 'edit' ? 'edit' : 'add',
        propertyId: this.mode === 'edit' && this.propertyId ? this.propertyId : undefined,
        payload: {
          propertyType: this.propertyType,
          propertyTypeOther: this.propertyTypeOther.trim() || null,
          khatianNo: this.khatianNo.trim(),
          dagNoCs: this.dagNoCs.trim(),
          dagNoRs: this.dagNoRs.trim(),
          holdingNumber: this.holdingNumber.trim(),
          landQuantity: this.landQuantity.trim(),
          myShareQuantity: this.myShareQuantity.trim(),
          ownership: this.ownership,
          coOwners: this.coOwners
            .filter((c) => c.ownerName.trim())
            .map((c) => ({ ownerName: c.ownerName.trim(), ownerPhone: c.ownerPhone.trim() })),
          docs,
        },
        newDocFiles,
      })
      .subscribe({
        next: () => {
          this.submitted = true;
          this.submitting = false;
          this.cdr.markForCheck();
          // Let the "request sent" confirmation register before leaving.
          setTimeout(() => this.router.navigate(['/profile']), 1200);
        },
        error: (err) => {
          this.submitting = false;
          const detail = typeof err?.error?.detail === 'string' ? err.error.detail : '';
          this.submitError =
            detail || this.translate.instant('member.propertyRequests.errors.submitFailed');
          this.cdr.markForCheck();
        },
      });
  }

  backToProfile(): void {
    this.router.navigate(['/profile']);
  }
}
