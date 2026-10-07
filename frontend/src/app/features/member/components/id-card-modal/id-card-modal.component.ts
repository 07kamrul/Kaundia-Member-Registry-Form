import {
  ChangeDetectionStrategy,
  Component,
  EventEmitter,
  Input,
  OnInit,
  Output,
  signal,
} from '@angular/core';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import QRCode from 'qrcode';
import { MemberProfile, MemberService } from '../../../../core/services/member.service';
import { AttachmentService } from '../../../../core/services/attachment.service';
import { IconComponent } from '../../../../shared/icon/icon.component';

/**
 * Fixed print-style palette (independent of the light/dark theme) so the card
 * looks like the physical card it stands in for, on screen and in the PNG.
 */
const CARD = {
  width: 1010,
  height: 640,
  green900: '#122718',
  green700: '#1f3d2a',
  gold: '#a9791e',
  goldLight: '#e6cf94',
  cream: '#f7f3e8',
  white: '#ffffff',
  ink: '#1f2937',
  inkSoft: '#4b5563',
  line: '#d8d2c2',
};

const FONT = '"Hind Siliguri", "Noto Sans Bengali", sans-serif';

/** Logical card scale used for the exported PNG (2x ≈ print quality at CR80). */
const EXPORT_SCALE = 2;

@Component({
  selector: 'app-id-card-modal',
  standalone: true,
  imports: [IconComponent, TranslatePipe],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './id-card-modal.component.html',
  styleUrl: './id-card-modal.component.scss',
  host: {'(document:keydown.escape)': 'close()'},
})
export class IdCardModalComponent implements OnInit {
  @Input() open = false;
  @Output() closed = new EventEmitter<void>();

  readonly loading = signal(false);
  readonly loadError = signal(false);
  readonly downloading = signal(false);
  readonly downloadError = signal(false);
  readonly profile = signal<MemberProfile | null>(null);
  /** The stored photo URL 404'd (file lost on disk): show the initial instead. */
  readonly photoFailed = signal(false);

  constructor(
    private memberService: MemberService,
    private attachments: AttachmentService,
    private translate: TranslateService,
  ) {}

  /** The shell keeps the component alive only while the modal is open. */
  ngOnInit(): void {
    this.load();
  }

  close(): void {
    if (this.downloading()) return;
    this.closed.emit();
  }

  onBackdropClick(event: MouseEvent): void {
    if (event.target === event.currentTarget) this.close();
  }

  /** Lazy-loads (cached) the profile the first time the modal is opened. */
  load(): void {
    if (this.profile() || this.loading() || this.loadError()) return;
    this.loading.set(true);
    this.memberService.getProfile().subscribe({
      next: (profile) => {
        this.profile.set(profile);
        this.loading.set(false);
      },
      error: () => {
        this.loadError.set(true);
        this.loading.set(false);
      },
    });
  }

  async download(): Promise<void> {
    const profile = this.profile();
    if (!profile || this.downloading()) return;
    this.downloading.set(true);
    this.downloadError.set(false);
    try {
      const [photoImg, signatureImg, logoImg] = await Promise.all([
        this.loadRemoteImage(profile.memberPhotoUrl),
        this.loadSignature(profile.memberSignature),
        this.loadLocalImage('/images/logo.jpeg'),
      ]);
      const qrCanvas = await this.renderQr(profile);

      await document.fonts.load(`700 30px ${FONT}`);
      await document.fonts.load(`400 18px ${FONT}`);
      await document.fonts.ready;

      const gap = 32 * EXPORT_SCALE;
      const canvas = document.createElement('canvas');
      canvas.width = CARD.width * EXPORT_SCALE;
      canvas.height = CARD.height * 2 * EXPORT_SCALE + gap;
      const ctx = canvas.getContext('2d')!;
      ctx.scale(EXPORT_SCALE, EXPORT_SCALE);
      this.drawFront(ctx, profile, photoImg, qrCanvas, logoImg);
      ctx.setTransform(EXPORT_SCALE, 0, 0, EXPORT_SCALE, 0, CARD.height * EXPORT_SCALE + gap);
      this.drawBack(ctx, profile, signatureImg);

      const blob: Blob | null = await new Promise((resolve) => canvas.toBlob(resolve, 'image/png'));
      if (!blob) throw new Error('toBlob failed');
      const url = URL.createObjectURL(blob);
      this.saveBlob(url, `id-card-${profile.memberId || 'member'}.png`);
      setTimeout(() => URL.revokeObjectURL(url), 1000);
    } catch {
      this.downloadError.set(true);
    } finally {
      this.downloading.set(false);
    }
  }

  private saveBlob(objectUrl: string, filename: string): void {
    const anchor = document.createElement('a');
    anchor.href = objectUrl;
    anchor.download = filename;
    anchor.rel = 'noopener';
    document.body.appendChild(anchor);
    anchor.click();
    anchor.remove();
  }

  /** Photos live on the API origin, so fetch them as blobs to keep the canvas untainted. */
  private async loadRemoteImage(url?: string): Promise<HTMLImageElement | null> {
    if (!url) return null;
    try {
      const blob = await this.attachments.load(url);
      return await this.decodeImage(URL.createObjectURL(blob));
    } catch {
      return null;
    }
  }

  /** Same-origin static assets can be drawn directly without tainting the canvas. */
  private async loadLocalImage(url: string): Promise<HTMLImageElement | null> {
    try {
      return await this.decodeImage(url);
    } catch {
      return null;
    }
  }

  /** The member's signature is stored inline as a data URL, not a file. */
  private async loadSignature(dataUrl?: string): Promise<HTMLImageElement | null> {
    if (!dataUrl || !dataUrl.startsWith('data:image')) return null;
    try {
      return await this.decodeImage(dataUrl);
    } catch {
      return null;
    }
  }

  private decodeImage(src: string): Promise<HTMLImageElement> {
    return new Promise((resolve, reject) => {
      const img = new Image();
      img.onload = () => resolve(img);
      img.onerror = reject;
      img.src = src;
    });
  }

  private async renderQr(profile: MemberProfile): Promise<HTMLCanvasElement> {
    const canvas = document.createElement('canvas');
    await QRCode.toCanvas(
      canvas,
      `KAUNDIA|${profile.memberId}|${profile.fullName}`,
      { width: 240, margin: 1, errorCorrectionLevel: 'M' },
    );
    return canvas;
  }

  // ---------------------------------------------------------------- drawing

  private drawFront(
    ctx: CanvasRenderingContext2D,
    profile: MemberProfile,
    photoImg: HTMLImageElement | null,
    qrCanvas: HTMLCanvasElement,
    logoImg: HTMLImageElement | null,
  ): void {
    const W = CARD.width;
    const H = CARD.height;
    this.roundRect(ctx, 0, 0, W, H, 24);
    ctx.fillStyle = CARD.white;
    ctx.fill();
    ctx.save();
    ctx.clip();

    // Header band with society identity
    const header = ctx.createLinearGradient(0, 0, W, 110);
    header.addColorStop(0, CARD.green900);
    header.addColorStop(1, CARD.green700);
    ctx.fillStyle = header;
    ctx.fillRect(0, 0, W, 110);
    ctx.fillStyle = CARD.gold;
    ctx.fillRect(0, 110, W, 4);

    ctx.beginPath();
    ctx.arc(72, 57, 36, 0, Math.PI * 2);
    ctx.fillStyle = CARD.cream;
    ctx.fill();
    if (logoImg) {
      this.drawCover(ctx, logoImg, 42, 27, 60, 60);
    } else {
      this.drawLogoFallback(ctx, 72, 57);
    }

    ctx.fillStyle = CARD.cream;
    ctx.textAlign = 'left';
    ctx.textBaseline = 'alphabetic';
    ctx.font = `700 26px ${FONT}`;
    ctx.fillText(this.instant('idCard.societyName'), 126, 50);
    ctx.font = `500 15px ${FONT}`;
    ctx.fillStyle = CARD.goldLight;
    this.wrapText(ctx, this.instant('idCard.societyOrg'), 126, 78, 560, 20, 2);

    // "MEMBER ID CARD" pill, right side of the header
    ctx.font = `700 15px ${FONT}`;
    const kind = this.instant('idCard.cardTitleEn').toUpperCase();
    const kindW = ctx.measureText(kind).width + 28;
    this.roundRect(ctx, W - 40 - kindW, 40, kindW, 34, 17);
    ctx.strokeStyle = 'rgba(230, 207, 148, 0.5)';
    ctx.lineWidth = 1.5;
    ctx.stroke();
    ctx.fillStyle = 'rgba(247, 243, 232, 0.85)';
    ctx.textAlign = 'center';
    ctx.fillText(kind, W - 40 - kindW / 2, 62);
    ctx.textAlign = 'left';

    // Membership status under the header, right-aligned
    if (profile.status) {
      ctx.font = `700 16px ${FONT}`;
      ctx.fillStyle = CARD.green700;
      ctx.textAlign = 'right';
      ctx.fillText(this.instant('idCard.status.' + profile.status.toLowerCase(), profile.status), W - 44, 152);
      ctx.textAlign = 'left';
    }

    // Photo, left column
    const photo = { x: 48, y: 152, w: 204, h: 252 };
    ctx.save();
    ctx.shadowColor = 'rgba(18, 39, 24, 0.3)';
    ctx.shadowBlur = 14;
    ctx.shadowOffsetY = 5;
    this.roundRect(ctx, photo.x, photo.y, photo.w, photo.h, 12);
    ctx.fillStyle = CARD.white;
    ctx.fill();
    ctx.restore();

    ctx.save();
    ctx.beginPath();
    this.roundRectPath(ctx, photo.x + 5, photo.y + 5, photo.w - 10, photo.h - 10, 9);
    ctx.clip();
    if (photoImg) {
      this.drawCover(ctx, photoImg, photo.x + 5, photo.y + 5, photo.w - 10, photo.h - 10);
    } else {
      ctx.fillStyle = CARD.cream;
      ctx.fillRect(photo.x + 5, photo.y + 5, photo.w - 10, photo.h - 10);
      ctx.fillStyle = CARD.green700;
      ctx.font = `700 92px ${FONT}`;
      ctx.textAlign = 'center';
      ctx.fillText(this.initialOf(profile.fullName), photo.x + photo.w / 2, photo.y + 158);
      ctx.textAlign = 'left';
    }
    ctx.restore();

    // Name + member id chip
    ctx.fillStyle = CARD.green900;
    ctx.font = `700 30px ${FONT}`;
    this.wrapText(ctx, profile.fullName, 296, 200, W - 296 - 300, 36, 2);

    const chipY = 216;
    ctx.font = `700 18px ${FONT}`;
    const chipW = ctx.measureText(profile.memberId).width + 36;
    this.roundRect(ctx, 296, chipY, chipW, 34, 17);
    ctx.fillStyle = CARD.green900;
    ctx.fill();
    ctx.fillStyle = CARD.goldLight;
    ctx.fillText(profile.memberId, 296 + 18, chipY + 24);

    // Detail grid: 2 columns, gold accent bars
    const cells: { x: number; y: number; label: string; value: string; wide?: boolean }[] = [
      { x: 296, y: 296, label: this.instant('idCard.dob'), value: this.formatDate(profile.dob) },
      { x: 660, y: 296, label: this.instant('idCard.mobile'), value: profile.mobile || '—' },
      { x: 296, y: 372, label: this.instant('idCard.nid'), value: profile.nid || '—' },
      { x: 660, y: 372, label: this.instant('idCard.address'), value: this.shortAddress(profile), wide: true },
    ];
    for (const cell of cells) {
      ctx.fillStyle = CARD.gold;
      ctx.fillRect(cell.x, cell.y - 13, 4, 40);
      ctx.font = `700 14px ${FONT}`;
      ctx.fillStyle = CARD.gold;
      ctx.fillText(cell.label.toUpperCase(), cell.x + 14, cell.y);
      ctx.font = `600 19px ${FONT}`;
      ctx.fillStyle = CARD.ink;
      const maxW = cell.wide ? W - 48 - cell.x - 14 : 320;
      this.wrapText(ctx, cell.value, cell.x + 14, cell.y + 26, maxW, 24, 2);
    }

    // QR + verify caption
    const qrSize = 112;
    const qrX = W - 48 - qrSize;
    const qrY = H - 48 - qrSize;
    ctx.drawImage(qrCanvas, qrX, qrY, qrSize, qrSize);
    ctx.font = `500 14px ${FONT}`;
    ctx.fillStyle = CARD.inkSoft;
    ctx.textAlign = 'right';
    ctx.fillText(this.instant('idCard.verify'), qrX - 14, qrY + qrSize / 2 + 4);
    ctx.textAlign = 'left';

    this.drawWatermark(ctx, W / 2, 330);

    // Footer band
    ctx.fillStyle = CARD.green900;
    ctx.fillRect(0, H - 44, W, 44);
    ctx.fillStyle = CARD.gold;
    ctx.fillRect(0, H - 44, W, 3);
    ctx.fillStyle = CARD.cream;
    ctx.font = `600 15px ${FONT}`;
    ctx.textAlign = 'center';
    ctx.fillText(this.instant('idCard.footer'), W / 2, H - 15);
    ctx.textAlign = 'left';

    ctx.restore();
  }

  /** Faint diagonal society name across the card body. */
  private drawWatermark(ctx: CanvasRenderingContext2D, cx: number, cy: number): void {
    ctx.save();
    ctx.globalAlpha = 0.05;
    ctx.fillStyle = CARD.green900;
    ctx.font = `700 60px ${FONT}`;
    ctx.textAlign = 'center';
    ctx.translate(cx, cy);
    ctx.rotate(-0.22);
    ctx.fillText(this.instant('idCard.societyName'), 0, 0);
    ctx.restore();
  }

  private drawBack(ctx: CanvasRenderingContext2D, profile: MemberProfile, signatureImg: HTMLImageElement | null): void {
    const W = CARD.width;
    const H = CARD.height;
    this.roundRect(ctx, 0, 0, W, H, 24);
    ctx.fillStyle = CARD.white;
    ctx.fill();
    ctx.save();
    ctx.clip();

    const header = ctx.createLinearGradient(0, 0, W, 90);
    header.addColorStop(0, CARD.green900);
    header.addColorStop(1, CARD.green700);
    ctx.fillStyle = header;
    ctx.fillRect(0, 0, W, 90);
    ctx.fillStyle = CARD.gold;
    ctx.fillRect(0, 90, W, 4);
    ctx.fillStyle = CARD.cream;
    ctx.font = `700 22px ${FONT}`;
    ctx.textAlign = 'left';
    ctx.fillText(this.instant('idCard.backTitle'), 48, 54);
    ctx.font = `600 16px ${FONT}`;
    ctx.fillStyle = CARD.goldLight;
    ctx.textAlign = 'right';
    ctx.fillText(profile.memberId, W - 48, 54);
    ctx.textAlign = 'left';

    const colL = { x: 48, right: 468 };
    const colR = { x: 560, right: W - 48 };
    let yL = 136;
    let yR = 136;

    const section = (x: number, right: number, atY: number, title: string, lines: { label: string; value: string }[]): number => {
      let y = atY;
      ctx.font = `700 15px ${FONT}`;
      ctx.fillStyle = CARD.gold;
      ctx.fillText(title, x, y);
      y += 26;
      for (const line of lines) {
        ctx.font = `500 16px ${FONT}`;
        ctx.fillStyle = CARD.inkSoft;
        ctx.fillText(line.label, x, y);
        ctx.textAlign = 'right';
        ctx.fillStyle = CARD.ink;
        ctx.font = `600 16px ${FONT}`;
        this.wrapText(ctx, line.value, right, y, right - x - 150, 22, 1);
        ctx.textAlign = 'left';
        y += 27;
      }
      return y + 16;
    };

    yL = section(colL.x, colL.right, yL, this.instant('idCard.sectionPersonal'), [
      { label: this.instant('idCard.father'), value: profile.fatherOrHusband || '—' },
      { label: this.instant('idCard.nid'), value: profile.nid || '—' },
    ]);
    yL = section(colL.x, colL.right, yL, this.instant('idCard.sectionContact'), [
      { label: this.instant('idCard.mobile'), value: profile.mobile || '—' },
      {
        label: this.instant('idCard.emergency'),
        value: profile.urgentContactMobile
          ? `${profile.urgentContactName ? profile.urgentContactName + ' · ' : ''}${profile.urgentContactMobile}`
          : '—',
      },
    ]);
    yR = section(colR.x, colR.right, yR, this.instant('idCard.sectionMembership'), [
      { label: this.instant('idCard.issuedOn'), value: this.formatDate(profile.submissionDate) },
      { label: this.instant('idCard.receiptNo'), value: profile.receiptNo || '—' },
    ]);

    // Full address, right column
    ctx.font = `700 15px ${FONT}`;
    ctx.fillStyle = CARD.gold;
    ctx.fillText(this.instant('idCard.address'), colR.x, yR);
    yR += 26;
    ctx.font = `500 16px ${FONT}`;
    ctx.fillStyle = CARD.ink;
    yR = this.wrapText(ctx, this.fullAddress(profile), colR.x, yR, colR.right - colR.x, 23, 3);
    yR += 16;

    // Terms, bottom-left
    ctx.font = `400 13px ${FONT}`;
    ctx.fillStyle = CARD.inkSoft;
    this.wrapText(ctx, this.instant('idCard.terms'), colL.x, H - 158, colL.right - colL.x, 19, 4);

    this.drawWatermark(ctx, W / 2, 320);

    // Signature + authority line, bottom-right
    const sigLineY = H - 116;
    if (signatureImg) {
      const sigW = 140;
      const sigH = Math.min(58, (signatureImg.height / signatureImg.width) * sigW);
      ctx.drawImage(signatureImg, W - 238, sigLineY - sigH - 6, sigW, sigH);
    }
    ctx.strokeStyle = CARD.line;
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(W - 258, sigLineY);
    ctx.lineTo(W - 48, sigLineY);
    ctx.stroke();
    ctx.font = `500 14px ${FONT}`;
    ctx.fillStyle = CARD.inkSoft;
    ctx.textAlign = 'center';
    ctx.fillText(this.instant('idCard.authority'), W - 153, sigLineY + 24);
    ctx.textAlign = 'left';

    // Footer band
    ctx.fillStyle = CARD.green900;
    ctx.fillRect(0, H - 44, W, 44);
    ctx.fillStyle = CARD.gold;
    ctx.fillRect(0, H - 44, W, 3);
    ctx.fillStyle = CARD.cream;
    ctx.font = `600 15px ${FONT}`;
    ctx.textAlign = 'center';
    ctx.fillText(this.instant('idCard.footer'), W / 2, H - 15);
    ctx.textAlign = 'left';

    ctx.restore();
  }

  // ---------------------------------------------------------------- helpers

  private roundRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number): void {
    ctx.beginPath();
    this.roundRectPath(ctx, x, y, w, h, r);
  }

  private roundRectPath(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number): void {
    ctx.moveTo(x + r, y);
    ctx.arcTo(x + w, y, x + w, y + h, r);
    ctx.arcTo(x + w, y + h, x, y + h, r);
    ctx.arcTo(x, y + h, x, y, r);
    ctx.arcTo(x, y, x + w, y, r);
    ctx.closePath();
  }

  private drawCover(ctx: CanvasRenderingContext2D, img: HTMLImageElement, x: number, y: number, w: number, h: number): void {
    const ratio = Math.max(w / img.width, h / img.height);
    const dw = img.width * ratio;
    const dh = img.height * ratio;
    ctx.drawImage(img, x + (w - dw) / 2, y + (h - dh) / 2, dw, dh);
  }

  /** Monogram fallback when the logo file cannot be loaded. */
  private drawLogoFallback(ctx: CanvasRenderingContext2D, cx: number, cy: number): void {
    ctx.fillStyle = CARD.green900;
    ctx.font = `700 36px ${FONT}`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText('ইউকে', cx, cy + 2);
    ctx.textBaseline = 'alphabetic';
    ctx.textAlign = 'left';
  }

  private wrapText(
    ctx: CanvasRenderingContext2D,
    text: string,
    x: number,
    y: number,
    maxWidth: number,
    lineHeight: number,
    maxLines: number,
  ): number {
    const words = (text || '—').split(/\s+/);
    let line = '';
    let lines = 0;
    let cursorY = y;
    for (let i = 0; i < words.length; i++) {
      const test = line ? `${line} ${words[i]}` : words[i];
      if (ctx.measureText(test).width > maxWidth && line) {
        ctx.fillText(line, x, cursorY);
        cursorY += lineHeight;
        lines++;
        line = words[i];
        if (lines === maxLines - 1 && i < words.length - 1) {
          line = this.ellipsis(ctx, line, words.slice(i + 1).join(' '), maxWidth);
          break;
        }
      } else {
        line = test;
      }
    }
    ctx.fillText(line, x, cursorY);
    return cursorY;
  }

  private ellipsis(ctx: CanvasRenderingContext2D, line: string, rest: string, maxWidth: number): string {
    let out = `${line} ${rest}`.trim();
    while (out.length > 1 && ctx.measureText(`${out}…`).width > maxWidth) {
      out = out.slice(0, -1);
    }
    return `${out.trim()}…`;
  }

  private initialOf(name: string): string {
    return (name || '').trim().charAt(0) || 'স';
  }

  shortAddress(profile: MemberProfile): string {
    const parts = [
      profile.currentUpazila || profile.permanentUpazila,
      profile.currentDistrict || profile.permanentDistrict,
    ].filter(Boolean);
    return parts.length ? parts.join(', ') : '—';
  }

  fullAddress(profile: MemberProfile): string {
    const c = profile;
    const current = [
      c.currentHouse, c.currentRoad, c.currentPostOffice, c.currentUpazila, c.currentDistrict, c.currentDivision,
    ].filter(Boolean).join(', ');
    if (current) return current;
    return [
      c.permanentHouse, c.permanentRoad, c.permanentPostOffice, c.permanentUpazila, c.permanentDistrict, c.permanentDivision,
    ].filter(Boolean).join(', ') || '—';
  }

  private formatDate(iso?: string): string {
    if (!iso) return '—';
    const date = new Date(iso);
    if (Number.isNaN(date.getTime())) return iso;
    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0');
    return `${day}/${month}/${date.getFullYear()}`;
  }

  private instant(key: string, fallback?: string): string {
    const value = this.translate.instant(key);
    return value === key && fallback !== undefined ? fallback : value;
  }
}
