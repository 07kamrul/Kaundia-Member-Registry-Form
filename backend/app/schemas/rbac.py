from pydantic import BaseModel


class PermissionOut(BaseModel):
    key: str
    resource: str
    action: str
    description: str


class RoleOut(BaseModel):
    id: int
    name: str
    description: str | None = None
    permission_keys: list[str]


class RolePermissionsUpdate(BaseModel):
    permission_keys: list[str]


class PermissionOverrideIn(BaseModel):
    permission_key: str
    granted: bool


class PermissionOverrideOut(BaseModel):
    permission_key: str
    granted: bool


class AdminUserOut(BaseModel):
    id: int
    name: str
    email: str
    role: str
    role_id: int | None = None


class AdminUserCreate(BaseModel):
    name: str
    email: str
    password: str
    role: str
    role_id: int | None = None


class AdminUserRoleUpdate(BaseModel):
    role: str
    role_id: int | None = None
