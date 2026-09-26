import { TestBed } from '@angular/core/testing';
import { IconComponent } from './icon.component';

describe('IconComponent', () => {
  beforeEach(() => TestBed.configureTestingModule({ imports: [IconComponent] }));

  function create(name: IconComponent['name'] = 'check') {
    const fixture = TestBed.createComponent(IconComponent);
    fixture.componentInstance.name = name;
    return fixture;
  }

  it('paints the icon path into the svg', () => {
    const fixture = create();
    fixture.detectChanges();
    const svg: SVGSVGElement | null = fixture.nativeElement.querySelector('svg');
    expect(svg).not.toBeNull();
    expect(svg!.innerHTML).toContain('<path');
    expect(svg!.getAttribute('viewBox')).toBe('0 0 24 24');
  });

  it('returns a stable sanitized value so change detection never rewrites the DOM', () => {
    const fixture = create('users');
    expect(fixture.componentInstance.path).toBe(fixture.componentInstance.path);
  });

  it('memoizes per icon name across component instances', () => {
    const a = create('wallet').componentInstance.path;
    const b = create('wallet').componentInstance.path;
    expect(a).toBe(b);
  });

  it('still renders when handed an unknown icon name', () => {
    const fixture = create('definitely-not-an-icon' as IconComponent['name']);
    fixture.detectChanges();
    const svg: SVGSVGElement | null = fixture.nativeElement.querySelector('svg');
    expect(svg).not.toBeNull();
    expect(svg!.innerHTML).toContain('<');
  });
});
