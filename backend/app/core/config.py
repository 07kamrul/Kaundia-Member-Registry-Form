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
        default="উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটি", validation_alias="SMTP_SENDER_NAME"
    )

    # Admin bootstrap
    admin_email: str = "admin@example.com"
    admin_password: str = "change-this-password"
    admin_name: str = "Administrator"
    admin_role: str = "super_admin"

    # CORS
    cors_origins: str = "http://localhost:9091"

    # Public website link included in member emails (login page etc.)
    frontend_base_url: str = "http://localhost:9091"

    # Organization identity used on generated documents (PDF letterhead).
    organization_name: str = Field(
        default="উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটি", validation_alias="ORGANIZATION_NAME"
    )

    # Approving a fund transaction at or above this amount auto-publishes a
    # member notice, so notable money movement is always announced.
    finance_notice_threshold: float = Field(default=50000, validation_alias="FINANCE_NOTICE_THRESHOLD")

    # Neighbour directory: how many nearest distinct dags are listed around
    # each of a member's own dags, and the per-member lookup rate limit that
    # guards the directory against scraping.
    neighbour_plot_limit: int = Field(default=5, ge=1, le=50, validation_alias="NEIGHBOUR_PLOT_LIMIT")
    neighbour_lookup_rate_limit: int = Field(default=30, ge=1, validation_alias="NEIGHBOUR_LOOKUP_RATE_LIMIT")
    neighbour_lookup_rate_window_seconds: int = Field(
        default=600, ge=1, validation_alias="NEIGHBOUR_LOOKUP_RATE_WINDOW_SECONDS"
    )

    # Plot boundaries (member-drawn polygons).
    # Society bounding box as "minLng,minLat,maxLng,maxLat" — polygons outside
    # it are rejected. Defaults to Bangladesh; tighten to the society area.
    boundary_society_bbox: str = Field(
        default="88.0,20.5,92.7,26.7", validation_alias="BOUNDARY_SOCIETY_BBOX"
    )
    boundary_max_vertices: int = Field(default=200, ge=3, validation_alias="BOUNDARY_MAX_VERTICES")
    # Computed area vs declared land quantity: a warning (not an error) beyond
    # this percentage difference, shown to the member and the reviewer.
    boundary_area_tolerance_pct: float = Field(
        default=25, ge=0, validation_alias="BOUNDARY_AREA_TOLERANCE_PCT"
    )
    # Overlaps smaller than this are treated as edge-touching, not a dispute.
    boundary_min_overlap_sqm: float = Field(
        default=1.0, ge=0, validation_alias="BOUNDARY_MIN_OVERLAP_SQM"
    )
    boundary_map_result_cap: int = Field(
        default=500, ge=1, validation_alias="BOUNDARY_MAP_RESULT_CAP"
    )
    # When true, anonymous visitors get the live map with dag numbers only —
    # never owner names or mobiles. Off by default because the owner popup
    # carries personal contact details.
    boundary_map_public_view: bool = Field(
        default=False, validation_alias="BOUNDARY_MAP_PUBLIC_VIEW"
    )
    boundary_owner_lookup_rate_limit: int = Field(
        default=30, ge=1, validation_alias="BOUNDARY_OWNER_LOOKUP_RATE_LIMIT"
    )
    boundary_owner_lookup_rate_window_seconds: int = Field(
        default=600, ge=1, validation_alias="BOUNDARY_OWNER_LOOKUP_RATE_WINDOW_SECONDS"
    )

    # Dag detail dialog: owner names per dag, so lookups are rate-limited + audited.
    dag_detail_rate_limit: int = Field(
        default=60, ge=1, validation_alias="DAG_DETAIL_RATE_LIMIT"
    )
    dag_detail_rate_window_seconds: int = Field(
        default=600, ge=1, validation_alias="DAG_DETAIL_RATE_WINDOW_SECONDS"
    )

    # Local land dataset (ingested BDS mouza map) served via /api/land.
    # Baked into the Docker image read-only; verified against meta.json
    # checksums at startup — a bad dataset must fail the boot, not the map.
    land_data_dir: str = Field(default="data/uttar-kaundia", validation_alias="LAND_DATA_DIR")
    # Must stay above the dataset size (6.8k BDS dags + 2.5k RAJUK RS plots):
    # the whole mouza is visible in one viewport, and a lower cap silently
    # drops sheets from the map (the client only gets `truncated: true`).
    shared_data_dir: str = Field(default="data/shared", validation_alias="SHARED_DATA_DIR")
    land_map_result_cap: int = Field(default=10_000, ge=1, validation_alias="LAND_MAP_RESULT_CAP")

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
