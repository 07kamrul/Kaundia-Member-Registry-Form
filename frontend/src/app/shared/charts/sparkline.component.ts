import { ChangeDetectionStrategy, Component, Input } from '@angular/core';

/** Tiny sparkline for summary tiles - trend at a glance, no axes. */
@Component({
  selector: 'app-sparkline',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (values.length > 1) {
      <svg [attr.viewBox]="'0 0 ' + width + ' ' + height" preserveAspectRatio="none" class="spark-svg" [style.color]="color">
        <polyline [attr.points]="points" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
      </svg>
    }
  `,
  styles: `
    .spark-svg {
      width: 100%;
      height: 1.6rem;
      display: block;
      opacity: 0.9;
    }
  `,
})
export class SparklineComponent {
  @Input({ required: true }) values!: number[];
  @Input() color = 'var(--emerald-600)';

  readonly width = 100;
  readonly height = 28;

  get points(): string {
    const min = Math.min(...this.values);
    const max = Math.max(...this.values);
    const span = max - min || 1;
    const step = this.width / (this.values.length - 1);
    return this.values
      .map((value, index) => {
        const y = 3 + ((max - value) / span) * (this.height - 6);
        return `${(index * step).toFixed(1)},${y.toFixed(1)}`;
      })
      .join(' ');
  }
}
