from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Database
    database_url: str = "sqlite+aiosqlite:///./dev.db"

    # JWT
    jwt_secret_key: str = "insecure-dev-secret-change-me"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 60
    refresh_token_expire_days: int = 30

    # Uploads
    upload_dir: str = "uploads"

    # SMTP
    smtp_host: str = "localhost"
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_from: str = "Kaundia Member Registry <no-reply@example.com>"

    # Admin bootstrap
    admin_email: str = "admin@example.com"
    admin_password: str = "change-this-password"
    admin_name: str = "Administrator"

    # CORS
    cors_origins: str = "http://localhost:9091"

    @property
    def cors_origins_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
