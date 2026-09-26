from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text
from starlette.middleware.gzip import GZipMiddleware

from app.api.routes import admin, auth, member, public, rbac, submissions
from app.core.config import get_settings
from app.db.session import engine

settings = get_settings()


@asynccontextmanager
async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
    # Warm the pool so the first request doesn't pay connection setup (remote
    # Postgres handshakes dominate first-hit latency), then release everything
    # cleanly on shutdown so the process exits without dangling connections.
    try:
        async with engine.connect() as connection:
            await connection.execute(text("SELECT 1"))
    except Exception:  # noqa: BLE001 - a cold pool must never block startup
        pass
    try:
        yield
    finally:
        await engine.dispose()


app = FastAPI(title="উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ পরিষদ API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Added after CORS so it wraps it: responses stay CORS-readable while large
# JSON payloads (profile, submissions) shrink dramatically over the wire.
# compresslevel 6 is within ~2% of 9 on JSON but several times cheaper to
# compute, and Starlette only offloads bodies >=128 KiB to a worker thread -
# everything smaller is compressed inline on the event loop.
app.add_middleware(GZipMiddleware, minimum_size=1000, compresslevel=6)

api_router_prefix = "/api"
app.include_router(submissions.router, prefix=api_router_prefix)
app.include_router(auth.router, prefix=api_router_prefix)
app.include_router(admin.router, prefix=api_router_prefix)
app.include_router(member.router, prefix=api_router_prefix)
app.include_router(rbac.router, prefix=api_router_prefix)
app.include_router(public.router, prefix=api_router_prefix)

upload_dir = Path(settings.upload_dir)
upload_dir.mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=str(upload_dir)), name="uploads")


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
