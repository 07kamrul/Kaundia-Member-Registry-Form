from functools import lru_cache
from pathlib import Path

from pydantic import AliasChoices, Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_INSECURE_JWT_DEFAULT = "insecure-dev-secret-change-me"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Application
    app_env: str = "development"

    # Database
    database_url: str = "sqlite+aiosqlite:///./dev.db"

    # JWT
    jwt_secret_key: str = Field(default=_INSECURE_JWT_DEFAULT, validation_alias=AliasChoices("SECRET_KEY", "JWT_SECRET_KEY"))
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60
    refresh_token_expire_days: int = 30

    # Uploads
    upload_dir: str = Field(default="uploads", validation_alias=AliasChoices("STORAGE_BASE_DIR", "UPLOAD_DIR"))

    # SMTP
    smtp_host: str = "localhost"
    smtp_port: int = 587
    smtp_user: str = Field(default="", validation_alias=AliasChoices("SMTP_USERNAME", "SMTP_USER"))
    smtp_password: str = ""
    smtp_sender_email: str = Field(default="no-reply@example.com", validation_alias="SMTP_SENDER_EMAIL")
    smtp_sender_name: str = Field(
        default="উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ পরিষদ", validation_alias="SMTP_SENDER_NAME"
    )

    # Admin bootstrap
    admin_email: str = "admin@example.com"
    admin_password: str = "change-this-password"
    admin_name: str = "Administrator"
    admin_role: str = "super_admin"

    # CORS
    cors_origins: str = "http://localhost:9091"

    @model_validator(mode="after")
    def _reject_insecure_secret_in_production(self) -> "Settings":
        if self.app_env == "production" and self.jwt_secret_key == _INSECURE_JWT_DEFAULT:
            raise ValueError(
                "JWT secret is using the insecure default. Set SECRET_KEY to a strong "
                "random value before running with APP_ENV=production."
            )
        return self

    @property
    def smtp_from(self) -> str:
        return f"{self.smtp_sender_name} <{self.smtp_sender_email}>"

    @property
    def upload_root(self) -> Path:
        """Absolute directory uploads are written to and served from.

        `upload_dir` may be relative (default `uploads`), which resolves
        against the process working directory - so two components resolving it
        at different moments could disagree. Resolving it in one place, always
        to an absolute path, keeps save logs, serve logs and the static mount
        directly comparable.
        """
        path = Path(self.upload_dir).expanduser()
        if not path.is_absolute():
            path = Path.cwd() / path
        return path.resolve()

    @property
    def cors_origins_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
