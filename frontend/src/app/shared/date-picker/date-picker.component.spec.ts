import { TestBed, ComponentFixture } from '@angular/core/testing';
import { vi } from 'vitest';
import { DatePickerComponent } from './date-picker.component';
import {
  AttachmentMissingError,
  AttachmentService,
} from '../../core/services/attachment.service';

describe('DatePickerComponent', () => {
  function create(): ComponentFixture<DatePickerComponent> {
    TestBed.configureTestingModule({});
    const fixture = TestBed.createComponent(DatePickerComponent);
    fixture.detectChanges();
    return fixture;
  }

  it('formats an ISO value for display and returns "" for empty/invalid values', () => {
    const fixture = create();
    const c = fixture.componentInstance;
    c.value = '2026-10-02';
    expect(c.displayValue).toMatch(/02.*2026/);
    c.value = '';
    expect(c.displayValue).toBe('');
    c.value = 'not-a-date';
    expect(c.displayValue).toBe('');
  });

  it('emits the native input value on change and "" on clear', () => {
    const fixture = create();
    const emitted: string[] = [];
    fixture.componentInstance.valueChange.subscribe((v: string) => emitted.push(v));
    fixture.componentInstance.onNativeChange({ target: { value: '2026-01-05' } } as never);
    expect(emitted).toEqual(['2026-01-05']);
    fixture.componentInstance.clear({ stopPropagation: () => {} } as never);
    expect(emitted).toEqual(['2026-01-05', '']);
  });

  it('blocks manual typing but allows Tab/Escape/Shift', () => {
    const fixture = create();
    const prevented: string[] = [];
    const key = (k: string) => ({ key: k, preventDefault: () => prevented.push(k) });
    fixture.componentInstance.onKeydown(key('Tab') as never);
    fixture.componentInstance.onKeydown(key('Escape') as never);
    fixture.componentInstance.onKeydown(key('a') as never);
    expect(prevented).toEqual(['a']);
  });

  it('opens the native picker when supported, falls back to focus otherwise', () => {
    const fixture = create();
    const focus = vi.fn();
    const showPicker = vi.fn();
    const native = { focus, showPicker } as unknown as HTMLInputElement;
    fixture.componentInstance.nativeInput = { nativeElement: native };

    fixture.componentInstance.openPicker();
    expect(showPicker).toHaveBeenCalled();

    // showPicker throwing falls back to focus.
    showPicker.mockImplementation(() => {
      throw new Error('not allowed');
    });
    fixture.componentInstance.openPicker();
    expect(focus).toHaveBeenCalled();

    // No native input at all is a no-op.
    fixture.componentInstance.nativeInput = undefined;
    fixture.componentInstance.openPicker();
    expect(focus).toHaveBeenCalledTimes(1);

    // Disabled inputs never open.
    fixture.componentInstance.disabled = true;
    fixture.componentInstance.nativeInput = { nativeElement: { focus, showPicker } } as never;
    fixture.componentInstance.openPicker();
    expect(focus).toHaveBeenCalledTimes(1);
    expect(showPicker).toHaveBeenCalledTimes(2);
  });
});

describe('AttachmentService', () => {
  let service: AttachmentService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(AttachmentService);
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  it('load returns the blob for a 200 response', async () => {
    const blob = new Blob(['%PDF']);
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({ ok: true, blob: () => Promise.resolve(blob) }),
    );
    await expect(service.load('/uploads/a.pdf')).resolves.toBe(blob);
  });

  it('load rejects with AttachmentMissingError on 404 and on network failure', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false, status: 404 }));
    await expect(service.load('/uploads/gone.pdf')).rejects.toBeInstanceOf(
      AttachmentMissingError,
    );

    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new TypeError('network')));
    await expect(service.load('/uploads/down.pdf')).rejects.toBeInstanceOf(
      AttachmentMissingError,
    );
  });

  it('download creates an anchor with the filename and revokes the object URL', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        blob: () => Promise.resolve(new Blob(['x'])),
      }),
    );
    const appended: HTMLElement[] = [];
    const created: HTMLAnchorElement[] = [];
    const originalCreate = document.createElement.bind(document);
    vi.spyOn(document, 'createElement').mockImplementation((tag: string) => {
      const el = originalCreate(tag);
      if (tag === 'a') created.push(el as HTMLAnchorElement);
      return el;
    });
    vi.spyOn(document.body, 'appendChild').mockImplementation(((el: HTMLElement) => {
      appended.push(el);
      return el;
    }) as never);
    const revoke = vi.fn();
    vi.stubGlobal('URL', { createObjectURL: () => 'blob:obj', revokeObjectURL: revoke });
    vi.useFakeTimers();

    await service.download('/uploads/a.pdf', 'deed.pdf');
    expect(created).toHaveLength(1);
    expect(created[0].download).toBe('deed.pdf');
    expect(appended).toHaveLength(1);
    vi.advanceTimersByTime(1100);
    expect(revoke).toHaveBeenCalledWith('blob:obj');
    vi.useRealTimers();
  });

  it('download propagates AttachmentMissingError', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false, status: 404 }));
    await expect(service.download('/uploads/gone.pdf', 'x.pdf')).rejects.toBeInstanceOf(
      AttachmentMissingError,
    );
  });
});
