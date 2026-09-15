import { Component, Input } from '@angular/core';
import { FormGroup, ReactiveFormsModule } from '@angular/forms';
import { PAYMENT_METHODS } from '../../../../core/models/registration.model';

@Component({
  selector: 'app-payment-info',
  standalone: true,
  imports: [ReactiveFormsModule],
  templateUrl: './payment-info.component.html',
})
export class PaymentInfoComponent {
  @Input({ required: true }) form!: FormGroup;
  @Input() submitAttempted = false;
  readonly paymentMethods = PAYMENT_METHODS;

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
