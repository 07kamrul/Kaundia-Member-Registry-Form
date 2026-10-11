import { ChangeDetectorRef, Component, OnInit, ChangeDetectionStrategy } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { PasswordFieldComponent } from '../../../../shared/password-field/password-field.component';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import {
  AdminUserDef,
  PermissionDef,
  PermissionOverride,
  RbacService,
  RoleDef,
} from '../../../../core/services/rbac.service';

interface PermissionGroup {
  categoryKey: string;
  permissions: PermissionDef[];
}

@Component({
  selector: 'app-role-management',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, TranslatePipe, PasswordFieldComponent],
  templateUrl: './role-management.component.html',
})
export class RoleManagementComponent implements OnInit {
  roles: RoleDef[] = [];
  permissions: PermissionDef[] = [];
  loading = false;
  error = '';
  savingRoleId: number | null = null;

  selectedRoleName = '';
  permissionSearch = '';

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

  // Resources grouped into reviewer-friendly categories; anything not listed
  // lands in "other" so a new backend permission still renders.
  private static readonly CATEGORY_RESOURCES: { key: string; resources: string[] }[] = [
    { key: 'access', resources: ['user', 'role', 'system', 'organization', 'audit'] },
    { key: 'members', resources: ['member', 'membership', 'document'] },
    { key: 'properties', resources: ['property', 'boundary', 'neighbour'] },
    { key: 'feesFinance', resources: ['fee_settings', 'cost', 'finance'] },
    { key: 'complaints', resources: ['complaint', 'request'] },
    { key: 'content', resources: ['notice', 'event', 'resolution_book', 'roadmap'] },
    { key: 'reports', resources: ['report'] },
    { key: 'selfService', resources: ['profile'] },
  ];

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
            this.selectedRoleName = roles[0]?.name ?? '';
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

  get selectedRole(): RoleDef | null {
    return this.roles.find((role) => role.name === this.selectedRoleName) ?? null;
  }

  selectRole(name: string): void {
    this.selectedRoleName = name;
    this.permissionSearch = '';
    this.cdr.markForCheck();
    // On narrow screens the tab row scrolls horizontally; keep the active
    // chip visible after switching roles.
    setTimeout(() => {
      document
        .querySelector('.role-mgmt-tab.active')
        ?.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' });
    });
  }

  roleLabel(name: string): string {
    const key = `admin.roleManagement.roles.${name}`;
    const label = this.translate.instant(key);
    return label === key ? name : label;
  }

  enabledCount(role: RoleDef): number {
    return role.permission_keys.length;
  }

  hasPermission(role: RoleDef, permissionKey: string): boolean {
    return role.permission_keys.includes(permissionKey);
  }

  groupsForRole(role: RoleDef): PermissionGroup[] {
    const search = this.permissionSearch.trim().toLowerCase();
    const groups: PermissionGroup[] = [];
    const seen = new Set<string>();

    for (const category of RoleManagementComponent.CATEGORY_RESOURCES) {
      const permissions = this.permissions.filter(
        (permission) =>
          category.resources.includes(permission.resource) &&
          (!search ||
            permission.description.toLowerCase().includes(search) ||
            permission.key.toLowerCase().includes(search)),
      );
      if (permissions.length) {
        groups.push({ categoryKey: category.key, permissions });
        permissions.forEach((permission) => seen.add(permission.key));
      }
    }

    const other = this.permissions.filter(
      (permission) =>
        !seen.has(permission.key) &&
        (!search ||
          permission.description.toLowerCase().includes(search) ||
          permission.key.toLowerCase().includes(search)),
    );
    if (other.length) groups.push({ categoryKey: 'other', permissions: other });
    return groups;
  }

  anyPermissionEnabled(role: RoleDef, group: PermissionGroup): boolean {
    return group.permissions.some((permission) => this.hasPermission(role, permission.key));
  }

  toggleGroup(role: RoleDef, group: PermissionGroup): void {
    const enable = !this.anyPermissionEnabled(role, group);
    this.setPermissions(
      role,
      group.permissions.map((permission) => permission.key),
      enable,
    );
  }

  togglePermission(role: RoleDef, permissionKey: string): void {
    this.setPermissions(role, [permissionKey], !this.hasPermission(role, permissionKey));
  }

  private setPermissions(role: RoleDef, keys: string[], enable: boolean): void {
    if (role.name === 'super_admin' || this.savingRoleId === role.id) return;

    const nextKeys = enable
      ? [...new Set([...role.permission_keys, ...keys])]
      : role.permission_keys.filter((key) => !keys.includes(key));

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
    if (!this.newUserName || !this.newUserEmail || !this.newUserPassword || !this.newUserRole)
      return;

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
            err?.error?.detail ??
            this.translate.instant('admin.roleManagement.errors.createUserFailed');
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
    next.push({
      permission_key: this.overrideDraftKey,
      granted: this.overrideDraftAction === 'grant',
    });
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
