import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
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
  imports: [FormsModule, TranslatePipe],
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

  newUserName = '';
  newUserEmail = '';
  newUserPassword = '';
  newUserRole = 'administrator';
  creatingUser = false;
  createUserError = '';
  createUserSuccess = '';

  roleAssignDraft = '';
  savingRoleAssignment = false;

  constructor(
    private rbacService: RbacService,
    private cdr: ChangeDetectorRef,
    private translate: TranslateService,
  ) {}

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
            this.cdr.markForCheck();
          },
          error: () => {
            this.error = this.translate.instant('admin.roleManagement.errors.loadRolesFailed');
            this.loading = false;
            this.cdr.markForCheck();
          },
        });
      },
      error: () => {
        this.error = this.translate.instant('admin.roleManagement.errors.loadPermissionsFailed');
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
    this.rbacService.listUsers().subscribe({
      next: (users) => {
        this.users = users;
        this.selectedUserId = users[0]?.id ?? null;
        if (this.selectedUserId) this.loadOverrides(this.selectedUserId);
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.roleManagement.errors.loadUsersFailed');
        this.cdr.markForCheck();
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
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.roleManagement.errors.saveChangeFailed');
        this.savingRoleId = null;
        this.cdr.markForCheck();
      },
    });
  }

  onSelectUser(userId: string): void {
    this.selectedUserId = userId ? Number(userId) : null;
    if (this.selectedUserId) {
      this.loadOverrides(this.selectedUserId);
      const user = this.users.find((u) => u.id === this.selectedUserId);
      this.roleAssignDraft = user ? user.role : '';
    }
  }

  createUser(): void {
    if (!this.newUserName || !this.newUserEmail || !this.newUserPassword || !this.newUserRole) return;

    this.creatingUser = true;
    this.createUserError = '';
    this.createUserSuccess = '';
    this.rbacService
      .createUser({
        name: this.newUserName,
        email: this.newUserEmail,
        password: this.newUserPassword,
        role: this.newUserRole,
        role_id: null,
      })
      .subscribe({
        next: (user) => {
          this.users = [...this.users, user];
          this.createUserSuccess = `${this.translate.instant('admin.roleManagement.createAdmin.successPrefix')} ${user.email}`;
          this.newUserName = '';
          this.newUserEmail = '';
          this.newUserPassword = '';
          this.creatingUser = false;
          this.cdr.markForCheck();
        },
        error: (err) => {
          this.createUserError =
            err?.error?.detail ?? this.translate.instant('admin.roleManagement.errors.createUserFailed');
          this.creatingUser = false;
          this.cdr.markForCheck();
        },
      });
  }

  assignRole(): void {
    if (!this.selectedUserId || !this.roleAssignDraft) return;

    this.savingRoleAssignment = true;
    this.rbacService.updateUserRole(this.selectedUserId, this.roleAssignDraft, null).subscribe({
      next: (updated) => {
        this.users = this.users.map((u) => (u.id === updated.id ? updated : u));
        this.savingRoleAssignment = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.roleManagement.errors.assignRoleFailed');
        this.savingRoleAssignment = false;
        this.cdr.markForCheck();
      },
    });
  }

  loadOverrides(userId: number): void {
    this.loadingOverrides = true;
    this.rbacService.listUserOverrides(userId).subscribe({
      next: (overrides) => {
        this.overrides = overrides;
        this.loadingOverrides = false;
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.roleManagement.errors.loadOverridesFailed');
        this.loadingOverrides = false;
        this.cdr.markForCheck();
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
        this.cdr.markForCheck();
      },
      error: () => {
        this.error = this.translate.instant('admin.roleManagement.errors.saveOverridesFailed');
        this.savingOverride = false;
        this.cdr.markForCheck();
      },
    });
  }
}
