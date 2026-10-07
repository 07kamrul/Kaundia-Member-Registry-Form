import { ChangeDetectionStrategy, Component, computed, forwardRef, input, model, output, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';

export interface MemberPickerOption {
  id: number;
  fullName: string;
  memberId?: string | null;
}

/**
 * Shared searchable member picker (single- or multi-select).
 * Multi-select is used for meeting attendance; single-select for the
 * chairperson / assignee fields. Selection is by member id.
 */
@Component({
  selector: 'app-member-picker',
  standalone: true,
  imports: [FormsModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="picker" [class.picker-open]="open()">
      <div class="picker-control" (click)="toggleOpen()">
        @if (selected().length === 0) {
          <span class="picker-placeholder">{{ placeholder() }}</span>
        } @else {
          <div class="picker-chips">
            @for (option of selectedOptions(); track option.id) {
              <span class="picker-chip">
                <span class="picker-chip-name">{{ option.fullName }}</span>
                @if (!disabled()) {
                  <button
                    type="button"
                    class="picker-chip-remove"
                    (click)="remove($event, option.id)"
                    [attr.aria-label]="'Remove ' + option.fullName"
                  >
                    ×
                  </button>
                }
              </span>
            }
            @if (multiple() && selected().length > 5) {
              <span class="picker-count">+{{ selected().length - 5 }}</span>
            }
          </div>
        }
        <span class="picker-caret" aria-hidden="true">▾</span>
      </div>

      @if (open() && !disabled()) {
        <div class="picker-dropdown">
          <input
            type="text"
            class="picker-search"
            [ngModel]="query()"
            [ngModelOptions]="{ standalone: true }"
            (ngModelChange)="query.set($event)"
            [placeholder]="searchPlaceholder()"
            (click)="$event.stopPropagation()"
          />
          <div class="picker-list" role="listbox">
            @for (option of filteredOptions(); track option.id) {
              <button
                type="button"
                class="picker-option"
                role="option"
                [attr.aria-selected]="isSelected(option.id)"
                [class.picker-option-selected]="isSelected(option.id)"
                (click)="toggleOption(option)"
              >
                <span class="picker-option-check" aria-hidden="true">{{ isSelected(option.id) ? '✓' : '' }}</span>
                <span class="picker-option-name">{{ option.fullName }}</span>
                @if (option.memberId) {
                  <span class="picker-option-id">{{ option.memberId }}</span>
                }
              </button>
            } @empty {
              <div class="picker-empty">{{ emptyText() }}</div>
            }
          </div>
        </div>
      }
    </div>
  `,
  styles: [
    `
      :host {
        display: block;
      }
      .picker {
        position: relative;
      }
      .picker-control {
        min-height: 44px;
        display: flex;
        align-items: center;
        gap: 0.5rem;
        padding: 0.35rem 2rem 0.35rem 0.6rem;
        border: 1px solid var(--border, #ddd);
        border-radius: var(--radius-md, 10px);
        background: var(--surface, #fff);
        cursor: pointer;
        flex-wrap: wrap;
      }
      .picker-placeholder {
        color: var(--text-muted, #888);
        font-size: 0.9rem;
      }
      .picker-caret {
        position: absolute;
        right: 0.7rem;
        top: 50%;
        transform: translateY(-50%);
        color: var(--text-muted, #888);
        pointer-events: none;
      }
      .picker-chips {
        display: flex;
        flex-wrap: wrap;
        gap: 0.3rem;
      }
      .picker-chip {
        display: inline-flex;
        align-items: center;
        gap: 0.25rem;
        background: var(--surface-2, #f3efe3);
        border: 1px solid var(--border, #ddd);
        border-radius: 999px;
        padding: 0.1rem 0.3rem 0.1rem 0.6rem;
        font-size: 0.82rem;
      }
      .picker-chip-remove {
        border: none;
        background: transparent;
        color: var(--text-muted, #888);
        font-size: 1rem;
        line-height: 1;
        cursor: pointer;
        padding: 0 0.2rem;
      }
      .picker-count {
        font-size: 0.8rem;
        color: var(--text-muted, #888);
      }
      .picker-dropdown {
        position: absolute;
        z-index: 30;
        top: calc(100% + 4px);
        left: 0;
        right: 0;
        background: var(--surface, #fff);
        border: 1px solid var(--border, #ddd);
        border-radius: var(--radius-md, 10px);
        box-shadow: var(--shadow-md, 0 8px 24px rgba(0, 0, 0, 0.12));
        overflow: hidden;
      }
      .picker-search {
        width: 100%;
        border: none;
        border-bottom: 1px solid var(--border, #ddd);
        padding: 0.6rem 0.8rem;
        font-size: 0.9rem;
        background: transparent;
        color: inherit;
        outline: none;
      }
      .picker-list {
        max-height: 260px;
        overflow-y: auto;
      }
      .picker-option {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        width: 100%;
        padding: 0.55rem 0.8rem;
        border: none;
        background: transparent;
        text-align: left;
        font-size: 0.9rem;
        color: inherit;
        cursor: pointer;
        min-height: 44px;
      }
      .picker-option:hover,
      .picker-option-selected {
        background: var(--surface-2, #f3efe3);
      }
      .picker-option-check {
        width: 1.1rem;
        color: var(--emerald-600, #2e5138);
        font-weight: 600;
      }
      .picker-option-name {
        flex: 1;
      }
      .picker-option-id {
        font-size: 0.75rem;
        color: var(--text-muted, #888);
      }
      .picker-empty {
        padding: 0.8rem;
        font-size: 0.85rem;
        color: var(--text-muted, #888);
        text-align: center;
      }
    `,
  ],
})
export class MemberPickerComponent {
  readonly options = input.required<MemberPickerOption[]>();
  readonly selected = model<number[]>([]);
  readonly multiple = input(true);
  readonly disabled = input(false);
  readonly placeholder = input('নির্বাচন করুন…');
  readonly searchPlaceholder = input('নাম দিয়ে খুঁজুন…');
  readonly emptyText = input('কোনো সদস্য পাওয়া যায়নি');
  readonly selectionChange = output<number[]>();

  readonly open = signal(false);
  readonly query = signal('');

  readonly selectedOptions = computed(() => {
    const ids = new Set(this.selected());
    return this.options().filter((option) => ids.has(option.id));
  });

  readonly filteredOptions = computed(() => {
    const needle = this.query().trim().toLowerCase();
    const options = this.options();
    if (!needle) return options;
    return options.filter(
      (option) =>
        option.fullName.toLowerCase().includes(needle) ||
        (option.memberId ?? '').toLowerCase().includes(needle),
    );
  });

  toggleOpen(): void {
    if (this.disabled()) return;
    this.open.update((value) => !value);
    if (this.open()) this.query.set('');
  }

  isSelected(id: number): boolean {
    return this.selected().includes(id);
  }

  toggleOption(option: MemberPickerOption): void {
    if (this.multiple()) {
      const next = this.isSelected(option.id)
        ? this.selected().filter((id) => id !== option.id)
        : [...this.selected(), option.id];
      this.setSelection(next);
    } else {
      this.setSelection([option.id]);
      this.open.set(false);
    }
  }

  remove(event: Event, id: number): void {
    event.stopPropagation();
    this.setSelection(this.selected().filter((value) => value !== id));
  }

  private setSelection(ids: number[]): void {
    this.selected.set(ids);
    this.selectionChange.emit(ids);
  }
}
