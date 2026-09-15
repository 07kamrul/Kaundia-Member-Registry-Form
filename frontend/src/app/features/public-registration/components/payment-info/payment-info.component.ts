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
  readonly paymentMethods = PAYMENT_METHODS;

  selectMethod(method: string): void {
    this.form.get('paymentMethod')?.setValue(method);
  }
}
