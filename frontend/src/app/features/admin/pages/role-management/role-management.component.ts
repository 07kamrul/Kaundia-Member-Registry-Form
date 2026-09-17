import { Component, OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { PermissionDef, RbacService, RoleDef } from '../../../../core/services/rbac.service';

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

  constructor(private rbacService: RbacService) {}

  ngOnInit(): void {
    this.loading = true;
    this.rbacService.listPermissions().subscribe({
      next: (permissions) => {
        this.permissions = permissions;
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
}
