import { Component, EventEmitter, Input, Output } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';

@Component({
  selector: 'app-confirm-modal',
  standalone: true,
  templateUrl: './confirm-modal.component.html',
})
export class ConfirmModalComponent {
  @Input() open = false;
  @Input() title = '';
  @Input() message = '';
  @Input() confirmLabel = '';
  @Input() cancelLabel = '';
  @Input() danger = false;
  @Input() confirmDisabled = false;

  @Output() confirm = new EventEmitter<void>();
  @Output() cancel = new EventEmitter<void>();

  constructor(private translate: TranslateService) {}

  get resolvedConfirmLabel(): string {
    return this.confirmLabel || this.translate.instant('common.confirmModal.confirmButton');
  }

  get resolvedCancelLabel(): string {
    return this.cancelLabel || this.translate.instant('common.confirmModal.cancelButton');
  }

  onBackdropClick(event: MouseEvent): void {
    if (event.target === event.currentTarget) {
      this.cancel.emit();
    }
  }
}
