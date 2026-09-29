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


MIN_PASSWORD_LENGTH = 8


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str


def validate_new_password(current_password: str, new_password: str) -> dict[str, str]:
    """Return field-level errors for a proposed new password (empty when valid)."""
    if len(new_password) < MIN_PASSWORD_LENGTH or not any(c.isdigit() for c in new_password):
        return {
            "new_password": f"Password must be at least {MIN_PASSWORD_LENGTH} characters and include a number"
        }
    if new_password == current_password:
        return {"new_password": "New password must be different from the current password"}
    return {}
