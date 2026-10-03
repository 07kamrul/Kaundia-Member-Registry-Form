import { Component, Input, ChangeDetectionStrategy } from '@angular/core';
import { FormGroup, ReactiveFormsModule } from '@angular/forms';
import { TranslatePipe } from '@ngx-translate/core';
import { PhoneInputComponent } from '../../../../shared/phone-input/phone-input.component';

@Component({
  selector: 'app-urgent-contact',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, TranslatePipe, PhoneInputComponent],
  templateUrl: './urgent-contact.component.html',
})
export class UrgentContactComponent {
  @Input({ required: true }) form!: FormGroup;
  @Input() submitAttempted = false;

  showError(controlName: string): boolean {
    const control = this.form.get(controlName);
    return !!control && !control.value?.trim() && (control.touched || this.submitAttempted);
  }

  mobileInvalid(): boolean {
    const control = this.form.get('urgentContactMobile');
    return (
      !!control &&
      !!control.value?.trim() &&
      control.invalid &&
      (control.touched || this.submitAttempted)
    );
  }
}
