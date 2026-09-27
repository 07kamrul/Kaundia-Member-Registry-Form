import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { catchError, map, Observable, of, shareReplay } from 'rxjs';
import { environment } from '../../../environments/environment';

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
        catchError(() => of(defaultValues)),
        shareReplay({ bufferSize: 1, refCount: false }),
      );
      this.cache.set(category, cached);
    }
    return cached;
  }
}
