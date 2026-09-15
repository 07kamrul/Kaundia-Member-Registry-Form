import { Component, DestroyRef, inject, Input, OnInit } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormControl, FormGroup, ReactiveFormsModule } from '@angular/forms';

const ADDRESS_FIELD_ERROR_MESSAGES: Record<string, string> = {
  district: 'জেলা আবশ্যক',
  upazila: 'উপজেলা/থানা আবশ্যক',
  postOffice: 'ডাকঘর আবশ্যক',
  road: 'রাস্তা/গ্রাম আবশ্যক',
  house: 'বাসা/হোল্ডিং নং আবশ্যক',
};

@Component({
  selector: 'app-address-info',
  standalone: true,
  imports: [ReactiveFormsModule],
  templateUrl: './address-info.component.html',
})
export class AddressInfoComponent implements OnInit {
  @Input({ required: true }) form!: FormGroup;
  @Input() submitAttempted = false;

  private readonly destroyRef = inject(DestroyRef);

  sameAsCurrentAddress = new FormControl(false);

  ngOnInit(): void {
    this.sameAsCurrentAddress.valueChanges
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe((isSame) => this.applySameAsCurrentAddress(isSame ?? false));

    this.currentAddressGroup.valueChanges
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe(() => {
        if (this.sameAsCurrentAddress.value) {
          this.copyCurrentAddressToPermanent();
        }
      });
  }

  private get currentAddressGroup(): FormGroup {
    return this.form.get('currentAddress') as FormGroup;
  }

  private get permanentAddressGroup(): FormGroup {
    return this.form.get('permanentAddress') as FormGroup;
  }

  private applySameAsCurrentAddress(isSame: boolean): void {
    if (isSame) {
      this.copyCurrentAddressToPermanent();
      this.permanentAddressGroup.disable({ emitEvent: false });
    } else {
      this.permanentAddressGroup.enable({ emitEvent: false });
    }
  }

  private copyCurrentAddressToPermanent(): void {
    this.permanentAddressGroup.patchValue(this.currentAddressGroup.value, { emitEvent: false });
  }

  showError(groupName: 'currentAddress' | 'permanentAddress', controlName: string): boolean {
    const control = this.form.get(`${groupName}.${controlName}`);
    return !!control && control.invalid && (control.touched || this.submitAttempted);
  }

  errorMessage(controlName: string): string {
    return ADDRESS_FIELD_ERROR_MESSAGES[controlName] ?? '';
  }
}
