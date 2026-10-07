import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  HostListener,
  OnDestroy,
  OnInit,
  computed,
  inject,
  input,
  output,
  signal,
} from '@angular/core';
import { TranslatePipe } from '@ngx-translate/core';
import { IconComponent } from '../../../../shared/icon/icon.component';
import { LanguageService } from '../../../../core/services/language.service';
import {
  currentTimeframeIndex,
  formatRoadmapDate,
  localizeDigits,
  timeframeName,
  timeframeWindow,
  type Roadmap,
  type RoadmapItem,
  type RoadmapTimeframe,
} from '../../../../core/services/roadmap.service';

/** Items per slide - keeps text legible from the back of a meeting hall. */
const ITEMS_PER_SLIDE = 6;
const SWIPE_THRESHOLD_PX = 50;

export type RoadmapSlide =
  | { kind: 'overview' }
  | {
      kind: 'timeframe';
      tf: RoadmapTimeframe;
      index: number;
      items: RoadmapItem[];
      page: number;
      pages: number;
    };

/** One overview slide, then each timeframe auto-paginated. */
export function buildSlides(roadmap: Roadmap): RoadmapSlide[] {
  const slides: RoadmapSlide[] = [{ kind: 'overview' }];
  roadmap.timeframes.forEach((tf, index) => {
    const pages = Math.max(1, Math.ceil(tf.items.length / ITEMS_PER_SLIDE));
    for (let page = 0; page < pages; page++) {
      slides.push({
        kind: 'timeframe',
        tf,
        index,
        items: tf.items.slice(page * ITEMS_PER_SLIDE, (page + 1) * ITEMS_PER_SLIDE),
        page: page + 1,
        pages,
      });
    }
  });
  return slides;
}

/** Full-screen, projector-friendly walkthrough built from the live payload. */
@Component({
  selector: 'app-roadmap-slides',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [TranslatePipe, IconComponent],
  templateUrl: './roadmap-slides.component.html',
  styleUrl: './roadmap-slides.component.scss',
  host: {
    role: 'dialog',
    'aria-modal': 'true',
    tabindex: '-1',
    '[attr.aria-label]': "'Roadmap slides'",
  },
})
export class RoadmapSlidesComponent implements OnInit, OnDestroy {
  private readonly host = inject<ElementRef<HTMLElement>>(ElementRef);
  private readonly language = inject(LanguageService);

  readonly roadmap = input.required<Roadmap>();
  readonly closed = output<void>();

  readonly lang = this.language.lang;
  readonly position = signal(0);
  private touchStartX: number | null = null;
  private previouslyFocused: Element | null = null;

  readonly slides = computed(() => buildSlides(this.roadmap()));
  readonly slide = computed(() => this.slides()[Math.min(this.position(), this.slides().length - 1)]);
  readonly currentIndex = computed(() => currentTimeframeIndex(this.roadmap()));

  ngOnInit(): void {
    this.previouslyFocused = document.activeElement;
    const element = this.host.nativeElement;
    element.focus();
    // Fullscreen is a nicety - the fixed overlay still works where it is refused.
    element.requestFullscreen?.().catch(() => undefined);
  }

  ngOnDestroy(): void {
    if (document.fullscreenElement) document.exitFullscreen().catch(() => undefined);
    if (this.previouslyFocused instanceof HTMLElement) this.previouslyFocused.focus();
  }

  @HostListener('document:keydown', ['$event'])
  onKeydown(event: KeyboardEvent): void {
    switch (event.key) {
      case 'ArrowRight':
      case 'PageDown':
      case ' ':
        event.preventDefault();
        this.next();
        break;
      case 'ArrowLeft':
      case 'PageUp':
        event.preventDefault();
        this.prev();
        break;
      case 'Home':
        this.position.set(0);
        break;
      case 'End':
        this.position.set(this.slides().length - 1);
        break;
      case 'Escape':
        this.close();
        break;
    }
  }

  @HostListener('touchstart', ['$event'])
  onTouchStart(event: TouchEvent): void {
    this.touchStartX = event.changedTouches[0]?.clientX ?? null;
  }

  @HostListener('touchend', ['$event'])
  onTouchEnd(event: TouchEvent): void {
    if (this.touchStartX === null) return;
    const delta = (event.changedTouches[0]?.clientX ?? this.touchStartX) - this.touchStartX;
    this.touchStartX = null;
    if (Math.abs(delta) < SWIPE_THRESHOLD_PX) return;
    if (delta < 0) this.next();
    else this.prev();
  }

  next(): void {
    this.position.update((p) => Math.min(p + 1, this.slides().length - 1));
  }

  prev(): void {
    this.position.update((p) => Math.max(p - 1, 0));
  }

  close(): void {
    this.closed.emit();
  }

  digits(value: number | string): string {
    return localizeDigits(value, this.lang());
  }

  date(iso: string | null): string {
    return formatRoadmapDate(iso, this.lang());
  }

  name(tf: RoadmapTimeframe): string {
    return timeframeName(tf, this.lang());
  }

  windowLabel(tf: RoadmapTimeframe): string {
    return timeframeWindow(tf, this.lang());
  }
}
