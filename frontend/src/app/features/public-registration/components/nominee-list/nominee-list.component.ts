import { Component, Input } from '@angular/core';
import { FormArray, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { buildNomineeGroup } from '../../registration-form.builder';
import { FormBuilder } from '@angular/forms';
import { TranslatePipe } from '@ngx-translate/core';

@Component({
  selector: 'app-nominee-list',
  standalone: true,
  imports: [ReactiveFormsModule, TranslatePipe],
  templateUrl: './nominee-list.component.html',
})
export class NomineeListComponent {
  @Input({ required: true }) form!: FormGroup;
  @Input({ required: true }) nominees!: FormArray;
  @Input() submitAttempted = false;

  sameAsUrgentContact = false;

  constructor(private fb: FormBuilder) {}

  group(index: number): FormGroup {
    return this.nominees.at(index) as FormGroup;
  }

  toggleSameAsUrgentContact(): void {
    this.sameAsUrgentContact = !this.sameAsUrgentContact;
    const nominee = this.group(0);

    if (this.sameAsUrgentContact) {
      nominee.patchValue({
        name: this.form.get('urgentContactName')?.value ?? '',
        relation: this.form.get('urgentContactRelation')?.value ?? '',
        mobile: this.form.get('urgentContactMobile')?.value ?? '',
        address: this.form.get('urgentContactAddress')?.value ?? '',
      });
      nominee.disable({ emitEvent: false });
    } else {
      nominee.enable({ emitEvent: false });
    }
  }

  showError(index: number, controlName: 'name' | 'mobile'): boolean {
    const control = this.group(index).get(controlName);
    return !!control && !control.value?.trim() && (control.touched || this.submitAttempted);
  }

  mobileInvalid(index: number): boolean {
    const control = this.group(index).get('mobile');
    return !!control && !!control.value?.trim() && control.invalid && (control.touched || this.submitAttempted);
  }

  addNominee(): void {
    if (this.nominees.length < 5) {
      this.nominees.push(buildNomineeGroup(this.fb));
    }
  }

  removeNominee(index: number): void {
    if (this.nominees.length > 1) {
      this.nominees.removeAt(index);
    }
  }
}
