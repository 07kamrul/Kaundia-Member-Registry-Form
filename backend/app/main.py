from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.routes import admin, auth, member, submissions
from app.core.config import get_settings

settings = get_settings()

app = FastAPI(title="Kaundia Member Registry API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

api_router_prefix = "/api"
app.include_router(submissions.router, prefix=api_router_prefix)
app.include_router(auth.router, prefix=api_router_prefix)
app.include_router(admin.router, prefix=api_router_prefix)
app.include_router(member.router, prefix=api_router_prefix)

upload_dir = Path(settings.upload_dir)
upload_dir.mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=str(upload_dir)), name="uploads")


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
