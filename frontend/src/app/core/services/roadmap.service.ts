import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map, type Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export type RoadmapStatus = 'planned' | 'in_progress' | 'done';
export const ROADMAP_STATUSES: readonly RoadmapStatus[] = ['planned', 'in_progress', 'done'];

export interface RoadmapItem {
  id: number;
  timeframeId: number;
  text: string;
  status: RoadmapStatus;
  targetDate: string | null;
  owner: string | null;
  note: string | null;
  sortOrder: number;
  completedAt: string | null;
  updatedAt: string | null;
}

export interface RoadmapProgress {
  total: number;
  done: number;
  inProgress: number;
  planned: number;
  percent: number;
}

export interface RoadmapTimeframe extends RoadmapProgress {
  id: number;
  key: string;
  nameBn: string;
  nameEn: string;
  windowBn: string;
  windowEn: string;
  sortOrder: number;
  items: RoadmapItem[];
}

export interface Roadmap {
  lastUpdated: string | null;
  totals: RoadmapProgress;
  timeframes: RoadmapTimeframe[];
}

export interface RoadmapArchivedCycle {
  archivedAt: string;
  total: number;
  done: number;
  items: RoadmapItem[];
}

export interface RoadmapItemInput {
  timeframeId: number;
  text: string;
  status?: RoadmapStatus;
  targetDate?: string | null;
  owner?: string | null;
  note?: string | null;
  notify?: boolean;
}

interface ItemApi {
  id: number;
  timeframe_id: number;
  text: string;
  status: RoadmapStatus;
  target_date: string | null;
  owner: string | null;
  note: string | null;
  sort_order: number;
  completed_at: string | null;
  updated_at: string | null;
}

interface ProgressApi {
  total: number;
  done: number;
  in_progress: number;
  planned: number;
  percent: number;
}

interface TimeframeApi extends ProgressApi {
  id: number;
  key: string;
  name_bn: string;
  name_en: string;
  target_window_bn: string;
  target_window_en: string;
  sort_order: number;
  items: ItemApi[];
}

export interface RoadmapApi {
  last_updated: string | null;
  totals: ProgressApi;
  timeframes: TimeframeApi[];
}

interface ArchivedCycleApi {
  archived_at: string;
  total: number;
  done: number;
  items: ItemApi[];
}

function toItem(api: ItemApi): RoadmapItem {
  return {
    id: api.id,
    timeframeId: api.timeframe_id,
    text: api.text,
    status: api.status,
    targetDate: api.target_date,
    owner: api.owner,
    note: api.note,
    sortOrder: api.sort_order,
    completedAt: api.completed_at,
    updatedAt: api.updated_at,
  };
}

function toProgress(api: ProgressApi): RoadmapProgress {
  return {
    total: api.total,
    done: api.done,
    inProgress: api.in_progress,
    planned: api.planned,
    percent: api.percent,
  };
}

export function toRoadmap(api: RoadmapApi): Roadmap {
  return {
    lastUpdated: api.last_updated,
    totals: toProgress(api.totals),
    timeframes: api.timeframes.map((tf) => ({
      ...toProgress(tf),
      id: tf.id,
      key: tf.key,
      nameBn: tf.name_bn,
      nameEn: tf.name_en,
      windowBn: tf.target_window_bn,
      windowEn: tf.target_window_en,
      sortOrder: tf.sort_order,
      items: tf.items.map(toItem),
    })),
  };
}

// ---------------------------------------------------------------------------
// Bangla-first display helpers shared by the page, slides and share image.
// ---------------------------------------------------------------------------

const BN_DIGITS = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

export function localizeDigits(value: number | string, lang: string): string {
  const text = String(value);
  return lang === 'bn' ? text.replace(/[0-9]/g, (d) => BN_DIGITS[Number(d)]) : text;
}

export function formatRoadmapDate(iso: string | null, lang: string): string {
  if (!iso) return '';
  const date = new Date(iso.length === 10 ? `${iso}T00:00:00` : iso);
  if (Number.isNaN(date.getTime())) return '';
  return date.toLocaleDateString(lang === 'bn' ? 'bn-BD' : 'en-GB', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });
}

export function timeframeName(tf: RoadmapTimeframe, lang: string): string {
  return lang === 'bn' ? tf.nameBn : tf.nameEn;
}

export function timeframeWindow(tf: RoadmapTimeframe, lang: string): string {
  return lang === 'bn' ? tf.windowBn : tf.windowEn;
}

/**
 * "আমরা এখন কোথায় আছি": the earliest timeframe that still has unfinished
 * work - or the last one when everything is done.
 */
export function currentTimeframeIndex(roadmap: Roadmap): number {
  const index = roadmap.timeframes.findIndex((tf) => tf.total > 0 && tf.done < tf.total);
  return index === -1 ? Math.max(roadmap.timeframes.length - 1, 0) : index;
}

@Injectable({ providedIn: 'root' })
export class RoadmapService {
  private readonly base = environment.apiBaseUrl;
  private readonly adminBase = `${environment.apiBaseUrl}/admin/roadmap`;

  constructor(private http: HttpClient) {}

  getRoadmap(): Observable<Roadmap> {
    return this.http.get<RoadmapApi>(`${this.base}/roadmap`).pipe(map(toRoadmap));
  }

  /** Server-rendered A4 handout; the caller saves it via an object URL. */
  downloadPdf(): Observable<Blob> {
    return this.http.get(`${this.base}/roadmap/export.pdf`, { responseType: 'blob' });
  }

  createItem(input: RoadmapItemInput): Observable<Roadmap> {
    return this.http
      .post<RoadmapApi>(`${this.adminBase}/items`, {
        timeframe_id: input.timeframeId,
        text: input.text,
        status: input.status ?? 'planned',
        target_date: input.targetDate || null,
        owner: input.owner || null,
        note: input.note || null,
        notify: input.notify ?? true,
      })
      .pipe(map(toRoadmap));
  }

  updateItem(
    id: number,
    changes: Partial<Omit<RoadmapItemInput, 'status' | 'notify'>>,
  ): Observable<Roadmap> {
    const body: Record<string, unknown> = {};
    if (changes.timeframeId !== undefined) body['timeframe_id'] = changes.timeframeId;
    if (changes.text !== undefined) body['text'] = changes.text;
    if (changes.targetDate !== undefined) body['target_date'] = changes.targetDate || null;
    if (changes.owner !== undefined) body['owner'] = changes.owner || null;
    if (changes.note !== undefined) body['note'] = changes.note || null;
    return this.http.put<RoadmapApi>(`${this.adminBase}/items/${id}`, body).pipe(map(toRoadmap));
  }

  setStatus(id: number, status: RoadmapStatus, notify = true): Observable<Roadmap> {
    return this.http
      .post<RoadmapApi>(`${this.adminBase}/items/${id}/status`, { status, notify })
      .pipe(map(toRoadmap));
  }

  deleteItem(id: number): Observable<Roadmap> {
    return this.http.delete<RoadmapApi>(`${this.adminBase}/items/${id}`).pipe(map(toRoadmap));
  }

  reorder(timeframeId: number, itemIds: number[]): Observable<Roadmap> {
    return this.http
      .post<RoadmapApi>(`${this.adminBase}/reorder`, { timeframe_id: timeframeId, item_ids: itemIds })
      .pipe(map(toRoadmap));
  }

  archive(onlyDone: boolean): Observable<{ archived: number }> {
    return this.http.post<{ archived: number }>(`${this.adminBase}/archive`, null, {
      params: { only_done: String(onlyDone) },
    });
  }

  getArchive(): Observable<RoadmapArchivedCycle[]> {
    return this.http.get<ArchivedCycleApi[]>(`${this.adminBase}/archive`).pipe(
      map((cycles) =>
        cycles.map((c) => ({
          archivedAt: c.archived_at,
          total: c.total,
          done: c.done,
          items: c.items.map(toItem),
        })),
      ),
    );
  }
}
