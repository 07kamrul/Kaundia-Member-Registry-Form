import { AttachmentMissingError, AttachmentService } from './attachment.service';

describe('AttachmentService', () => {
  const service = new AttachmentService();

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it('resolves with the response body as a blob', async () => {
    const blob = new Blob(['%PDF']);
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({ ok: true, blob: () => Promise.resolve(blob) }),
    );

    await expect(service.load('https://api.example.com/uploads/a.pdf')).resolves.toBe(blob);
  });

  it('rejects with AttachmentMissingError when the file is gone', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false, status: 404 }));

    await expect(service.load('https://api.example.com/uploads/a.pdf')).rejects.toBeInstanceOf(
      AttachmentMissingError,
    );
  });

  it('rejects with AttachmentMissingError when the request never completes', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new TypeError('Failed to fetch')));

    await expect(service.load('https://api.example.com/uploads/a.pdf')).rejects.toBeInstanceOf(
      AttachmentMissingError,
    );
  });

  it('downloads the fetched blob under the requested filename', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        blob: () => Promise.resolve(new Blob(['data'])),
      }),
    );
    (URL as unknown as Record<string, unknown>)['createObjectURL'] = vi.fn(() => 'blob:download');
    (URL as unknown as Record<string, unknown>)['revokeObjectURL'] = vi.fn();

    let anchor: HTMLAnchorElement | null = null;
    const click = vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(function (
      this: HTMLAnchorElement,
    ) {
      anchor = this;
    });

    await service.download('https://api.example.com/uploads/a.pdf', 'khajna_kar_rashid.pdf');

    expect(click).toHaveBeenCalledTimes(1);
    expect(anchor).not.toBeNull();
    expect((anchor as unknown as HTMLAnchorElement).download).toBe('khajna_kar_rashid.pdf');
    expect((anchor as unknown as HTMLAnchorElement).href).toBe('blob:download');
    expect(document.body.contains(anchor as unknown as HTMLAnchorElement)).toBe(false);
  });
});
