import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  Input,
  forwardRef,
  inject,
} from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { TranslatePipe } from '@ngx-translate/core';
import { IconComponent } from '../icon/icon.component';

/**
 * Password input with a show/hide toggle. Works with formControlName and ngModel.
 * The native input is never re-created, so toggling keeps the value and caret.
 */
@Component({
  selector: 'app-password-field',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe, IconComponent],
  providers: [
    {
      provide: NG_VALUE_ACCESSOR,
      useExisting: forwardRef(() => PasswordFieldComponent),
      multi: true,
    },
  ],
  template: `
    <div class="password-field">
      <input
        [type]="visible ? 'text' : 'password'"
        [value]="value"
        [disabled]="disabled"
        [attr.id]="inputId"
        [attr.autocomplete]="autocomplete"
        [attr.placeholder]="placeholder || null"
        [attr.aria-invalid]="invalid ? 'true' : null"
        (input)="onInput($any($event.target).value)"
        (blur)="onTouched()"
      />
      <button
        type="button"
        class="password-toggle"
        (click)="toggle()"
        [attr.aria-label]="(visible ? 'passwordField.hide' : 'passwordField.show') | translate"
        [attr.aria-pressed]="visible"
      >
        <app-icon [name]="visible ? 'eye-off' : 'eye'" [size]="18" />
      </button>
    </div>
  `,
})
export class PasswordFieldComponent implements ControlValueAccessor {
  @Input() inputId: string | null = null;
  @Input() autocomplete = 'current-password';
  @Input() placeholder = '';
  @Input() invalid = false;

  value = '';
  visible = false;
  disabled = false;

  private readonly cdr = inject(ChangeDetectorRef);
  private onChange: (value: string) => void = () => undefined;
  onTouched: () => void = () => undefined;

  toggle(): void {
    this.visible = !this.visible;
  }

  onInput(value: string): void {
    this.value = value;
    this.onChange(value);
  }

  writeValue(value: string | null): void {
    this.value = value ?? '';
    this.cdr.markForCheck();
  }

  registerOnChange(fn: (value: string) => void): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: () => void): void {
    this.onTouched = fn;
  }

  setDisabledState(isDisabled: boolean): void {
    this.disabled = isDisabled;
    this.cdr.markForCheck();
  }
}
