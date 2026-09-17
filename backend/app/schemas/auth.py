from pydantic import BaseModel


class AdminLoginRequest(BaseModel):
    email: str
    password: str


class MemberLoginRequest(BaseModel):
    username: str
    password: str


class LoginRequest(BaseModel):
    identifier: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    must_change_password: bool = False
    role: str | None = None
    permissions: list[str] = []


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str
