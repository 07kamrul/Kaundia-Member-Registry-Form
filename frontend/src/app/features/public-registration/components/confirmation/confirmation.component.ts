import { Component, EventEmitter, Input, Output, ChangeDetectionStrategy } from '@angular/core';
import { TranslatePipe } from '@ngx-translate/core';

@Component({
  selector: 'app-confirmation',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe],
  templateUrl: './confirmation.component.html',
})
export class ConfirmationComponent {
  @Input({ required: true }) submissionId!: string;
  @Output() acknowledge = new EventEmitter<void>();
}
