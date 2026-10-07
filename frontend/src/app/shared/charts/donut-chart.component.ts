import { ChangeDetectionStrategy, Component, Input } from '@angular/core';

export interface DonutSegment {
  label: string;
  value: number;
  /** Optional override; otherwise the brand palette rotates. */
  color?: string;
}

const PALETTE = [
  '#2e5138', // emerald-600
  '#c9a34c', // gold
  '#9c3a2c', // red-600
  '#47564a', // gray-700
  '#8a611a', // gold-strong
  '#78826f', // gray-500
  '#1f3d2a', // emerald-800
  '#b0794f',
];

/**
 * Hand-rolled SVG donut chart (no chart library): stroke-dasharray arcs with
 * a center summary, per-segment hover/tap tooltips and a legend that calls
 * out the largest slice. Kept dependency-free on purpose - the app has a
 * strict initial-bundle budget and this is ~2 kB instead of chart.js.
 */
@Component({
  selector: 'app-donut-chart',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="donut-wrap">
      <div class="donut-visual">
        <svg viewBox="0 0 120 120" role="img" class="donut-svg">
          <circle cx="60" cy="60" r="48" class="donut-track" />
          @for (arc of arcs; track $index) {
            <circle
              cx="60"
              cy="60"
              r="48"
              class="donut-segment"
              [class.donut-segment-active]="activeIndex === $index"
              [attr.stroke]="arc.color"
              [attr.stroke-dasharray]="arc.dasharray"
              [attr.stroke-dashoffset]="arc.dashoffset"
              (pointerenter)="activeIndex = $index"
              (click)="activeIndex = $index"
            />
          }
        </svg>
        <div class="donut-center">
          @if (activeIndex !== null && arcs[activeIndex]) {
            <span class="donut-center-percent">{{ arcs[activeIndex].percentLabel }}</span>
            <span class="donut-center-label">{{ arcs[activeIndex].label }}</span>
          } @else {
            <span class="donut-center-percent">{{ centerValue }}</span>
            <span class="donut-center-label">{{ centerTitle }}</span>
          }
        </div>
      </div>

      <ul class="donut-legend">
        @for (arc of arcs; track $index) {
          <li
            class="donut-legend-row"
            [class.donut-legend-active]="activeIndex === $index"
            (pointerenter)="activeIndex = $index"
            (click)="activeIndex = $index"
          >
            <span class="donut-dot" [style.background]="arc.color"></span>
            <span class="donut-legend-label">
              {{ arc.label }}
              @if ($index === 0 && arcs.length > 1) {
                <span class="donut-top-tag">{{ topTag }}</span>
              }
            </span>
            <span class="donut-legend-value">{{ arc.valueLabel }}</span>
          </li>
        }
      </ul>
    </div>
  `,
  styles: `
    .donut-wrap {
      display: flex;
      gap: 1.25rem;
      align-items: center;
      flex-wrap: wrap;
    }
    .donut-visual {
      position: relative;
      width: 11rem;
      flex: 0 0 auto;
      margin: 0 auto;
    }
    .donut-svg {
      width: 100%;
      height: auto;
      display: block;
    }
    .donut-track {
      fill: none;
      stroke: var(--gray-200);
      stroke-width: 16;
    }
    .donut-segment {
      fill: none;
      stroke-width: 16;
      cursor: pointer;
      transition: stroke-width 0.15s ease;
    }
    .donut-segment-active {
      stroke-width: 20;
    }
    .donut-center {
      position: absolute;
      inset: 0;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      text-align: center;
      pointer-events: none;
      padding: 0 1.75rem;
    }
    .donut-center-percent {
      font-weight: 700;
      font-size: 1rem;
      color: var(--emerald-800);
      word-break: break-word;
    }
    .donut-center-label {
      font-size: 0.75rem;
      color: var(--gray-600);
      margin-top: 0.15rem;
      word-break: break-word;
    }
    .donut-legend {
      list-style: none;
      margin: 0;
      padding: 0;
      flex: 1 1 12rem;
      min-width: 11rem;
      display: flex;
      flex-direction: column;
      gap: 0.3rem;
    }
    .donut-legend-row {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.2rem 0.4rem;
      border-radius: var(--radius-sm);
      cursor: pointer;
      font-size: 0.875rem;
    }
    .donut-legend-active {
      background: var(--surface-2);
    }
    .donut-dot {
      width: 0.65rem;
      height: 0.65rem;
      border-radius: 50%;
      flex: 0 0 auto;
    }
    .donut-legend-label {
      flex: 1;
      min-width: 0;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .donut-top-tag {
      font-size: 0.625rem;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      color: var(--gold-strong);
      margin-left: 0.3rem;
    }
    .donut-legend-value {
      font-weight: 600;
      white-space: nowrap;
      font-variant-numeric: tabular-nums;
    }
  `,
})
export class DonutChartComponent {
  @Input({ required: true }) segments!: DonutSegment[];
  @Input() centerTitle = '';
  @Input() centerValue = '';
  /** Legend call-out for the largest slice, already translated. */
  @Input() topTag = '';
  /** Formats segment amounts for the legend/tooltip. */
  @Input() formatValue: (value: number) => string = (value) => String(value);

  activeIndex: number | null = null;

  get arcs(): {
    color: string;
    label: string;
    valueLabel: string;
    percentLabel: string;
    dasharray: string;
    dashoffset: string;
  }[] {
    const total = this.segments.reduce((sum, s) => sum + s.value, 0);
    const circumference = 2 * Math.PI * 48;
    let offset = 0;
    return this.segments.map((segment, index) => {
      const fraction = total > 0 ? segment.value / total : 0;
      const length = fraction * circumference;
      const arc = {
        color: segment.color ?? PALETTE[index % PALETTE.length],
        label: segment.label,
        valueLabel: this.formatValue(segment.value),
        percentLabel: `${Math.round(fraction * 100)}%`,
        dasharray: `${length} ${circumference - length}`,
        // Rotate -90° so the chart starts at 12 o'clock: offset 25% of C.
        dashoffset: `${-offset + circumference * 0.25}`,
      };
      offset += length;
      return arc;
    });
  }
}
