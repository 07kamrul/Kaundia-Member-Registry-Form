import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map, type Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export type MeetingType = 'online' | 'offline';
export type MeetingStatus = 'scheduled' | 'completed' | 'cancelled';
export type ResolutionStatus = 'pending' | 'in_progress' | 'done';
export type AttendanceStatus = 'present' | 'absent';
export type RecordingType = 'video' | 'audio' | 'screenshot' | 'chat_log';

export interface MemberRef {
  id: number;
  fullName: string;
  memberId: string | null;
}

export interface Resolution {
  id: number;
  meetingId: number;
  resolutionNo: number;
  decision: string;
  voteFor: number;
  voteAgainst: number;
  voteNeutral: number;
  assignedTo: MemberRef | null;
  task: string | null;
  dueDate: string | null;
  status: ResolutionStatus;
  updatedAt: string | null;
}

export interface AttendanceEntry {
  member: MemberRef;
  status: AttendanceStatus;
}

export interface Recording {
  id: number;
  meetingId: number;
  originalName: string;
  fileType: RecordingType;
  fileSize: number;
  uploadedBy: string | null;
  uploadedAt: string | null;
}

export interface MeetingListItem {
  id: number;
  meetingNo: string;
  date: string;
  time: string | null;
  meetingType: MeetingType;
  chairperson: string;
  nextMeetingDate: string | null;
  status: MeetingStatus;
  resolutionCount: number;
  attendancePresent: number;
  attendanceTotal: number;
  attendancePercent: number;
}

export interface MeetingDetail extends MeetingListItem {
  agenda: string;
  summary: string | null;
  createdBy: string | null;
  updatedAt: string | null;
  resolutions: Resolution[];
  attendance: AttendanceEntry[];
  recordings: Recording[];
}

export interface MeetingPage {
  total: number;
  items: MeetingListItem[];
}

export interface MeetingSearchResult extends MeetingPage {
  matchedResolutions: Record<string, Resolution[]>;
}

export interface DashboardSummary {
  totalMeetings: number;
  meetingsThisYear: number;
  averageAttendancePercent: number;
  openActionItems: number;
  upcomingMeetingDate: string | null;
  recentMeetings: MeetingListItem[];
}

export interface SuggestedMeetingNo {
  meetingNo: string;
  available: boolean;
}

export interface AttendanceInput {
  memberId: number;
  status: AttendanceStatus;
}

export interface ResolutionInput {
  decision: string;
  voteFor: number;
  voteAgainst: number;
  voteNeutral: number;
  assignedToMemberId?: number | null;
  task?: string | null;
  dueDate?: string | null;
  status?: ResolutionStatus;
}

export interface MeetingCreateInput {
  meetingNo?: string | null;
  date: string;
  time?: string | null;
  meetingType: MeetingType;
  chairperson: string;
  chairpersonMemberId?: number | null;
  agenda: string;
  summary?: string | null;
  nextMeetingDate?: string | null;
  status?: MeetingStatus;
  resolutions: ResolutionInput[];
  attendance: AttendanceInput[];
  notify?: boolean;
}

// --- snake_case API shapes -------------------------------------------------

interface MemberRefApi {
  id: number;
  full_name: string;
  member_id: string | null;
}

interface ResolutionApi {
  id: number;
  meeting_id: number;
  resolution_no: number;
  decision: string;
  vote_for: number;
  vote_against: number;
  vote_neutral: number;
  assigned_to: MemberRefApi | null;
  task: string | null;
  due_date: string | null;
  status: ResolutionStatus;
  updated_at: string | null;
}

interface AttendanceApi {
  member: MemberRefApi;
  status: AttendanceStatus;
}

interface RecordingApi {
  id: number;
  meeting_id: number;
  original_name: string;
  file_type: RecordingType;
  file_size: number;
  uploaded_by: string | null;
  uploaded_at: string | null;
}

interface MeetingListItemApi {
  id: number;
  meeting_no: string;
  date: string;
  time: string | null;
  meeting_type: MeetingType;
  chairperson: string;
  next_meeting_date: string | null;
  status: MeetingStatus;
  resolution_count: number;
  attendance_present: number;
  attendance_total: number;
  attendance_percent: number;
}

interface MeetingDetailApi extends MeetingListItemApi {
  agenda: string;
  summary: string | null;
  created_by: string | null;
  updated_at: string | null;
  resolutions: ResolutionApi[];
  attendance: AttendanceApi[];
  recordings: RecordingApi[];
}

interface MeetingPageApi {
  total: number;
  items: MeetingListItemApi[];
}

interface SearchResultApi extends MeetingPageApi {
  matched_resolutions: Record<string, ResolutionApi[]>;
}

interface DashboardApi {
  total_meetings: number;
  meetings_this_year: number;
  average_attendance_percent: number;
  open_action_items: number;
  upcoming_meeting_date: string | null;
  recent_meetings: MeetingListItemApi[];
}

function toMemberRef(api: MemberRefApi | null): MemberRef | null {
  return api ? { id: api.id, fullName: api.full_name, memberId: api.member_id } : null;
}

function toResolution(api: ResolutionApi): Resolution {
  return {
    id: api.id,
    meetingId: api.meeting_id,
    resolutionNo: api.resolution_no,
    decision: api.decision,
    voteFor: api.vote_for,
    voteAgainst: api.vote_against,
    voteNeutral: api.vote_neutral,
    assignedTo: toMemberRef(api.assigned_to),
    task: api.task,
    dueDate: api.due_date,
    status: api.status,
    updatedAt: api.updated_at,
  };
}

function toMeetingListItem(api: MeetingListItemApi): MeetingListItem {
  return {
    id: api.id,
    meetingNo: api.meeting_no,
    date: api.date,
    time: api.time,
    meetingType: api.meeting_type,
    chairperson: api.chairperson,
    nextMeetingDate: api.next_meeting_date,
    status: api.status,
    resolutionCount: api.resolution_count,
    attendancePresent: api.attendance_present,
    attendanceTotal: api.attendance_total,
    attendancePercent: api.attendance_percent,
  };
}

function toMeetingDetail(api: MeetingDetailApi): MeetingDetail {
  return {
    ...toMeetingListItem(api),
    agenda: api.agenda,
    summary: api.summary,
    createdBy: api.created_by,
    updatedAt: api.updated_at,
    resolutions: api.resolutions.map(toResolution),
    attendance: api.attendance.map((entry) => ({
      member: toMemberRef(entry.member)!,
      status: entry.status,
    })),
    recordings: api.recordings.map((rec) => ({
      id: rec.id,
      meetingId: rec.meeting_id,
      originalName: rec.original_name,
      fileType: rec.file_type,
      fileSize: rec.file_size,
      uploadedBy: rec.uploaded_by,
      uploadedAt: rec.uploaded_at,
    })),
  };
}

// ---------------------------------------------------------------------------
// Bangla-first display helpers (mirrors roadmap.service.ts conventions).
// ---------------------------------------------------------------------------

const BN_DIGITS = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

export function localizeDigits(value: number | string, lang: string): string {
  const text = String(value);
  return lang === 'bn' ? text.replace(/[0-9]/g, (d) => BN_DIGITS[Number(d)]) : text;
}

export function formatRbDate(iso: string | null, lang: string): string {
  if (!iso) return '';
  const date = new Date(iso.length === 10 ? `${iso}T00:00:00` : iso);
  if (Number.isNaN(date.getTime())) return '';
  return date.toLocaleDateString(lang === 'bn' ? 'bn-BD' : 'en-GB', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });
}

export function formatRbTime(hhmm: string | null): string {
  return hhmm ?? '';
}

export function meetingTypeLabel(type: MeetingType, lang: string): string {
  return lang === 'bn' ? (type === 'online' ? 'অনলাইন' : 'অফলাইন') : (type === 'online' ? 'Online' : 'Offline');
}

export function meetingStatusLabel(status: MeetingStatus, lang: string): string {
  if (lang === 'bn') {
    return { scheduled: 'নির্ধারিত', completed: 'সম্পন্ন', cancelled: 'বাতিল' }[status];
  }
  return { scheduled: 'Scheduled', completed: 'Completed', cancelled: 'Cancelled' }[status];
}

export function resolutionStatusLabel(status: ResolutionStatus, lang: string): string {
  if (lang === 'bn') {
    return { pending: 'অপেক্ষমাণ', in_progress: 'চলমান', done: 'সম্পন্ন' }[status];
  }
  return { pending: 'Pending', in_progress: 'In Progress', done: 'Done' }[status];
}

export function attendanceStatusLabel(status: AttendanceStatus, lang: string): string {
  return lang === 'bn' ? (status === 'present' ? 'উপস্থিত' : 'অনুপস্থিত') : status === 'present' ? 'Present' : 'Absent';
}

export function recordingTypeLabel(type: RecordingType, lang: string): string {
  if (lang === 'bn') {
    return { video: 'ভিডিও', audio: 'অডিও', screenshot: 'স্ক্রিনশট', chat_log: 'চ্যাট লগ' }[type];
  }
  return { video: 'Video', audio: 'Audio', screenshot: 'Screenshot', chat_log: 'Chat Log' }[type];
}

export function formatFileSize(bytes: number, lang: string): string {
  const units = lang === 'bn' ? ['বাইট', 'KB', 'MB'] : ['B', 'KB', 'MB'];
  let value = bytes;
  let unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit += 1;
  }
  return `${localizeDigits(unit === 0 ? value : Math.round(value * 10) / 10, lang)} ${units[unit]}`;
}

@Injectable({ providedIn: 'root' })
export class ResolutionBookService {
  private readonly base = environment.apiBaseUrl;

  constructor(private http: HttpClient) {}

  listMeetings(params: {
    q?: string;
    meeting_type?: string;
    meeting_status?: string;
    date_from?: string;
    date_to?: string;
    limit?: number;
    offset?: number;
  }): Observable<MeetingPage> {
    return this.http
      .get<MeetingPageApi>(`${this.base}/resolution-book/meetings`, { params: this.cleanParams(params) })
      .pipe(map((api) => ({ total: api.total, items: api.items.map(toMeetingListItem) })));
  }

  search(params: { q?: string; meeting_type?: string; date_from?: string; date_to?: string }): Observable<MeetingSearchResult> {
    return this.http
      .get<SearchResultApi>(`${this.base}/resolution-book/search`, { params: this.cleanParams(params) })
      .pipe(
        map((api) => ({
          total: api.total,
          items: api.items.map(toMeetingListItem),
          matchedResolutions: Object.fromEntries(
            Object.entries(api.matched_resolutions ?? {}).map(([key, list]) => [key, list.map(toResolution)]),
          ),
        })),
      );
  }

  summary(): Observable<DashboardSummary> {
    return this.http.get<DashboardApi>(`${this.base}/resolution-book/summary`).pipe(
      map((api) => ({
        totalMeetings: api.total_meetings,
        meetingsThisYear: api.meetings_this_year,
        averageAttendancePercent: api.average_attendance_percent,
        openActionItems: api.open_action_items,
        upcomingMeetingDate: api.upcoming_meeting_date,
        recentMeetings: api.recent_meetings.map(toMeetingListItem),
      })),
    );
  }

  suggestMeetingNo(forDate: string): Observable<SuggestedMeetingNo> {
    return this.http
      .get<{ meeting_no: string; available: boolean }>(
        `${this.base}/resolution-book/meetings/suggest-no`,
        { params: { for_date: forDate } },
      )
      .pipe(map((api) => ({ meetingNo: api.meeting_no, available: api.available })));
  }

  getMeeting(id: number): Observable<MeetingDetail> {
    return this.http
      .get<MeetingDetailApi>(`${this.base}/resolution-book/meetings/${id}`)
      .pipe(map(toMeetingDetail));
  }

  createMeeting(input: MeetingCreateInput): Observable<MeetingDetail> {
    return this.http
      .post<MeetingDetailApi>(`${this.base}/resolution-book/meetings`, {
        meeting_no: input.meetingNo || null,
        date: input.date,
        time: input.time || null,
        meeting_type: input.meetingType,
        chairperson: input.chairperson,
        chairperson_member_id: input.chairpersonMemberId || null,
        agenda: input.agenda,
        summary: input.summary || null,
        next_meeting_date: input.nextMeetingDate || null,
        status: input.status ?? 'completed',
        resolutions: input.resolutions.map((r) => ({
          decision: r.decision,
          vote_for: r.voteFor,
          vote_against: r.voteAgainst,
          vote_neutral: r.voteNeutral,
          assigned_to_member_id: r.assignedToMemberId || null,
          task: r.task || null,
          due_date: r.dueDate || null,
          status: r.status ?? 'pending',
        })),
        attendance: input.attendance.map((a) => ({ member_id: a.memberId, status: a.status })),
        notify: input.notify ?? true,
      })
      .pipe(map(toMeetingDetail));
  }

  updateMeeting(id: number, changes: Partial<Record<string, unknown>>): Observable<MeetingDetail> {
    return this.http
      .put<MeetingDetailApi>(`${this.base}/resolution-book/meetings/${id}`, changes)
      .pipe(map(toMeetingDetail));
  }

  bulkAttendance(meetingId: number, entries: AttendanceInput[]): Observable<MeetingDetail> {
    return this.http
      .post<MeetingDetailApi>(`${this.base}/resolution-book/meetings/${meetingId}/attendance`, {
        entries: entries.map((e) => ({ member_id: e.memberId, status: e.status })),
      })
      .pipe(map(toMeetingDetail));
  }

  addResolution(meetingId: number, input: ResolutionInput): Observable<MeetingDetail> {
    return this.http
      .post<MeetingDetailApi>(`${this.base}/resolution-book/meetings/${meetingId}/resolutions`, {
        decision: input.decision,
        vote_for: input.voteFor,
        vote_against: input.voteAgainst,
        vote_neutral: input.voteNeutral,
        assigned_to_member_id: input.assignedToMemberId || null,
        task: input.task || null,
        due_date: input.dueDate || null,
        status: input.status ?? 'pending',
      })
      .pipe(map(toMeetingDetail));
  }

  updateResolution(
    id: number,
    changes: Partial<Pick<ResolutionInput, 'status' | 'task' | 'dueDate' | 'assignedToMemberId'>>,
  ): Observable<Resolution> {
    const body: Record<string, unknown> = {};
    if (changes.status !== undefined) body['status'] = changes.status;
    if (changes.task !== undefined) body['task'] = changes.task || null;
    if (changes.dueDate !== undefined) body['due_date'] = changes.dueDate || null;
    if (changes.assignedToMemberId !== undefined) body['assigned_to_member_id'] = changes.assignedToMemberId || null;
    return this.http
      .put<{ resolution: ResolutionApi }>(`${this.base}/resolution-book/resolutions/${id}`, body)
      .pipe(map((api) => toResolution(api.resolution)));
  }

  uploadRecording(meetingId: number, file: File): Observable<Recording> {
    const form = new FormData();
    form.append('file', file);
    return this.http.post<RecordingApi>(
      `${this.base}/resolution-book/meetings/${meetingId}/recordings`,
      form,
    ).pipe(
      map((api) => ({
        id: api.id,
        meetingId: api.meeting_id,
        originalName: api.original_name,
        fileType: api.file_type,
        fileSize: api.file_size,
        uploadedBy: api.uploaded_by,
        uploadedAt: api.uploaded_at,
      })),
    );
  }

  downloadRecording(recordingId: number): Observable<Blob> {
    return this.http.get(`${this.base}/resolution-book/recordings/${recordingId}/download`, {
      responseType: 'blob',
    });
  }

  /** Server-rendered official minutes document; caller saves via object URL. */
  downloadPdf(meetingId: number): Observable<Blob> {
    return this.http.get(`${this.base}/resolution-book/meetings/${meetingId}/export.pdf`, {
      responseType: 'blob',
    });
  }

  private cleanParams(params: Record<string, unknown>): Record<string, string> {
    const out: Record<string, string> = {};
    for (const [key, value] of Object.entries(params)) {
      if (value !== undefined && value !== null && value !== '') {
        out[key] = String(value);
      }
    }
    return out;
  }
}
