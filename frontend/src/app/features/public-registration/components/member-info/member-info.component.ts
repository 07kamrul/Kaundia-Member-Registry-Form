import { Component, EventEmitter, Input, Output, ChangeDetectionStrategy } from '@angular/core';
import { FormGroup, ReactiveFormsModule } from '@angular/forms';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';

@Component({
  selector: 'app-member-info',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule, TranslatePipe],
  templateUrl: './member-info.component.html',
})
export class MemberInfoComponent {
  @Input({ required: true }) form!: FormGroup;
  @Input() memberPhotoPreview = '';
  @Input() submitAttempted = false;
  @Output() photoChange = new EventEmitter<Event>();
  @Output() photoClear = new EventEmitter<void>();

  constructor(private translate: TranslateService) {}

  showError(controlName: string): boolean {
    const control = this.form.get(controlName);
    return !!control && control.invalid && (control.touched || this.submitAttempted);
  }

  errorMessage(controlName: string): string {
    const control = this.form.get(controlName);
    const messageKeys: Record<string, string> = {
      fullName: 'registration.memberInfo.fullNameRequired',
      fatherOrHusband: 'registration.memberInfo.fatherOrHusbandRequired',
      mother: 'registration.memberInfo.motherRequired',
      dob: 'registration.memberInfo.dobRequired',
      gender: 'registration.memberInfo.genderRequired',
      memberPhoto: 'registration.memberInfo.memberPhotoRequired',
    };

    if (controlName === 'mobile') {
      return this.translate.instant(
        control?.errors?.['required']
          ? 'registration.memberInfo.mobileRequired'
          : 'registration.memberInfo.mobileInvalid',
      );
    }

    if (controlName === 'email') {
      return this.translate.instant(
        control?.errors?.['required']
          ? 'registration.memberInfo.emailRequired'
          : 'registration.memberInfo.emailInvalid',
      );
    }

    if (controlName === 'nid') {
      return this.translate.instant(
        control?.errors?.['required']
          ? 'registration.memberInfo.nidRequired'
          : 'registration.memberInfo.nidInvalid',
      );
    }

    const key = messageKeys[controlName];
    return key ? this.translate.instant(key) : '';
  }
}
