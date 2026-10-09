import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy import text
from starlette.middleware.gzip import GZipMiddleware
from starlette.types import ASGIApp, Receive, Scope, Send

from app.api.routes import (
    admin,
    auth,
    finance,
    installment_payments,
    member,
    neighbours,
    notices,
    public,
    rbac,
    resolution_book,
    roadmap,
    society_costs,
    submissions,
)
from app.core.config import get_settings
from app.db.session import engine
from app.services.storage import UploadStaticFiles, check_upload_root

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
    check_upload_root()
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


app = FastAPI(title="উত্তর কাউন্দিয়া আবাসন মালিক কল্যাণ সোসাইটি API", lifespan=lifespan)


class CorsSafeErrorMiddleware:
    """Catches unhandled exceptions and returns a JSON 500.

    Registering an exception_handler(Exception) is not enough: Starlette wires
    that onto ServerErrorMiddleware, which sits OUTSIDE CORSMiddleware, so the
    500 it produces carries no Access-Control-Allow-Origin and the browser
    reports a misleading CORS failure instead of the real server error. As a
    user middleware this runs inside CORS, so its response keeps the headers
    and the frontend's error handling sees an actual status code."""

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        try:
            await self.app(scope, receive, send)
        except Exception:
            logger.exception("Unhandled error on %s %s", scope.get("method"), scope.get("path"))
            response = JSONResponse(status_code=500, content={"detail": "Internal server error"})
            await response(scope, receive, send)


# Added BEFORE CORS so it runs INSIDE it (first-added middleware is outermost
# here): its error responses must pass back through CORSMiddleware to gain the
# Access-Control-Allow-* headers, otherwise the browser reports a misleading
# CORS failure instead of the real 500.
app.add_middleware(CorsSafeErrorMiddleware)

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
app.include_router(notices.router, prefix=api_router_prefix)
app.include_router(member.router, prefix=api_router_prefix)
app.include_router(neighbours.router, prefix=api_router_prefix)
app.include_router(rbac.router, prefix=api_router_prefix)
app.include_router(public.router, prefix=api_router_prefix)
app.include_router(society_costs.router, prefix=api_router_prefix)
app.include_router(finance.router, prefix=api_router_prefix)
app.include_router(roadmap.router, prefix=api_router_prefix)
app.include_router(resolution_book.router, prefix=api_router_prefix)
app.include_router(installment_payments.router, prefix=api_router_prefix)

app.mount("/uploads", UploadStaticFiles(), name="uploads")


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}
