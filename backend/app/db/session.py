from collections.abc import AsyncGenerator

from sqlalchemy import event
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker, create_async_engine

from app.core.config import get_settings

settings = get_settings()


def _build_engine(url: str) -> AsyncEngine:
    """Create the async engine with pool settings tuned for the workload.

    - ``pool_pre_ping`` issues a lightweight round-trip before handing out a
      connection, so an idle connection dropped by a firewall/NAT is detected
      here instead of mid-request (important for the remote Postgres URL).
    - ``pool_recycle`` retires connections before common server-side idle
      timeouts, avoiding "server has gone away" errors after quiet periods.
    - Pool sizing is only meaningful for the pooled DBAPI drivers; SQLite URLs
      default to ``NullPool``-like behaviour and ignore these kwargs.
    """
    return create_async_engine(
        url,
        echo=False,
        future=True,
        pool_pre_ping=True,
        pool_recycle=1800,
        pool_size=10,
        max_overflow=20,
        pool_timeout=30,
    )


engine = _build_engine(settings.database_url)

if settings.database_url.startswith("sqlite"):
    # WAL lets readers proceed while a writer holds the lock (the admin panel
    # polls lists while submissions insert), and NORMAL synchronous is safe
    # under WAL while being meaningfully faster than the FULL default.
    @event.listens_for(engine.sync_engine, "connect")
    def _set_sqlite_pragmas(dbapi_connection, _connection_record) -> None:  # type: ignore[no-untyped-def]
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA journal_mode=WAL")
        cursor.execute("PRAGMA synchronous=NORMAL")
        cursor.execute("PRAGMA temp_store=MEMORY")
        cursor.execute("PRAGMA cache_size=-16000")  # ~16 MB page cache
        cursor.close()


AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        yield session
