import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import {
  AdminUserDef,
  PermissionDef,
  PermissionOverride,
  RbacService,
  RoleDef,
} from '../../../../core/services/rbac.service';

@Component({
  selector: 'app-role-management',
  standalone: true,
  imports: [FormsModule],
  templateUrl: './role-management.component.html',
})
export class RoleManagementComponent implements OnInit {
  roles: RoleDef[] = [];
  permissions: PermissionDef[] = [];
  loading = false;
  error = '';
  savingRoleId: number | null = null;

  users: AdminUserDef[] = [];
  selectedUserId: number | null = null;
  overrides: PermissionOverride[] = [];
  loadingOverrides = false;
  savingOverride = false;
  overrideDraftKey = '';
  overrideDraftAction: 'grant' | 'revoke' = 'grant';

  constructor(private rbacService: RbacService) {}

  ngOnInit(): void {
    this.loading = true;
    this.rbacService.listPermissions().subscribe({
      next: (permissions) => {
        this.permissions = permissions;
        this.overrideDraftKey = permissions[0]?.key ?? '';
        this.rbacService.listRoles().subscribe({
          next: (roles) => {
            this.roles = roles;
            this.loading = false;
          },
          error: () => {
            this.error = 'ভূমিকা তালিকা লোড করা যায়নি।';
            this.loading = false;
          },
        });
      },
      error: () => {
        this.error = 'অনুমতি তালিকা লোড করা যায়নি।';
        this.loading = false;
      },
    });
    this.rbacService.listUsers().subscribe({
      next: (users) => {
        this.users = users;
        this.selectedUserId = users[0]?.id ?? null;
        if (this.selectedUserId) this.loadOverrides(this.selectedUserId);
      },
      error: () => {
        this.error = 'ব্যবহারকারী তালিকা লোড করা যায়নি।';
      },
    });
  }

  hasPermission(role: RoleDef, permissionKey: string): boolean {
    return role.permission_keys.includes(permissionKey);
  }

  togglePermission(role: RoleDef, permissionKey: string): void {
    const nextKeys = this.hasPermission(role, permissionKey)
      ? role.permission_keys.filter((key) => key !== permissionKey)
      : [...role.permission_keys, permissionKey];

    this.savingRoleId = role.id;
    this.rbacService.updateRolePermissions(role.id, nextKeys).subscribe({
      next: (updated) => {
        role.permission_keys = updated.permission_keys;
        this.savingRoleId = null;
      },
      error: () => {
        this.error = 'পরিবর্তন সংরক্ষণ করা যায়নি।';
        this.savingRoleId = null;
      },
    });
  }

  onSelectUser(userId: string): void {
    this.selectedUserId = userId ? Number(userId) : null;
    if (this.selectedUserId) this.loadOverrides(this.selectedUserId);
  }

  loadOverrides(userId: number): void {
    this.loadingOverrides = true;
    this.rbacService.listUserOverrides(userId).subscribe({
      next: (overrides) => {
        this.overrides = overrides;
        this.loadingOverrides = false;
      },
      error: () => {
        this.error = 'স্বতন্ত্র অনুমতি লোড করা যায়নি।';
        this.loadingOverrides = false;
      },
    });
  }

  permissionLabel(key: string): string {
    return this.permissions.find((p) => p.key === key)?.description ?? key;
  }

  applyOverride(): void {
    if (!this.selectedUserId || !this.overrideDraftKey) return;
    const next = this.overrides.filter((o) => o.permission_key !== this.overrideDraftKey);
    next.push({ permission_key: this.overrideDraftKey, granted: this.overrideDraftAction === 'grant' });
    this.saveOverrides(this.selectedUserId, next);
  }

  removeOverride(key: string): void {
    if (!this.selectedUserId) return;
    const next = this.overrides.filter((o) => o.permission_key !== key);
    this.saveOverrides(this.selectedUserId, next);
  }

  private saveOverrides(userId: number, overrides: PermissionOverride[]): void {
    this.savingOverride = true;
    this.rbacService.setUserOverrides(userId, overrides).subscribe({
      next: (result) => {
        this.overrides = result;
        this.savingOverride = false;
      },
      error: () => {
        this.error = 'স্বতন্ত্র অনুমতি সংরক্ষণ করা যায়নি।';
        this.savingOverride = false;
      },
    });
  }
}
