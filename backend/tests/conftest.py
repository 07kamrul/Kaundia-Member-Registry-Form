import asyncio
from collections.abc import AsyncGenerator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import StaticPool

from app.db.base import Base
from app.db.session import get_db
from app.main import app
from app.core.security import hash_password
from app.models.admin import AdminUser

TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"


@pytest_asyncio.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    engine = create_async_engine(
        TEST_DATABASE_URL, poolclass=StaticPool, connect_args={"check_same_thread": False}
    )
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    session_maker = async_sessionmaker(bind=engine, expire_on_commit=False)

    async def override_get_db() -> AsyncGenerator[AsyncSession, None]:
        async with session_maker() as session:
            yield session

    app.dependency_overrides[get_db] = override_get_db

    async with session_maker() as session:
        yield session

    app.dependency_overrides.clear()
    await engine.dispose()


@pytest_asyncio.fixture
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest_asyncio.fixture
async def admin_user(db_session: AsyncSession) -> AdminUser:
    admin = AdminUser(
        email="admin@example.com", password_hash=hash_password("adminpass123"), name="Admin"
    )
    db_session.add(admin)
    await db_session.commit()
    await db_session.refresh(admin)
    return admin
