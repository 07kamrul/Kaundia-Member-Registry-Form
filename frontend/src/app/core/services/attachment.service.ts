import { Injectable } from '@angular/core';

/**
 * The server did not return the attachment (404/403/5xx, or the request never
 * made it). Thrown instead of navigating to the raw file URL, so callers can
 * fall back to the app's own error UI rather than the backend's JSON body.
 */
export class AttachmentMissingError extends Error {
  constructor(readonly url: string) {
    super(`Attachment not available: ${url}`);
    this.name = 'AttachmentMissingError';
  }
}

/**
 * Fetches attachments as blobs so preview/download flows can tell "the file is
 * gone" apart from "the viewer could not render it", and so downloads behave
 * like `Content-Disposition: attachment` instead of a bare link navigation.
 */
@Injectable({ providedIn: 'root' })
export class AttachmentService {
  /** Load an attachment; rejects with `AttachmentMissingError` when it is absent. */
  async load(url: string): Promise<Blob> {
    let response: Response;
    try {
      response = await fetch(url, { credentials: 'omit' });
    } catch {
      throw new AttachmentMissingError(url);
    }
    if (!response.ok) throw new AttachmentMissingError(url);
    return response.blob();
  }

  /**
   * Save the attachment to the user's device via an object URL. The anchor
   * `download` attribute forces a download (no navigation, no inline viewer),
   * and a missing file surfaces as `AttachmentMissingError` for the caller's
   * in-app error message.
   */
  async download(url: string, filename: string): Promise<void> {
    const blob = await this.load(url);
    const objectUrl = URL.createObjectURL(blob);
    try {
      const anchor = document.createElement('a');
      anchor.href = objectUrl;
      anchor.download = filename;
      anchor.rel = 'noopener';
      document.body.appendChild(anchor);
      anchor.click();
      anchor.remove();
    } finally {
      // Revoke after the download has been handed to the browser; doing it
      // synchronously can cancel the transfer in some engines.
      setTimeout(() => URL.revokeObjectURL(objectUrl), 1000);
    }
  }
}
