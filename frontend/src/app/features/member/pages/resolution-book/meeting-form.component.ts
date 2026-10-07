import { ChangeDetectionStrategy, Component, OnInit, computed, effect, inject, signal } from '@angular/core';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { TranslatePipe } from '@ngx-translate/core';
import { FormsModule } from '@angular/forms';
import { IconComponent } from '../../../../shared/icon/icon.component';
import { DatePickerComponent } from '../../../../shared/date-picker/date-picker.component';
import { TimePickerComponent } from '../../../../shared/time-picker/time-picker.component';
import { MemberPickerComponent, type MemberPickerOption } from '../../../../shared/member-picker/member-picker.component';
import { AdminService } from '../../../../core/services/admin.service';
import { LanguageService } from '../../../../core/services/language.service';
import {
  ResolutionBookService,
  localizeDigits,
  type AttendanceStatus,
  type MeetingDetail,
  type MeetingType,
  type ResolutionStatus,
} from '../../../../core/services/resolution-book.service';

const DRAFT_KEY = 'ukams_resolution_book_draft';

interface ResolutionRow {
  decision: string;
  voteFor: number;
  voteAgainst: number;
  voteNeutral: number;
  assignedTo: number[];
  task: string;
  dueDate: string;
  status: ResolutionStatus;
}

interface QueuedFile {
  file: File;
  name: string;
  size: number;
}

function emptyResolution(): ResolutionRow {
  return { decision: '', voteFor: 0, voteAgainst: 0, voteNeutral: 0, assignedTo: [], task: '', dueDate: '', status: 'pending' };
}

@Component({
  selector: 'app-meeting-form',
  standalone: true,
  imports: [
    TranslatePipe,
    IconComponent,
    RouterLink,
    FormsModule,
    DatePickerComponent,
    TimePickerComponent,
    MemberPickerComponent,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './meeting-form.component.html',
  styleUrl: './meeting-form.component.scss',
})
export class MeetingFormComponent implements OnInit {
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly service = inject(ResolutionBookService);
  private readonly adminService = inject(AdminService);
  private readonly language = inject(LanguageService);

  readonly editId = signal<number | null>(null);
  readonly loading = signal(false);
  readonly saving = signal(false);
  readonly error = signal('');
  readonly memberOptions = signal<MemberPickerOption[]>([]);

  // Form state
  readonly meetingNo = signal('');
  readonly meetingNoAuto = signal(true);
  readonly date = signal('');
  readonly time = signal('');
  readonly meetingType = signal<MeetingType>('online');
  readonly chairperson = signal<string>('');
  readonly chairpersonId = signal<number[]>([]);
  readonly agenda = signal('');
  readonly summary = signal('');
  readonly nextMeetingDate = signal('');
  readonly status = signal<'scheduled' | 'completed' | 'cancelled'>('completed');
  readonly attendanceIds = signal<number[]>([]);
  readonly attendanceStatus = signal<Record<number, AttendanceStatus>>({});
  readonly resolutions = signal<ResolutionRow[]>([emptyResolution()]);
  readonly files = signal<QueuedFile[]>([]);
  readonly notify = signal(true);

  readonly lang = this.language.lang;
  readonly agendaMax = 5000;
  readonly summaryMax = 8000;
  readonly maxFileBytes = 100 * 1024 * 1024;

  readonly presentCount = computed(
    () => Object.values(this.attendanceStatus()).filter((status) => status === 'present').length,
  );

  readonly votesInvalid = computed(() =>
    this.resolutions().some(
      (row) => row.voteFor + row.voteAgainst + row.voteNeutral > this.presentCount(),
    ),
  );

  readonly formValid = computed(
    () =>
      this.date() !== '' &&
      this.chairperson().trim() !== '' &&
      this.agenda().trim() !== '' &&
      this.resolutions().every((row) => row.decision.trim() !== ''),
  );

  constructor() {
    // Draft auto-save (same recovery pattern as the registration form).
    effect(() => {
      if (this.editId() !== null || this.saving()) return;
      const draft = {
        meetingNo: this.meetingNo(),
        date: this.date(),
        time: this.time(),
        meetingType: this.meetingType(),
        chairperson: this.chairperson(),
        chairpersonId: this.chairpersonId(),
        agenda: this.agenda(),
        summary: this.summary(),
        nextMeetingDate: this.nextMeetingDate(),
        status: this.status(),
        attendanceIds: this.attendanceIds(),
        attendanceStatus: this.attendanceStatus(),
        resolutions: this.resolutions(),
      };
      try {
        localStorage.setItem(DRAFT_KEY, JSON.stringify(draft));
      } catch {
        // Storage full/unavailable - the draft is best-effort only.
      }
    });
  }

  ngOnInit(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    this.loadMembers();
    if (Number.isFinite(id) && id > 0) {
      this.editId.set(id);
      this.loadMeeting(id);
    } else {
      this.restoreDraft();
      if (!this.date()) {
        this.service.suggestMeetingNo(new Date().toISOString().slice(0, 10)).subscribe({
          next: (suggestion) => {
            if (this.meetingNoAuto()) this.meetingNo.set(suggestion.meetingNo);
          },
        });
      }
    }
  }

  loadMembers(): void {
    this.adminService.listMembers().subscribe({
      next: (members) => {
        this.memberOptions.set(
          members
            .filter((member) => member.status === 'approved')
            .map((member) => ({
              id: Number(member.id),
              fullName: member.fullName,
              memberId: member.memberId,
            })),
        );
      },
      error: () => this.memberOptions.set([]),
    });
  }

  loadMeeting(id: number): void {
    this.loading.set(true);
    this.service.getMeeting(id).subscribe({
      next: (meeting) => {
        this.meetingNo.set(meeting.meetingNo);
        this.meetingNoAuto.set(false);
        this.date.set(meeting.date);
        this.time.set(meeting.time ?? '');
        this.meetingType.set(meeting.meetingType);
        this.chairperson.set(meeting.chairperson);
        this.agenda.set(meeting.agenda);
        this.summary.set(meeting.summary ?? '');
        this.nextMeetingDate.set(meeting.nextMeetingDate ?? '');
        this.status.set(meeting.status);
        this.loading.set(false);
      },
      error: () => {
        this.error.set('rb.loadError');
        this.loading.set(false);
      },
    });
  }

  restoreDraft(): void {
    try {
      const raw = localStorage.getItem(DRAFT_KEY);
      if (!raw) return;
      const draft = JSON.parse(raw) as Partial<{
        meetingNo: string;
        date: string;
        time: string;
        meetingType: MeetingType;
        chairperson: string;
        chairpersonId: number[];
        agenda: string;
        summary: string;
        nextMeetingDate: string;
        status: 'scheduled' | 'completed' | 'cancelled';
        attendanceIds: number[];
        attendanceStatus: Record<number, AttendanceStatus>;
        resolutions: ResolutionRow[];
      }>;
      if (!draft.date && !draft.agenda) return;
      this.meetingNo.set(draft.meetingNo ?? '');
      this.meetingNoAuto.set(!draft.meetingNo);
      this.date.set(draft.date ?? '');
      this.time.set(draft.time ?? '');
      this.meetingType.set(draft.meetingType ?? 'online');
      this.chairperson.set(draft.chairperson ?? '');
      this.chairpersonId.set(draft.chairpersonId ?? []);
      this.agenda.set(draft.agenda ?? '');
      this.summary.set(draft.summary ?? '');
      this.nextMeetingDate.set(draft.nextMeetingDate ?? '');
      this.status.set(draft.status ?? 'completed');
      this.attendanceIds.set(draft.attendanceIds ?? []);
      this.attendanceStatus.set(draft.attendanceStatus ?? {});
      this.resolutions.set(draft.resolutions?.length ? draft.resolutions : [emptyResolution()]);
    } catch {
      // Corrupt draft - start clean.
    }
  }

  discardDraft(): void {
    try {
      localStorage.removeItem(DRAFT_KEY);
    } catch {
      // ignore
    }
  }

  // ----- field handlers -----

  onDateChange(value: string): void {
    this.date.set(value);
    if (this.meetingNoAuto() && value) {
      this.service.suggestMeetingNo(value).subscribe({
        next: (suggestion) => this.meetingNo.set(suggestion.meetingNo),
      });
    }
  }

  editMeetingNo(): void {
    this.meetingNoAuto.set(false);
  }

  onChairpersonChange(ids: number[]): void {
    this.chairpersonId.set(ids);
    const option = this.memberOptions().find((candidate) => candidate.id === ids[0]);
    this.chairperson.set(option?.fullName ?? this.chairperson());
  }

  onAttendanceChange(ids: number[]): void {
    // New picks default to absent; explicit marks win.
    const current = { ...this.attendanceStatus() };
    const next: Record<number, AttendanceStatus> = {};
    for (const id of ids) {
      next[id] = current[id] ?? 'absent';
    }
    this.attendanceIds.set(ids);
    this.attendanceStatus.set(next);
  }

  setAttendanceStatus(memberId: number, status: AttendanceStatus): void {
    this.attendanceStatus.set({ ...this.attendanceStatus(), [memberId]: status });
  }

  markAllPresent(): void {
    const next: Record<number, AttendanceStatus> = {};
    for (const id of this.attendanceIds()) next[id] = 'present';
    this.attendanceStatus.set(next);
  }

  addResolution(): void {
    this.resolutions.set([...this.resolutions(), emptyResolution()]);
  }

  removeResolution(index: number): void {
    const rows = this.resolutions();
    if (rows.length === 1) {
      this.resolutions.set([emptyResolution()]);
    } else {
      this.resolutions.set(rows.filter((_, i) => i !== index));
    }
  }

  updateResolution(index: number, patch: Partial<ResolutionRow>): void {
    this.resolutions.set(
      this.resolutions().map((row, i) => (i === index ? { ...row, ...patch } : row)),
    );
  }

  onFilesSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    const picked = Array.from(input.files ?? []);
    input.value = '';
    const oversized = picked.find((file) => file.size > this.maxFileBytes);
    if (oversized) {
      this.error.set('rb.form.fileTooLarge');
      return;
    }
    this.error.set('');
    this.files.set([...this.files(), ...picked.map((file) => ({ file, name: file.name, size: file.size }))]);
  }

  removeFile(index: number): void {
    this.files.set(this.files().filter((_, i) => i !== index));
  }

  // ----- submit -----

  submit(): void {
    if (!this.formValid() || this.saving()) return;
    this.saving.set(true);
    this.error.set('');

    if (this.editId() !== null) {
      this.service
        .updateMeeting(this.editId()!, {
          date: this.date(),
          time: this.time() || null,
          meeting_type: this.meetingType(),
          chairperson: this.chairperson(),
          chairperson_member_id: this.chairpersonId()[0] ?? null,
          agenda: this.agenda(),
          summary: this.summary() || null,
          next_meeting_date: this.nextMeetingDate() || null,
          status: this.status(),
        })
        .subscribe({
          next: () => {
            this.discardDraft();
            void this.router.navigate(['/resolution-book/meeting', this.editId()]);
          },
          error: (err) => this.fail(err),
        });
      return;
    }

    const attendance = this.attendanceIds().map((memberId) => ({
      memberId,
      status: this.attendanceStatus()[memberId] ?? 'absent',
    }));
    this.service
      .createMeeting({
        meetingNo: this.meetingNoAuto() ? null : this.meetingNo(),
        date: this.date(),
        time: this.time() || null,
        meetingType: this.meetingType(),
        chairperson: this.chairperson(),
        chairpersonMemberId: this.chairpersonId()[0] ?? null,
        agenda: this.agenda(),
        summary: this.summary() || null,
        nextMeetingDate: this.nextMeetingDate() || null,
        status: this.status(),
        attendance,
        resolutions: this.resolutions().map((row) => ({
          decision: row.decision,
          voteFor: Number(row.voteFor) || 0,
          voteAgainst: Number(row.voteAgainst) || 0,
          voteNeutral: Number(row.voteNeutral) || 0,
          assignedToMemberId: row.assignedTo[0] ?? null,
          task: row.task || null,
          dueDate: row.dueDate || null,
          status: row.status,
        })),
        notify: this.notify(),
      })
      .subscribe({
        next: (meeting) => this.uploadQueuedFiles(meeting),
        error: (err) => this.fail(err),
      });
  }

  private uploadQueuedFiles(meeting: MeetingDetail): void {
    const queued = this.files();
    if (queued.length === 0) {
      this.finishCreate(meeting.id);
      return;
    }
    let remaining = queued.length;
    let failed = false;
    for (const item of queued) {
      this.service.uploadRecording(meeting.id, item.file).subscribe({
        next: () => {
          remaining -= 1;
          if (remaining === 0) this.finishCreate(meeting.id);
        },
        error: () => {
          if (!failed) {
            failed = true;
            this.saving.set(false);
            this.error.set('rb.recordings.uploadError');
          }
        },
      });
    }
  }

  private finishCreate(meetingId: number): void {
    this.discardDraft();
    void this.router.navigate(['/resolution-book/meeting', meetingId]);
  }

  private fail(err: { error?: { detail?: string }; status?: number }): void {
    this.saving.set(false);
    if (err.status === 409) {
      this.error.set('rb.form.duplicateNo');
    } else if (err.status === 422) {
      this.error.set(err.error?.detail ?? 'rb.form.votesExceed');
    } else {
      this.error.set(err.error?.detail ?? 'rb.form.submitError');
    }
  }

  // ----- view helpers -----

  toInt(value: string): number {
    const parsed = Number(value);
    return Number.isFinite(parsed) && parsed > 0 ? Math.floor(parsed) : 0;
  }

  digits(value: number | string): string {
    return localizeDigits(value, this.lang());
  }

  charCount(value: string, max: number): string {
    return `${this.digits(value.length)} / ${this.digits(max)}`;
  }

  memberName(id: number): string {
    return this.memberOptions().find((option) => option.id === id)?.fullName ?? `#${id}`;
  }

  formatFileSize(bytes: number): string {
    if (bytes >= 1024 * 1024) return `${this.digits(Math.round((bytes / (1024 * 1024)) * 10) / 10)} MB`;
    if (bytes >= 1024) return `${this.digits(Math.round(bytes / 1024))} KB`;
    return `${this.digits(bytes)} B`;
  }
}
