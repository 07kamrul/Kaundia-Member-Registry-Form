import { ChangeDetectionStrategy, Component, Input } from '@angular/core';

interface TrendSeries {
  key: 'income' | 'expense' | 'net';
  values: number[];
  color: string;
  dashed: boolean;
}

/**
 * Hand-rolled SVG line/area chart: income vs expense over time with a net
 * line, hover crosshair + tooltip showing the exact figures. Scales with the
 * container; negative nets are plotted below an emphasized zero line.
 */
@Component({
  selector: 'app-trend-chart',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="trend-wrap">
      @if (labels.length < 2) {
        <p class="trend-empty">{{ emptyLabel }}</p>
      } @else {
        <div class="trend-plot">
          <svg [attr.viewBox]="'0 0 ' + width + ' ' + height" preserveAspectRatio="xMidYMid meet" class="trend-svg">
            @for (gridY of gridLines; track $index) {
              <line [attr.x1]="padLeft" [attr.x2]="width - padRight" [attr.y1]="gridY" [attr.y2]="gridY" class="trend-grid" />
            }
            @if (hasNegative) {
              <line [attr.x1]="padLeft" [attr.x2]="width - padRight" [attr.y1]="y(0)" [attr.y2]="y(0)" class="trend-zero" />
            }
            @if (areaPath) {
              <path [attr.d]="areaPath" class="trend-area" />
            }
            <path [attr.d]="linePath(incomeValues)" class="trend-line trend-income" />
            <path [attr.d]="linePath(expenseValues)" class="trend-line trend-expense" />
            <path [attr.d]="linePath(netValues)" class="trend-line trend-net" [class.trend-dashed]="true" />

            @if (hoverIndex !== null && hoverIndex < labels.length) {
              <line
                [attr.x1]="x(hoverIndex)"
                [attr.x2]="x(hoverIndex)"
                [attr.y1]="padTop"
                [attr.y2]="height - padBottom"
                class="trend-hover-line"
              />
              <circle [attr.cx]="x(hoverIndex)" [attr.cy]="yOf(incomeValues[hoverIndex])" r="4" class="trend-dot trend-income" />
              <circle [attr.cx]="x(hoverIndex)" [attr.cy]="yOf(expenseValues[hoverIndex])" r="4" class="trend-dot trend-expense" />
              <circle [attr.cx]="x(hoverIndex)" [attr.cy]="yOf(netValues[hoverIndex])" r="4" class="trend-dot trend-net" />
            }

            @for (band of hoverBands; track $index) {
              <rect
                [attr.x]="band.x"
                [attr.y]="padTop"
                [attr.width]="band.width"
                [attr.height]="height - padTop - padBottom"
                class="trend-band"
                (pointerenter)="hoverIndex = $index"
                (pointerleave)="onLeave()"
                (click)="hoverIndex = $index"
              />
            }
          </svg>

          @if (hoverIndex !== null && hoverIndex < labels.length) {
            <div class="trend-tooltip" [style.left.%]="tooltipLeft">
              <p class="trend-tooltip-label">{{ labels[hoverIndex] }}</p>
              <p class="trend-tooltip-row"><span class="trend-swatch trend-income"></span>{{ incomeLabel }}: {{ formatValue(incomeValues[hoverIndex]) }}</p>
              <p class="trend-tooltip-row"><span class="trend-swatch trend-expense"></span>{{ expenseLabel }}: {{ formatValue(expenseValues[hoverIndex]) }}</p>
              <p class="trend-tooltip-row"><span class="trend-swatch trend-net"></span>{{ netLabel }}: {{ formatValue(netValues[hoverIndex]) }}</p>
            </div>
          }
        </div>

        <div class="trend-x">
          @for (label of sparseLabels; track $index) {
            <span class="trend-x-label">{{ label.text }}</span>
          }
        </div>
        <div class="trend-legend">
          <span class="trend-legend-item"><span class="trend-swatch trend-income"></span>{{ incomeLabel }}</span>
          <span class="trend-legend-item"><span class="trend-swatch trend-expense"></span>{{ expenseLabel }}</span>
          <span class="trend-legend-item"><span class="trend-swatch trend-net"></span>{{ netLabel }}</span>
        </div>
      }
    </div>
  `,
  styles: `
    .trend-wrap {
      width: 100%;
    }
    .trend-plot {
      position: relative;
      width: 100%;
    }
    .trend-svg {
      width: 100%;
      height: auto;
      display: block;
    }
    .trend-grid {
      stroke: var(--gray-200);
      stroke-width: 1;
    }
    .trend-zero {
      stroke: var(--gray-400);
      stroke-width: 1.2;
      stroke-dasharray: 4 3;
    }
    .trend-area {
      fill: var(--emerald-600);
      opacity: 0.1;
    }
    .trend-line {
      fill: none;
      stroke-width: 2.4;
      stroke-linecap: round;
      stroke-linejoin: round;
    }
    .trend-income {
      stroke: var(--emerald-600);
    }
    .trend-expense {
      stroke: var(--red-600);
    }
    .trend-net {
      stroke: var(--gold);
    }
    .trend-dashed {
      stroke-dasharray: 6 4;
    }
    .trend-dot {
      fill: var(--surface);
      stroke-width: 2;
    }
    .trend-hover-line {
      stroke: var(--gray-400);
      stroke-width: 1;
    }
    .trend-band {
      fill: transparent;
      cursor: pointer;
    }
    .trend-tooltip {
      position: absolute;
      top: 0.25rem;
      transform: translateX(-50%);
      background: var(--surface);
      border: 1px solid var(--gray-200);
      border-radius: var(--radius-sm);
      box-shadow: var(--shadow-md);
      padding: 0.5rem 0.75rem;
      font-size: 0.8125rem;
      pointer-events: none;
      white-space: nowrap;
      z-index: 2;
      min-width: 10rem;
    }
    .trend-tooltip-label {
      margin: 0 0 0.25rem;
      font-weight: 700;
      color: var(--emerald-800);
    }
    .trend-tooltip-row {
      margin: 0.1rem 0;
      display: flex;
      align-items: center;
      gap: 0.4rem;
      font-variant-numeric: tabular-nums;
    }
    .trend-swatch {
      width: 0.6rem;
      height: 0.6rem;
      border-radius: 2px;
      display: inline-block;
      flex: 0 0 auto;
    }
    .trend-x {
      display: flex;
      justify-content: space-between;
      padding: 0.35rem 0.25rem 0;
    }
    .trend-x-label {
      font-size: 0.72rem;
      color: var(--gray-500);
    }
    .trend-legend {
      display: flex;
      flex-wrap: wrap;
      gap: 1rem;
      justify-content: center;
      margin-top: 0.5rem;
      font-size: 0.8125rem;
      color: var(--gray-700);
    }
    .trend-legend-item {
      display: inline-flex;
      align-items: center;
      gap: 0.4rem;
    }
    .trend-empty {
      color: var(--gray-500);
      font-size: 0.875rem;
      text-align: center;
      margin: 1.5rem 0;
    }
  `,
})
export class TrendChartComponent {
  @Input({ required: true }) labels!: string[];
  @Input({ required: true }) incomeValues!: number[];
  @Input({ required: true }) expenseValues!: number[];
  @Input({ required: true }) netValues!: number[];
  @Input() incomeLabel = '';
  @Input() expenseLabel = '';
  @Input() netLabel = '';
  @Input() emptyLabel = '';
  @Input() formatValue: (value: number) => string = (value) => String(value);

  readonly width = 660;
  readonly height = 250;
  readonly padLeft = 6;
  readonly padRight = 6;
  readonly padTop = 10;
  readonly padBottom = 8;

  hoverIndex: number | null = null;

  onLeave(): void {
    this.hoverIndex = null;
  }

  private get maxValue(): number {
    return Math.max(1, ...this.incomeValues, ...this.expenseValues, ...this.netValues, 0);
  }

  private get minValue(): number {
    return Math.min(0, ...this.netValues, ...this.incomeValues, ...this.expenseValues);
  }

  get hasNegative(): boolean {
    return this.minValue < 0;
  }

  y(value: number): number {
    const span = this.maxValue - this.minValue || 1;
    const innerHeight = this.height - this.padTop - this.padBottom;
    return this.padTop + ((this.maxValue - value) / span) * innerHeight;
  }

  yOf(value: number): number {
    return this.y(value ?? 0);
  }

  x(index: number): number {
    const inner = this.width - this.padLeft - this.padRight;
    const step = this.labels.length > 1 ? inner / (this.labels.length - 1) : 0;
    return this.padLeft + index * step;
  }

  linePath(values: number[]): string {
    if (!values.length) return '';
    return values
      .map((value, index) => `${index === 0 ? 'M' : 'L'}${this.x(index).toFixed(1)},${this.y(value ?? 0).toFixed(1)}`)
      .join(' ');
  }

  get areaPath(): string {
    if (this.incomeValues.length < 2) return '';
    const line = this.linePath(this.incomeValues);
    const last = this.incomeValues.length - 1;
    return `${line} L${this.x(last).toFixed(1)},${this.y(0).toFixed(1)} L${this.x(0).toFixed(1)},${this.y(0).toFixed(1)} Z`;
  }

  get gridLines(): number[] {
    return [0, 0.25, 0.5, 0.75, 1].map(
      (fraction) => this.padTop + fraction * (this.height - this.padTop - this.padBottom),
    );
  }

  get hoverBands(): { x: number; width: number }[] {
    const count = this.labels.length;
    if (count < 2) return [];
    const inner = this.width - this.padLeft - this.padRight;
    const step = inner / (count - 1);
    const width = Math.max(step, 12);
    return this.labels.map((_, index) => ({
      x: this.x(index) - width / 2,
      width,
    }));
  }

  get tooltipLeft(): number {
    if (this.hoverIndex === null) return 50;
    const fraction = this.hoverIndex / Math.max(1, this.labels.length - 1);
    // Keep the tooltip inside the plot area.
    return Math.min(82, Math.max(18, fraction * 100));
  }

  /** First/last + a middle sample so narrow screens don't smear. */
  get sparseLabels(): { text: string }[] {
    const count = this.labels.length;
    if (count <= 6) return this.labels.map((text) => ({ text }));
    const picks = new Set<number>([0, Math.floor(count / 2), count - 1]);
    return [...picks].sort((a, b) => a - b).map((index) => ({ text: this.labels[index] }));
  }
}
