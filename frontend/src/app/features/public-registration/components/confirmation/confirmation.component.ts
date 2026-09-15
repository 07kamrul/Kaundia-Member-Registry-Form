import { Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
  selector: 'app-confirmation',
  standalone: true,
  templateUrl: './confirmation.component.html',
})
export class ConfirmationComponent {
  @Input({ required: true }) submissionId!: string;
  @Input({ required: true }) fullName!: string;
  @Output() reset = new EventEmitter<void>();
}
