import { Component, Input } from '@angular/core';
import { FormArray, FormBuilder, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { MAX_PROPERTY_COUNT } from '../../../../core/models/registration.model';
import { buildPropertyGroup } from '../../registration-form.builder';
import { PropertyItemComponent } from './property-item.component';

@Component({
  selector: 'app-property-list',
  standalone: true,
  imports: [ReactiveFormsModule, PropertyItemComponent],
  templateUrl: './property-list.component.html',
})
export class PropertyListComponent {
  @Input({ required: true }) form!: FormGroup;
  @Input({ required: true }) properties!: FormArray;
  @Input() submitAttempted = false;

  readonly propertyCounts = Array.from({ length: MAX_PROPERTY_COUNT }, (_, i) => i + 1);

  constructor(private fb: FormBuilder) {}

  onCountChange(event: Event): void {
    const count = Number((event.target as HTMLSelectElement).value) || 0;
    this.form.get('propertyCount')?.setValue(count);
    while (this.properties.length < count) {
      this.properties.push(buildPropertyGroup(this.fb));
    }
    while (this.properties.length > count) {
      this.properties.removeAt(this.properties.length - 1);
    }
  }

  propertyGroup(i: number): FormGroup {
    return this.properties.at(i) as FormGroup;
  }
}
