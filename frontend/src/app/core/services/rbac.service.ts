import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import type { Observable } from 'rxjs';
import { environment } from '../../../environments/environment';

export interface PermissionDef {
  key: string;
  resource: string;
  action: string;
  description: string;
}

export interface RoleDef {
  id: number;
  name: string;
  description: string | null;
  permission_keys: string[];
}

export interface PermissionOverride {
  permission_key: string;
  granted: boolean;
}

@Injectable({ providedIn: 'root' })
export class RbacService {
  private base = `${environment.apiBaseUrl}/admin/rbac`;

  constructor(private http: HttpClient) {}

  listPermissions(): Observable<PermissionDef[]> {
    return this.http.get<PermissionDef[]>(`${this.base}/permissions`);
  }

  listRoles(): Observable<RoleDef[]> {
    return this.http.get<RoleDef[]>(`${this.base}/roles`);
  }

  updateRolePermissions(roleId: number, permissionKeys: string[]): Observable<RoleDef> {
    return this.http.put<RoleDef>(`${this.base}/roles/${roleId}/permissions`, {
      permission_keys: permissionKeys,
    });
  }

  listUserOverrides(userId: number): Observable<PermissionOverride[]> {
    return this.http.get<PermissionOverride[]>(`${this.base}/users/${userId}/overrides`);
  }

  setUserOverrides(
    userId: number,
    overrides: PermissionOverride[],
  ): Observable<PermissionOverride[]> {
    return this.http.put<PermissionOverride[]>(`${this.base}/users/${userId}/overrides`, overrides);
  }
}
