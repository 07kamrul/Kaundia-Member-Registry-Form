import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { map, type Observable } from 'rxjs';
import { environment } from '../../../environments/environment';
import {
  toEventItem,
  toNotice,
  type EventApiModel,
  type EventItem,
  type Notice,
  type NoticeApiModel,
} from '../models/content.model';

/**
 * Unauthenticated reads of the published notices/events feed. The same
 * endpoints serve logged-out visitors and logged-in members - only rows the
 * backend considers public come back (see `app/api/routes/public.py`).
 */
@Injectable({ providedIn: 'root' })
export class ContentService {
  private base = `${environment.apiBaseUrl}/public`;

  constructor(private http: HttpClient) {}

  listNotices(): Observable<Notice[]> {
    return this.http
      .get<NoticeApiModel[]>(`${this.base}/notices`)
      .pipe(map((rows) => rows.map(toNotice)));
  }

  listEvents(): Observable<EventItem[]> {
    return this.http
      .get<EventApiModel[]>(`${this.base}/events`)
      .pipe(map((rows) => rows.map(toEventItem)));
  }
}
