import { ChangeDetectionStrategy, Component, OnInit, computed, inject, signal } from '@angular/core';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { TranslatePipe } from '@ngx-translate/core';
import { FormsModule } from '@angular/forms';
import { IconComponent } from '../../../../shared/icon/icon.component';
import { LanguageService } from '../../../../core/services/language.service';
import { AuthService } from '../../../../core/services/auth.service';
import {
  ResolutionBookService,
  attendanceStatusLabel,
  formatFileSize,
  formatRbDate,
  localizeDigits,
  meetingStatusLabel,
  meetingTypeLabel,
  recordingTypeLabel,
  resolutionStatusLabel,
  type MeetingDetail,
  type Recording,
  type ResolutionStatus,
} from '../../../../core/services/resolution-book.service';

const OBJECT_URL_REVOKE_MS = 1000;
const TABS = ['overview', 'attendance', 'resolutions', 'recordings'] as const;
type Tab = (typeof TABS)[number];

function saveBlob(blob: Blob, filename: string): void {
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement('a');
  anchor.href = url;
  anchor.download = filename;
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
  setTimeout(() => URL.revokeObjectURL(url), OBJECT_URL_REVOKE_MS);
}

@Component({
  selector: 'app-meeting-detail',
  standalone: true,
  imports: [TranslatePipe, IconComponent, RouterLink, FormsModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './meeting-detail.component.html',
  styleUrl: './meeting-detail.component.scss',
})
export class MeetingDetailComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly service = inject(ResolutionBookService);
  private readonly language = inject(LanguageService);
  readonly auth = inject(AuthService);

  readonly meetingId = signal<number | null>(null);
  readonly meeting = signal<MeetingDetail | null>(null);
  readonly loading = signal(true);
  readonly error = signal(false);
  readonly tab = signal<Tab>('overview');
  readonly pdfBusy = signal(false);
  readonly exportError = signal('');
  readonly statusSaving = signal<number | null>(null);
  readonly uploadBusy = signal(false);
  readonly uploadError = signal('');
  readonly tabs = TABS;

  readonly lang = this.language.lang;
  readonly canManage = computed(() => this.auth.hasPermission('manage_resolution_book'));
  readonly attendancePercent = computed(() => this.meeting()?.attendancePercent ?? 0);

  ngOnInit(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    if (!Number.isFinite(id) || id <= 0) {
      this.router.navigate(['/resolution-book']);
      return;
    }
    this.meetingId.set(id);
    this.load();
  }

  load(): void {
    const id = this.meetingId();
    if (id === null) return;
    this.loading.set(true);
    this.error.set(false);
    this.service.getMeeting(id).subscribe({
      next: (data) => {
        this.meeting.set(data);
        this.loading.set(false);
      },
      error: () => {
        this.error.set(true);
        this.loading.set(false);
      },
    });
  }

  setTab(tab: Tab): void {
    this.tab.set(tab);
  }

  digits(value: number | string): string {
    return localizeDigits(value, this.lang());
  }

  date(iso: string | null): string {
    return formatRbDate(iso, this.lang());
  }

  typeLabel(type: MeetingDetail['meetingType']): string {
    return meetingTypeLabel(type, this.lang());
  }

  statusLabel(status: MeetingDetail['status']): string {
    return meetingStatusLabel(status, this.lang());
  }

  resolutionStatusLabel(status: ResolutionStatus): string {
    return resolutionStatusLabel(status, this.lang());
  }

  attendanceStatusLabel(status: 'present' | 'absent'): string {
    return attendanceStatusLabel(status, this.lang());
  }

  recordingTypeLabel(type: Recording['fileType']): string {
    return recordingTypeLabel(type, this.lang());
  }

  fileSize(bytes: number): string {
    return formatFileSize(bytes, this.lang());
  }

  downloadPdf(): void {
    const id = this.meetingId();
    if (id === null) return;
    this.pdfBusy.set(true);
    this.exportError.set('');
    this.service.downloadPdf(id).subscribe({
      next: (blob) => {
        saveBlob(blob, `minutes-${this.meeting()?.meetingNo ?? id}.pdf`);
        this.pdfBusy.set(false);
      },
      error: () => {
        this.exportError.set('rb.exportError');
        this.pdfBusy.set(false);
      },
    });
  }

  setResolutionStatus(resolutionId: number, status: ResolutionStatus): void {
    this.statusSaving.set(resolutionId);
    this.service.updateResolution(resolutionId, { status }).subscribe({
      next: (updated) => {
        const current = this.meeting();
        if (current) {
          this.meeting.set({
            ...current,
            resolutions: current.resolutions.map((r) => (r.id === updated.id ? updated : r)),
          });
        }
        this.statusSaving.set(null);
      },
      error: () => this.statusSaving.set(null),
    });
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    input.value = '';
    if (file) this.uploadFile(file);
  }

  uploadFile(file: File): void {
    const id = this.meetingId();
    if (id === null) return;
    this.uploadBusy.set(true);
    this.uploadError.set('');
    this.service.uploadRecording(id, file).subscribe({
      next: (recording) => {
        const current = this.meeting();
        if (current) {
          this.meeting.set({ ...current, recordings: [...current.recordings, recording] });
        }
        this.uploadBusy.set(false);
      },
      error: (err) => {
        this.uploadError.set(err?.error?.detail || 'rb.recordings.uploadError');
        this.uploadBusy.set(false);
      },
    });
  }

  downloadRecording(recording: Recording): void {
    this.service.downloadRecording(recording.id).subscribe({
      next: (blob) => saveBlob(blob, recording.originalName),
      error: () => this.uploadError.set('rb.recordings.downloadError'),
    });
  }
}
