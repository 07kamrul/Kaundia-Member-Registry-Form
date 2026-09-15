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

  constructor(private fb: FormBuilder) {}

  group(index: number): FormGroup {
    return this.nominees.at(index) as FormGroup;
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
