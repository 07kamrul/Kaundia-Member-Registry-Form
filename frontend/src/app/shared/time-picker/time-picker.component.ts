import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  EventEmitter,
  Input,
  Output,
  ViewChild,
} from '@angular/core';
import { CommonModule } from '@angular/common';

/**
 * Reusable time picker wrapping a native <input type="time">.
 *
 * - Value/output is always "HH:mm" (24h) or '' when empty.
 * - Display is formatted as "03:30 PM" via Intl.DateTimeFormat.
 * - Same @Input/@Output shape as DatePickerComponent so the two can be
 *   composed side by side for combined date+time fields.
 */
@Component({
  selector: 'app-time-picker',
  standalone: true,
  imports: [CommonModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './time-picker.component.html',
  styleUrl: './time-picker.component.scss',
})
export class TimePickerComponent {
  @Input() value = '';
  @Input() placeholder = 'Select time';
  @Input() disabled = false;
  @Input() clearable = false;
  @Input() invalid = false;
  @Input() errorMessage = '';
  @Input() inputId = '';

  @Output() valueChange = new EventEmitter<string>();

  @ViewChild('nativeInput') nativeInput?: ElementRef<HTMLInputElement>;

  get displayValue(): string {
    if (!this.value) {
      return '';
    }
    const [hours, minutes] = this.value.split(':').map((part) => Number(part));
    if (Number.isNaN(hours) || Number.isNaN(minutes)) {
      return '';
    }
    const reference = new Date();
    reference.setHours(hours, minutes, 0, 0);
    return new Intl.DateTimeFormat(undefined, {
      hour: '2-digit',
      minute: '2-digit',
    }).format(reference);
  }

  onNativeChange(event: Event): void {
    const target = event.target as HTMLInputElement;
    this.valueChange.emit(target.value);
  }

  openPicker(): void {
    const input = this.nativeInput?.nativeElement;
    if (!input || this.disabled) {
      return;
    }
    const supportsShowPicker =
      typeof (input as { showPicker?: () => void }).showPicker === 'function';
    if (supportsShowPicker) {
      try {
        (input as unknown as { showPicker: () => void }).showPicker();
        return;
      } catch {
        // Fall back to focus below.
      }
    }
    input.focus();
  }

  clear(event: MouseEvent): void {
    event.stopPropagation();
    this.valueChange.emit('');
  }

  onKeydown(event: KeyboardEvent): void {
    if (event.key === 'Tab' || event.key === 'Escape' || event.key === 'Shift') {
      return;
    }
    event.preventDefault();
  }
}
