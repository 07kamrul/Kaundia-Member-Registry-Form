import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  OnInit,
  computed,
  inject,
  signal,
} from '@angular/core';
import { NgTemplateOutlet } from '@angular/common';
import { HttpErrorResponse } from '@angular/common/http';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import type { Subscription } from 'rxjs';
import { TranslatePipe } from '@ngx-translate/core';
import { IconComponent } from '../../../../shared/icon/icon.component';
import { LanguageService } from '../../../../core/services/language.service';
import { MemberService } from '../../../../core/services/member.service';
import { localizeDigits } from '../../../../core/services/roadmap.service';
import { telHref, whatsAppHref } from '../../../../shared/phone-input/contact-links';
import {
  NEIGHBOUR_DAG_TYPES,
  type NeighbourDagType,
  type NeighbourDirectory,
  type NeighbourGroup,
  type NeighbourOwnPlot,
  type NeighbourOwner,
} from '../../../../core/models/neighbour.model';

const ERROR_KEYS = {
  approvedOnly: 'member.neighbours.approvedOnly',
  rateLimited: 'member.neighbours.rateLimited',
  loadError: 'member.neighbours.loadError',
} as const;
const APPROVED_ONLY_CODE = 'NEIGHBOUR_DIRECTORY_APPROVED_ONLY';
const RATE_LIMITED_CODE = 'NEIGHBOUR_LOOKUP_RATE_LIMITED';
const HTTP_FORBIDDEN = 403;
const HTTP_TOO_MANY_REQUESTS = 429;
const NUMERIC_QUANTITY = /^\d+(\.\d+)?$/;
const SKELETON_GROUPS = [1, 2] as const;
const EMPTY_VALUE = '—';

export interface NeighbourRow {
  owner: NeighbourOwner;
  telHref: string | null;
  whatsAppHref: string | null;
}

export interface NeighbourGroupView {
  own: NeighbourOwnPlot;
  hasDag: boolean;
  rows: NeighbourRow[];
}

const BANGLA_DIGITS = '০১২৩৪৫৬৭৮৯';

/** Replaces Bangla digits with their ASCII equivalents; other characters are kept. */
export function toAsciiDigits(text: string): string {
  return text.replace(/[০-৯]/g, (digit) => String(BANGLA_DIGITS.indexOf(digit)));
}

function errorCode(error: HttpErrorResponse): string | null {
  const body: unknown = error.error;
  if (typeof body !== 'object' || body === null) return null;
  const detail: unknown = (body as { detail?: unknown }).detail;
  if (typeof detail !== 'object' || detail === null) return null;
  const code: unknown = (detail as { code?: unknown }).code;
  return typeof code === 'string' ? code : null;
}

/** Maps a failed lookup to an i18n key - server text is never shown. */
export function neighbourErrorKey(error: unknown): string {
  if (!(error instanceof HttpErrorResponse)) return ERROR_KEYS.loadError;
  const code = errorCode(error);
  if (error.status === HTTP_FORBIDDEN && code === APPROVED_ONLY_CODE)
    return ERROR_KEYS.approvedOnly;
  if (error.status === HTTP_TOO_MANY_REQUESTS || code === RATE_LIMITED_CODE) {
    return ERROR_KEYS.rateLimited;
  }
  return ERROR_KEYS.loadError;
}

/** Same-dag owners first, then neighbours; contact links resolved once. */
export function toGroupView(group: NeighbourGroup): NeighbourGroupView {
  return {
    own: group.own,
    hasDag: group.own.dagNumber !== null,
    rows: [...group.sameDagOwners, ...group.neighbours].map((owner) => ({
      owner,
      telHref: telHref(owner.mobile),
      whatsAppHref: whatsAppHref(owner.mobile),
    })),
  };
}

@Component({
  selector: 'app-member-neighbours',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe, IconComponent, NgTemplateOutlet],
  templateUrl: './neighbours.component.html',
  styleUrl: './neighbours.component.scss',
})
export class NeighboursComponent implements OnInit {
  private readonly memberService = inject(MemberService);
  private readonly destroyRef = inject(DestroyRef);
  readonly lang = inject(LanguageService).lang;

  readonly dagTypes = NEIGHBOUR_DAG_TYPES;
  readonly skeletonGroups = SKELETON_GROUPS;
  readonly directory = signal<NeighbourDirectory | null>(null);
  readonly loading = signal(true);
  readonly errorKey = signal<string | null>(null);
  /** Selected toggle value; null until the server echoes its default. */
  readonly dagType = signal<NeighbourDagType | null>(null);
  /** Last known plot limit - kept while a dag-type switch reloads. */
  readonly plotLimit = signal<number | null>(null);
  readonly groups = computed(() => (this.directory()?.properties ?? []).map(toGroupView));

  private request: Subscription | null = null;

  ngOnInit(): void {
    this.load();
  }

  /** (Re)fetch for the selected dag type; the first request sends none. */
  load(): void {
    const requested = this.dagType() ?? undefined;
    this.request?.unsubscribe();
    this.loading.set(true);
    this.errorKey.set(null);
    this.request = this.memberService
      .getNeighbours(requested)
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: (data) => {
          this.directory.set(data);
          this.dagType.set(data.dagType);
          this.plotLimit.set(data.plotLimit);
          this.loading.set(false);
        },
        error: (err: unknown) => {
          this.directory.set(null);
          this.errorKey.set(neighbourErrorKey(err));
          this.loading.set(false);
        },
      });
  }

  selectDagType(type: NeighbourDagType): void {
    if (this.loading() || type === this.dagType()) return;
    this.dagType.set(type);
    this.load();
  }

  otherDagType(type: NeighbourDagType): NeighbourDagType {
    return type === 'rs' ? 'cs' : 'rs';
  }

  ownDag(own: NeighbourOwnPlot, type: NeighbourDagType): string | null {
    return type === 'rs' ? own.rsDag : own.csDag;
  }

  isNumericQuantity(quantity: string): boolean {
    return NUMERIC_QUANTITY.test(quantity);
  }

  digits(value: string | number | null): string {
    if (value === null || value === '') return EMPTY_VALUE;
    // Stored values mix Bangla and ASCII digits ("৮৩০", "830/1"); normalise
    // first so the whole page shows one digit set for the active language.
    return localizeDigits(toAsciiDigits(String(value)), this.lang());
  }
}
