import { Component, DestroyRef, Input, OnInit, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormArray, FormGroup, ReactiveFormsModule } from '@angular/forms';
import {
  ALLOWED_DOC_MIME_TYPES,
  MAX_DOC_FILE_BYTES,
  ORG_BANK_INFO,
  ORG_MFS_INFO,
  PAYMENT_METHODS,
} from '../../../../core/models/registration.model';
import { propertiesArray } from '../../registration-form.builder';

const FIRST_DECIMAL_RATE = 50;
const ADDITIONAL_DECIMAL_RATE = 10;

export interface SubscriptionBreakdown {
  totalDecimal: number;
  additionalDecimal: number;
  additionalAmount: number;
  amount: number;
}

@Component({
  selector: 'app-payment-info',
  standalone: true,
  imports: [ReactiveFormsModule],
  templateUrl: './payment-info.component.html',
})
export class PaymentInfoComponent implements OnInit {
  @Input({ required: true }) form!: FormGroup;
  @Input() submitAttempted = false;
  readonly paymentMethods = PAYMENT_METHODS;
  readonly firstDecimalRate = FIRST_DECIMAL_RATE;
  readonly additionalDecimalRate = ADDITIONAL_DECIMAL_RATE;
  readonly subscriptionBreakdown = signal<SubscriptionBreakdown | null>(null);
  readonly maxReceiptFileMb = MAX_DOC_FILE_BYTES / (1024 * 1024);
  readonly bankInfo = ORG_BANK_INFO;
  readonly mfsInfo = ORG_MFS_INFO;
  receiptFileError = '';

  constructor(private destroyRef: DestroyRef) {}

  ngOnInit(): void {
    const properties = this.properties;
    this.recalculateSubscription(properties);
    properties.valueChanges
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe(() => this.recalculateSubscription(properties));
  }

  private get properties(): FormArray {
    return propertiesArray(this.form);
  }

  private recalculateSubscription(properties: FormArray): void {
    const totalDecimal = properties.controls.reduce((sum, property) => {
      const value = parseFloat(property.get('landQuantity')?.value);
      return sum + (Number.isFinite(value) && value > 0 ? value : 0);
    }, 0);

    if (totalDecimal <= 0) {
      this.subscriptionBreakdown.set(null);
      return;
    }

    const additionalDecimal = totalDecimal - 1;
    const additionalAmount = additionalDecimal * ADDITIONAL_DECIMAL_RATE;
    const amount = FIRST_DECIMAL_RATE + additionalAmount;

    this.subscriptionBreakdown.set({
      totalDecimal,
      additionalDecimal,
      additionalAmount,
      amount,
    });
    this.form.get('subscription')?.setValue(amount, { emitEvent: false });
  }

  onReceiptFileChange(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    input.value = '';
    if (!file) return;

    if (!ALLOWED_DOC_MIME_TYPES.includes(file.type)) {
      this.receiptFileError = 'শুধুমাত্র JPG, PNG বা PDF ফাইল গ্রহণযোগ্য';
      return;
    }
    if (file.size > MAX_DOC_FILE_BYTES) {
      this.receiptFileError = `ফাইলের সাইজ সর্বোচ্চ ${this.maxReceiptFileMb} এমবি হতে হবে`;
      return;
    }
    this.receiptFileError = '';

    const reader = new FileReader();
    reader.onload = () => {
      this.form.patchValue({
        receiptFileName: file.name,
        receiptFileDataUrl: reader.result as string,
      });
    };
    reader.readAsDataURL(file);
  }

  removeReceiptFile(): void {
    this.form.patchValue({ receiptFileName: '', receiptFileDataUrl: '' });
  }

  selectMethod(method: string): void {
    this.form.get('paymentMethod')?.setValue(method);
  }

  get isBankSelected(): boolean {
    return this.form.get('paymentMethod')?.value === PAYMENT_METHODS[1];
  }

  get isMfsSelected(): boolean {
    return this.form.get('paymentMethod')?.value === PAYMENT_METHODS[2];
  }

  showError(controlName: string): boolean {
    const control = this.form.get(controlName);
    return !!control && control.invalid && (control.touched || this.submitAttempted);
  }

  errorMessage(controlName: string): string {
    const messages: Record<string, string> = {
      admissionFee: 'ভর্তি ফি আবশ্যক',
      subscription: 'চাঁদা আবশ্যক',
      paymentMethod: 'পেমেন্ট মাধ্যম আবশ্যক',
    };
    return messages[controlName] ?? '';
  }
}
