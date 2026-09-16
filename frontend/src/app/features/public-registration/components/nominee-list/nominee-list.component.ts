import { Component, Input } from '@angular/core';
import { FormArray, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { buildNomineeGroup } from '../../registration-form.builder';
import { FormBuilder } from '@angular/forms';

@Component({
  selector: 'app-nominee-list',
  standalone: true,
  imports: [ReactiveFormsModule],
  templateUrl: './nominee-list.component.html',
})
export class NomineeListComponent {
  @Input({ required: true }) nominees!: FormArray;
  @Input() submitAttempted = false;

  constructor(private fb: FormBuilder) {}

  group(index: number): FormGroup {
    return this.nominees.at(index) as FormGroup;
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
