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
  width: 640,
  height: 1010,
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

/** Logical card scale used for the exported PNG (2x = ~1300 dpi at CR80). */
const EXPORT_SCALE = 2;

const FONT = '"Hind Siliguri", "Noto Sans Bengali", sans-serif';

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
    this.roundRect(ctx, 0, 0, W, CARD.height, 24);
    ctx.fillStyle = CARD.white;
    ctx.fill();
    ctx.save();
    ctx.clip();

    // Header band with society identity
    const header = ctx.createLinearGradient(0, 0, W, 175);
    header.addColorStop(0, CARD.green900);
    header.addColorStop(1, CARD.green700);
    ctx.fillStyle = header;
    ctx.fillRect(0, 0, W, 175);
    ctx.fillStyle = CARD.gold;
    ctx.fillRect(0, 175, W, 5);

    ctx.beginPath();
    ctx.arc(88, 84, 46, 0, Math.PI * 2);
    ctx.fillStyle = CARD.cream;
    ctx.fill();
    if (logoImg) {
      this.drawCover(ctx, logoImg, 52, 48, 72, 72);
    } else {
      this.drawLogoFallback(ctx, 88, 84);
    }

    ctx.fillStyle = CARD.cream;
    ctx.textAlign = 'left';
    ctx.textBaseline = 'alphabetic';
    ctx.font = `700 30px ${FONT}`;
    ctx.fillText(this.instant('idCard.societyName'), 156, 76);
    ctx.font = `500 17px ${FONT}`;
    ctx.fillStyle = CARD.goldLight;
    this.wrapText(ctx, this.instant('idCard.societyOrg'), 156, 106, W - 186, 24, 2);

    ctx.font = `600 15px ${FONT}`;
    ctx.fillStyle = 'rgba(247, 243, 232, 0.75)';
    ctx.textAlign = 'right';
    ctx.fillText(this.instant('idCard.cardTitleEn').toUpperCase(), W - 36, 158);
    ctx.textAlign = 'left';

    // Photo overlapping the header
    const photo = { x: W / 2 - 95, y: 118, w: 190, h: 228 };
    ctx.save();
    ctx.shadowColor = 'rgba(18, 39, 24, 0.35)';
    ctx.shadowBlur = 18;
    ctx.shadowOffsetY = 6;
    this.roundRect(ctx, photo.x, photo.y, photo.w, photo.h, 14);
    ctx.fillStyle = CARD.white;
    ctx.fill();
    ctx.restore();

    ctx.save();
    ctx.beginPath();
    this.roundRectPath(ctx, photo.x + 6, photo.y + 6, photo.w - 12, photo.h - 12, 10);
    ctx.clip();
    if (photoImg) {
      this.drawCover(ctx, photoImg, photo.x + 6, photo.y + 6, photo.w - 12, photo.h - 12);
    } else {
      ctx.fillStyle = CARD.cream;
      ctx.fillRect(photo.x + 6, photo.y + 6, photo.w - 12, photo.h - 12);
      ctx.fillStyle = CARD.green700;
      ctx.font = `700 84px ${FONT}`;
      ctx.textAlign = 'center';
      ctx.fillText(this.initialOf(profile.fullName), W / 2, photo.y + 138);
      ctx.textAlign = 'left';
    }
    ctx.restore();

    // Name + member id chip
    ctx.textAlign = 'center';
    ctx.fillStyle = CARD.green900;
    ctx.font = `700 30px ${FONT}`;
    const nameY = photo.y + photo.h + 52;
    this.wrapText(ctx, profile.fullName, W / 2, nameY, W - 120, 36, 2);

    const chipY = nameY + 22;
    const chipText = profile.memberId;
    ctx.font = `700 20px ${FONT}`;
    const chipW = ctx.measureText(chipText).width + 44;
    this.roundRect(ctx, W / 2 - chipW / 2, chipY, chipW, 36, 18);
    ctx.fillStyle = CARD.green900;
    ctx.fill();
    ctx.fillStyle = CARD.goldLight;
    ctx.fillText(chipText, W / 2, chipY + 25);

    // Detail rows
    const rows: { label: string; value: string }[] = [
      { label: this.instant('idCard.dob'), value: this.formatDate(profile.dob) },
      { label: this.instant('idCard.mobile'), value: profile.mobile || '—' },
      { label: this.instant('idCard.nid'), value: profile.nid || '—' },
      { label: this.instant('idCard.address'), value: this.shortAddress(profile) },
    ];
    let y = chipY + 100;
    ctx.textAlign = 'left';
    for (const row of rows) {
      ctx.font = `600 15px ${FONT}`;
      ctx.fillStyle = CARD.gold;
      ctx.fillText(row.label.toUpperCase(), 56, y);
      ctx.font = `500 19px ${FONT}`;
      ctx.fillStyle = CARD.ink;
      y = this.wrapText(ctx, row.value, 56, y + 26, W - 112, 26, 2) + 24;
    }

    // QR + verify caption
    const qrSize = 116;
    const qrX = 56;
    const qrY = CARD.height - 232;
    ctx.drawImage(qrCanvas, qrX, qrY, qrSize, qrSize);
    ctx.font = `500 14px ${FONT}`;
    ctx.fillStyle = CARD.inkSoft;
    ctx.fillText(this.instant('idCard.verify'), qrX + qrSize + 14, qrY + qrSize / 2 + 4);

    // Status ribbon
    if (profile.status) {
      ctx.textAlign = 'right';
      ctx.font = `700 15px ${FONT}`;
      ctx.fillStyle = CARD.green700;
      ctx.fillText(this.instant('idCard.status.' + profile.status.toLowerCase(), profile.status), W - 56, qrY + qrSize / 2 + 4);
      ctx.textAlign = 'left';
    }

    // Footer band
    ctx.fillStyle = CARD.green900;
    ctx.fillRect(0, CARD.height - 52, W, 52);
    ctx.fillStyle = CARD.gold;
    ctx.fillRect(0, CARD.height - 52, W, 3);
    ctx.fillStyle = CARD.cream;
    ctx.font = `600 16px ${FONT}`;
    ctx.textAlign = 'center';
    ctx.fillText(this.instant('idCard.footer'), W / 2, CARD.height - 18);
    ctx.textAlign = 'left';

    ctx.restore();
  }

  private drawBack(ctx: CanvasRenderingContext2D, profile: MemberProfile, signatureImg: HTMLImageElement | null): void {
    const W = CARD.width;
    this.roundRect(ctx, 0, 0, W, CARD.height, 24);
    ctx.fillStyle = CARD.white;
    ctx.fill();
    ctx.save();
    ctx.clip();

    const header = ctx.createLinearGradient(0, 0, W, 96);
    header.addColorStop(0, CARD.green900);
    header.addColorStop(1, CARD.green700);
    ctx.fillStyle = header;
    ctx.fillRect(0, 0, W, 96);
    ctx.fillStyle = CARD.gold;
    ctx.fillRect(0, 96, W, 4);
    ctx.fillStyle = CARD.cream;
    ctx.font = `700 22px ${FONT}`;
    ctx.textAlign = 'left';
    ctx.fillText(this.instant('idCard.backTitle'), 48, 58);
    ctx.font = `600 15px ${FONT}`;
    ctx.fillStyle = CARD.goldLight;
    ctx.textAlign = 'right';
    ctx.fillText(profile.memberId, W - 48, 58);
    ctx.textAlign = 'left';

    let y = 160;
    const section = (title: string, lines: { label: string; value: string }[]) => {
      ctx.font = `700 16px ${FONT}`;
      ctx.fillStyle = CARD.gold;
      ctx.fillText(title, 48, y);
      y += 30;
      for (const line of lines) {
        ctx.font = `500 17px ${FONT}`;
        ctx.fillStyle = CARD.inkSoft;
        ctx.fillText(line.label, 48, y);
        ctx.textAlign = 'right';
        ctx.fillStyle = CARD.ink;
        ctx.font = `600 17px ${FONT}`;
        this.wrapText(ctx, line.value, W - 48, y, W / 2 - 60, 24, 2);
        ctx.textAlign = 'left';
        y += 30;
      }
      y += 18;
    };

    section(this.instant('idCard.sectionPersonal'), [
      { label: this.instant('idCard.father'), value: profile.fatherOrHusband || '—' },
      { label: this.instant('idCard.nid'), value: profile.nid || '—' },
    ]);
    section(this.instant('idCard.sectionContact'), [
      { label: this.instant('idCard.mobile'), value: profile.mobile || '—' },
      {
        label: this.instant('idCard.emergency'),
        value: profile.urgentContactMobile
          ? `${profile.urgentContactName ? profile.urgentContactName + ' · ' : ''}${profile.urgentContactMobile}`
          : '—',
      },
    ]);
    section(this.instant('idCard.sectionMembership'), [
      { label: this.instant('idCard.issuedOn'), value: this.formatDate(profile.submissionDate) },
      { label: this.instant('idCard.receiptNo'), value: profile.receiptNo || '—' },
    ]);

    // Full address block
    ctx.font = `700 16px ${FONT}`;
    ctx.fillStyle = CARD.gold;
    ctx.fillText(this.instant('idCard.address'), 48, y);
    y += 30;
    ctx.font = `500 17px ${FONT}`;
    ctx.fillStyle = CARD.ink;
    y = this.wrapText(ctx, this.fullAddress(profile), 48, y, W - 96, 25, 4);
    y += 26;

    // Terms
    ctx.font = `400 14px ${FONT}`;
    ctx.fillStyle = CARD.inkSoft;
    y = this.wrapText(ctx, this.instant('idCard.terms'), 48, y, W - 96, 21, 4);

    // Signature + authority line
    const sigLineY = CARD.height - 130;
    if (signatureImg) {
      const sigW = 150;
      const sigH = Math.min(64, (signatureImg.height / signatureImg.width) * sigW);
      ctx.drawImage(signatureImg, W - 232, sigLineY - sigH - 8, sigW, sigH);
    }
    ctx.strokeStyle = CARD.line;
    ctx.lineWidth = 1.5;
    ctx.beginPath();
    ctx.moveTo(W - 252, sigLineY);
    ctx.lineTo(W - 48, sigLineY);
    ctx.stroke();
    ctx.font = `500 15px ${FONT}`;
    ctx.fillStyle = CARD.inkSoft;
    ctx.textAlign = 'center';
    ctx.fillText(this.instant('idCard.authority'), W - 150, sigLineY + 26);

    ctx.fillStyle = CARD.green900;
    ctx.fillRect(0, CARD.height - 52, W, 52);
    ctx.fillStyle = CARD.gold;
    ctx.fillRect(0, CARD.height - 52, W, 3);
    ctx.fillStyle = CARD.cream;
    ctx.font = `600 16px ${FONT}`;
    ctx.fillText(this.instant('idCard.footer'), W / 2, CARD.height - 18);
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
