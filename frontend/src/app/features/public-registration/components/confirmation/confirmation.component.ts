import { Component, EventEmitter, Input, Output } from '@angular/core';
import { TranslatePipe } from '@ngx-translate/core';

@Component({
  selector: 'app-confirmation',
  standalone: true,
  imports: [TranslatePipe],
  templateUrl: './confirmation.component.html',
})
export class ConfirmationComponent {
  @Input({ required: true }) submissionId!: string;
  @Output() acknowledge = new EventEmitter<void>();
}
