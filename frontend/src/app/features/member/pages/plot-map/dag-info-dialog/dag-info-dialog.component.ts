import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  OnInit,
  computed,
  inject,
  input,
  output,
  signal,
  viewChild,
} from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import type { Subscription } from 'rxjs';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { LanguageService } from '../../../../../core/services/language.service';
import { LandDataService, type DagDetails } from '../../../../../core/services/land-data.service';
import { formatRoadmapDate, localizeDigits } from '../../../../../core/services/roadmap.service';
import { toAsciiDigits } from '../../../../../core/services/digits.helper';
import { groupKhatians, landFigures, mouzaLabel } from './dag-info-format';

/** The dag the dialog shows; survey + sheet address the details endpoint. */
export interface DagTarget {
  readonly survey: string;
  readonly sheet: string;
  readonly dag: string;
}

type DialogState =
  | { readonly status: 'loading' }
  | { readonly status: 'loaded'; readonly details: DagDetails }
  | { readonly status: 'error'; readonly kind: 'notFound' | 'rateLimited' | 'generic' };

const FOCUSABLE = 'button:not([disabled]), [href], [tabindex]:not([tabindex="-1"])';

/**
 * Official-style dag information dialog (mirrors the settlement.gov.bd popup):
 * land details + khatian table. Fixed blue header and grey footer, scrolling
 * body. Owner names are fetched lazily for the one dag shown and kept only in
 * this component's memory.
 */
@Component({
  selector: 'app-dag-info-dialog',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe],
  templateUrl: './dag-info-dialog.component.html',
  styleUrl: './dag-info-dialog.component.scss',
})
export class DagInfoDialogComponent implements OnInit {
  readonly target = input.required<DagTarget>();
  readonly closed = output<void>();

  private readonly landData = inject(LandDataService);
  private readonly translate = inject(TranslateService);
  private readonly destroyRef = inject(DestroyRef);
  private readonly lang = inject(LanguageService).lang;
  private readonly panel = viewChild.required<ElementRef<HTMLElement>>('panel');
  private request?: Subscription;

  readonly state = signal<DialogState>({ status: 'loading' });

  readonly dagLabel = computed(() => localizeDigits(toAsciiDigits(this.target().dag), this.lang()));
  readonly surveyLabel = computed(() => {
    this.lang();
    const survey = this.target().survey;
    const key = `member.plotMap.dagInfo.survey.${survey}`;
    const label = this.translate.instant(key);
    return label === key ? survey.toUpperCase() : label;
  });

  /** Everything the loaded view needs, derived once per state/language change. */
  readonly view = computed(() => {
    const state = this.state();
    if (state.status !== 'loaded') return null;
    const lang = this.lang();
    const { details } = state;
    const figures = landFigures(details.total_land, lang);
    return {
      mouza: mouzaLabel(details.mouza, lang),
      figures,
      unitLabel: this.unitLabel(figures.unit),
      groups: groupKhatians(details.khatians).map((group) => ({
        ...group,
        number: localizeDigits(toAsciiDigits(group.khatian.khatian_no), lang),
        stage: this.stageLabel(group.khatian.stage_code, group.khatian.stage_bn),
      })),
      collected: formatRoadmapDate(details.source.fetched_at, lang),
    };
  });

  ngOnInit(): void {
    this.load();
    queueMicrotask(() => this.panel().nativeElement.focus());
  }

  load(): void {
    this.request?.unsubscribe();
    this.state.set({ status: 'loading' });
    const { survey, sheet, dag } = this.target();
    this.request = this.landData
      .dagDetails(survey, sheet, dag)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (details) => this.state.set({ status: 'loaded', details }),
        error: (error: unknown) => this.state.set({ status: 'error', kind: errorKind(error) }),
      });
  }

  close(): void {
    this.closed.emit();
  }

  onOverlayClick(event: MouseEvent): void {
    if (event.target === event.currentTarget) this.close();
  }

  onKeydown(event: KeyboardEvent): void {
    if (event.key === 'Escape') {
      event.preventDefault();
      this.close();
      return;
    }
    if (event.key === 'Tab') this.trapFocus(event);
  }

  private trapFocus(event: KeyboardEvent): void {
    const root = this.panel().nativeElement;
    const items = Array.from(root.querySelectorAll<HTMLElement>(FOCUSABLE));
    if (!items.length) {
      event.preventDefault();
      return;
    }
    const first = items[0];
    const last = items[items.length - 1];
    const active = document.activeElement;
    if (event.shiftKey && (active === first || active === root)) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && active === last) {
      event.preventDefault();
      first.focus();
    }
  }

  private unitLabel(unit: string): string {
    const key = `member.plotMap.dagInfo.unit.${unit}`;
    const label = this.translate.instant(key);
    return label === key ? unit : label;
  }

  /** Known stages go through i18n; anything else is shown as stored. */
  private stageLabel(code: string | null, stageBn: string): string {
    if (!code) return stageBn;
    const key = `member.plotMap.dagInfo.stage.${code}`;
    const label = this.translate.instant(key);
    return label === key ? stageBn : label;
  }
}

function errorKind(error: unknown): 'notFound' | 'rateLimited' | 'generic' {
  if (!(error instanceof HttpErrorResponse)) return 'generic';
  if (error.status === 404) return 'notFound';
  if (error.status === 429) return 'rateLimited';
  return 'generic';
}
