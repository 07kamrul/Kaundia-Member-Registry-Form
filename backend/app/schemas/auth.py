from pydantic import BaseModel


class AdminLoginRequest(BaseModel):
    email: str
    password: str


class MemberLoginRequest(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    must_change_password: bool = False


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str
