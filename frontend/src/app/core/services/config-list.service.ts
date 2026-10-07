import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { catchError, map, Observable, of, shareReplay } from 'rxjs';
import { environment } from '../../../environments/environment';
import type { ConfigListItem } from '../models/admin.model';

interface ConfigListItemApiModel {
  id: number;
  category: string;
  value: string;
  label: string;
  sort_order: number;
  is_active: number;
}

@Injectable({ providedIn: 'root' })
export class ConfigListService {
  private base = `${environment.apiBaseUrl}/public/config-lists`;
  private cache = new Map<string, Observable<string[]>>();
  private itemCache = new Map<string, Observable<ConfigListItem[]>>();

  constructor(private http: HttpClient) {}

  /**
   * Active option values for `category`, sorted by sort_order. Falls back to
   * `defaultValues` (the values previously hard-coded in registration.model.ts)
   * so the public registration form still renders if the API is unreachable.
   */
  getValues(category: string, defaultValues: string[]): Observable<string[]> {
    let cached = this.cache.get(category);
    if (!cached) {
      cached = this.http.get<ConfigListItemApiModel[]>(`${this.base}/${category}`).pipe(
        map((rows) => rows.map((r) => r.value)),
        // An unconfigured category returns [] — keep showing the defaults.
        map((values) => (values.length ? values : defaultValues)),
        catchError(() => of(defaultValues)),
        shareReplay({ bufferSize: 1, refCount: false }),
      );
      this.cache.set(category, cached);
    }
    return cached;
  }

  /**
   * Full rows (id + label) for `category` - used where a stored
   * `category_id` has to be rendered as its label. Empty list on failure:
   * the label is decoration, the page still works without it.
   */
  getItems(category: string): Observable<ConfigListItem[]> {
    let cached = this.itemCache.get(category);
    if (!cached) {
      cached = this.http.get<ConfigListItemApiModel[]>(`${this.base}/${category}`).pipe(
        map((rows) =>
          rows.map((r) => ({
            id: String(r.id),
            category: r.category,
            value: r.value,
            label: r.label,
            sortOrder: r.sort_order,
            isActive: r.is_active === 1,
          })),
        ),
        catchError(() => of([] as ConfigListItem[])),
        shareReplay({ bufferSize: 1, refCount: false }),
      );
      this.itemCache.set(category, cached);
    }
    return cached;
  }
}
