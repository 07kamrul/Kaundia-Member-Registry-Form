import { Component, Input } from '@angular/core';
import { FormGroup, ReactiveFormsModule } from '@angular/forms';

@Component({
  selector: 'app-urgent-contact',
  standalone: true,
  imports: [ReactiveFormsModule],
  templateUrl: './urgent-contact.component.html',
})
export class UrgentContactComponent {
  @Input({ required: true }) form!: FormGroup;
}
