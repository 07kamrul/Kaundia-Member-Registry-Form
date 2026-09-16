import { Component, DestroyRef, Input, OnInit, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormArray, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { PAYMENT_METHODS } from '../../../../core/models/registration.model';
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

  selectMethod(method: string): void {
    this.form.get('paymentMethod')?.setValue(method);
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
