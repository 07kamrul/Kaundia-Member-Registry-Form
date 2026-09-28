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
 * Reusable date picker wrapping a native <input type="date">.
 *
 * - Value/output is always an ISO date string ("yyyy-MM-dd") or '' when empty.
 * - The visible text is read-only to typing; clicking/focusing opens the
 *   native picker via showPicker() when supported, falling back to normal
 *   focus behavior otherwise.
 * - Exposes [value]/(valueChange) rather than ControlValueAccessor, matching
 *   the @Input/@Output pattern already used by shared/confirm-modal.
 */
@Component({
  selector: 'app-date-picker',
  standalone: true,
  imports: [CommonModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './date-picker.component.html',
  styleUrl: './date-picker.component.scss',
})
export class DatePickerComponent {
  @Input() value = '';
  @Input() min?: string;
  @Input() max?: string;
  @Input() placeholder = 'Select date';
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
    const parsed = new Date(`${this.value}T00:00:00`);
    if (Number.isNaN(parsed.getTime())) {
      return '';
    }
    return new Intl.DateTimeFormat(undefined, {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    }).format(parsed);
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
        // Some browsers throw if the input isn't user-activated/visible; fall back below.
      }
    }
    input.focus();
  }

  clear(event: MouseEvent): void {
    event.stopPropagation();
    this.valueChange.emit('');
  }

  onKeydown(event: KeyboardEvent): void {
    // Block manual character entry; the field is picker-only. Allow Tab/Escape/Shift.
    if (event.key === 'Tab' || event.key === 'Escape' || event.key === 'Shift') {
      return;
    }
    event.preventDefault();
  }
}
