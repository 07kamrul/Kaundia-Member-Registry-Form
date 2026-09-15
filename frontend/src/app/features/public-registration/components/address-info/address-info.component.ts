import { Component, Input } from '@angular/core';
import { FormGroup, ReactiveFormsModule } from '@angular/forms';

@Component({
  selector: 'app-address-info',
  standalone: true,
  imports: [ReactiveFormsModule],
  templateUrl: './address-info.component.html',
})
export class AddressInfoComponent {
  @Input({ required: true }) form!: FormGroup;
}
