import { Component, EventEmitter, Input, Output } from '@angular/core';
import { FormGroup, ReactiveFormsModule } from '@angular/forms';

@Component({
  selector: 'app-member-info',
  standalone: true,
  imports: [ReactiveFormsModule],
  templateUrl: './member-info.component.html',
})
export class MemberInfoComponent {
  @Input({ required: true }) form!: FormGroup;
  @Input() memberPhotoPreview = '';
  @Input() submitAttempted = false;
  @Output() photoChange = new EventEmitter<Event>();
  @Output() photoClear = new EventEmitter<void>();

  showError(controlName: string): boolean {
    const control = this.form.get(controlName);
    return !!control && control.invalid && (control.touched || this.submitAttempted);
  }

  errorMessage(controlName: string): string {
    const control = this.form.get(controlName);
    const messages: Record<string, string> = {
      fullName: 'পূর্ণ নাম আবশ্যক',
      fatherOrHusband: 'পিতা/স্বামী আবশ্যক',
      mother: 'মাতা আবশ্যক',
      dob: 'জন্ম তারিখ আবশ্যক',
      email: 'ই-মেইল সঠিক নয়',
      nid: 'NID নম্বর ১০-১৭ সংখ্যার হতে হবে',
    };

    if (controlName === 'mobile') {
      return control?.errors?.['required'] ? 'মোবাইল আবশ্যক' : 'মোবাইল নম্বর সঠিক নয় (01XXXXXXXXX)';
    }

    return messages[controlName] ?? '';
  }
}
