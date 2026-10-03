import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  HostListener,
  Input,
  computed,
  forwardRef,
  inject,
  signal,
} from '@angular/core';
import { ControlValueAccessor, NG_VALUE_ACCESSOR } from '@angular/forms';
import { TranslatePipe } from '@ngx-translate/core';
import { CountryCode, getExampleNumber } from 'libphonenumber-js';
import examples from 'libphonenumber-js/mobile/examples';
import { LanguageService } from '../../core/services/language.service';
import {
  DEFAULT_PHONE_COUNTRY,
  PhoneCountry,
  composePhoneNumber,
  filterPhoneCountries,
  listPhoneCountries,
  splitPhoneNumber,
} from './phone-number';

/**
 * International phone input: searchable country picker + national number.
 * Works with formControlName and ngModel; the model value is E.164
 * (e.g. "+8801712345678"). Legacy national values ("01712345678") are read
 * as Bangladeshi numbers.
 */
@Component({
  selector: 'app-phone-input',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe],
  providers: [
    { provide: NG_VALUE_ACCESSOR, useExisting: forwardRef(() => PhoneInputComponent), multi: true },
  ],
  template: `
    <div class="phone-input" [class.is-invalid]="invalid" [class.is-disabled]="disabled()">
      <button
        type="button"
        class="phone-country-trigger"
        [disabled]="disabled()"
        [attr.aria-label]="'phoneInput.selectCountry' | translate"
        aria-haspopup="listbox"
        [attr.aria-expanded]="open()"
        (click)="toggle()"
      >
        <span class="phone-flag" aria-hidden="true">{{ selected().flag }}</span>
        <span class="phone-dial">{{ selected().dialCode }}</span>
        <span class="phone-caret" aria-hidden="true">▾</span>
      </button>
      <input
        type="tel"
        inputmode="tel"
        autocomplete="tel-national"
        [attr.id]="inputId"
        [value]="nationalNumber()"
        [disabled]="disabled()"
        [attr.placeholder]="placeholder()"
        [attr.aria-invalid]="invalid ? 'true' : null"
        (input)="onNumberInput($any($event.target).value)"
        (blur)="onTouched()"
      />
      @if (open()) {
        <div class="phone-country-panel">
          <input
            type="search"
            class="phone-country-search"
            [value]="query()"
            [attr.placeholder]="'phoneInput.searchCountry' | translate"
            [attr.aria-label]="'phoneInput.searchCountry' | translate"
            (input)="query.set($any($event.target).value)"
            (keydown.enter)="$event.preventDefault(); pickFirst()"
          />
          <ul class="phone-country-list" role="listbox">
            @for (country of filtered(); track country.code) {
              <li
                role="option"
                [attr.aria-selected]="country.code === countryCode()"
                [class.is-selected]="country.code === countryCode()"
                (click)="pick(country.code)"
              >
                <span class="phone-flag" aria-hidden="true">{{ country.flag }}</span>
                <span class="phone-country-name">{{ country.name }}</span>
                <span class="phone-dial">{{ country.dialCode }}</span>
              </li>
            } @empty {
              <li class="phone-country-empty">{{ 'phoneInput.noCountry' | translate }}</li>
            }
          </ul>
        </div>
      }
    </div>
  `,
})
export class PhoneInputComponent implements ControlValueAccessor {
  @Input() inputId: string | null = null;
  @Input() invalid = false;

  private readonly host: ElementRef<HTMLElement> = inject(ElementRef);
  private readonly language = inject(LanguageService);

  readonly countries = computed(() => listPhoneCountries(this.language.lang()));
  readonly countryCode = signal<CountryCode>(DEFAULT_PHONE_COUNTRY);
  readonly nationalNumber = signal('');
  readonly disabled = signal(false);
  readonly open = signal(false);
  readonly query = signal('');

  readonly selected = computed<PhoneCountry>(
    () =>
      this.countries().find((c) => c.code === this.countryCode()) ?? {
        code: this.countryCode(),
        name: this.countryCode(),
        dialCode: '',
        flag: '',
      },
  );
  readonly filtered = computed(() => filterPhoneCountries(this.countries(), this.query()));
  readonly placeholder = computed(
    () => getExampleNumber(this.countryCode(), examples)?.formatNational() ?? '',
  );

  private onChange: (value: string) => void = () => undefined;
  onTouched: () => void = () => undefined;

  toggle(): void {
    this.open.update((isOpen) => !isOpen);
    this.query.set('');
    if (this.open()) {
      queueMicrotask(() =>
        this.host.nativeElement.querySelector<HTMLInputElement>('.phone-country-search')?.focus(),
      );
    }
  }

  pick(code: CountryCode): void {
    this.countryCode.set(code);
    this.open.set(false);
    this.emit();
  }

  pickFirst(): void {
    const first = this.filtered()[0];
    if (first) this.pick(first.code);
  }

  onNumberInput(value: string): void {
    // A full international number pasted into the field switches the country.
    if (value.trim().startsWith('+')) {
      this.countryCode.set(splitPhoneNumber(value, this.countryCode()).country);
    }
    this.nationalNumber.set(value);
    this.emit();
  }

  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    if (this.open() && !this.host.nativeElement.contains(event.target as Node)) {
      this.open.set(false);
    }
  }

  @HostListener('keydown.escape')
  onEscape(): void {
    this.open.set(false);
  }

  writeValue(value: string | null): void {
    const split = splitPhoneNumber(value);
    this.countryCode.set(split.country);
    this.nationalNumber.set(split.nationalNumber);
  }

  registerOnChange(fn: (value: string) => void): void {
    this.onChange = fn;
  }

  registerOnTouched(fn: () => void): void {
    this.onTouched = fn;
  }

  setDisabledState(isDisabled: boolean): void {
    this.disabled.set(isDisabled);
  }

  private emit(): void {
    this.onChange(composePhoneNumber(this.countryCode(), this.nationalNumber()));
  }
}
