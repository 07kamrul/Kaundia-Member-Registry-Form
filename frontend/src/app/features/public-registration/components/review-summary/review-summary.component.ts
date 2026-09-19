import { Component, EventEmitter, Input, Output } from '@angular/core';
import { FormArray, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { TranslatePipe } from '@ngx-translate/core';

@Component({
  selector: 'app-review-summary',
  standalone: true,
  imports: [ReactiveFormsModule, TranslatePipe],
  templateUrl: './review-summary.component.html',
})
export class ReviewSummaryComponent {
  @Input({ required: true }) form!: FormGroup;
  @Output() editStep = new EventEmitter<number>();

  get properties(): FormArray {
    return this.form.get('properties') as FormArray;
  }

  get nominees(): FormArray {
    return this.form.get('nominees') as FormArray;
  }

  goTo(step: number): void {
    this.editStep.emit(step);
  }
}
