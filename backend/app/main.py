import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from starlette.middleware.gzip import GZipMiddleware

from app.api.routes import admin, auth, member, public, rbac, submissions
from app.core.config import get_settings
from app.db.session import engine
from app.services.storage import UploadStaticFiles

settings = get_settings()
logger = logging.getLogger(__name__)

# uvicorn attaches handlers only to its own loggers; without a root handler the
# upload save/serve paths logged by app.services.storage would be dropped, and
# comparing them is how a "file exists but /uploads 404s" report gets diagnosed.
if not logging.root.handlers:
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s: %(message)s")


@asynccontextmanager
async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
    # Uploads are written and served from this exact directory; printing it on
    # startup makes "file saved here, server looking there" mismatches obvious.
    logger.info("[uploads] serving directory: %s", settings.upload_root)
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

app.mount("/uploads", UploadStaticFiles(), name="uploads")


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
