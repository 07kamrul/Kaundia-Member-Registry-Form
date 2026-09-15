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
  @Output() photoChange = new EventEmitter<Event>();
  @Output() photoClear = new EventEmitter<void>();
}
