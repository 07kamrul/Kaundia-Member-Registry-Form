"""Bootstrap script: creates an initial admin user from ADMIN_EMAIL /
ADMIN_PASSWORD / ADMIN_NAME env vars if one does not already exist.

Run with: python -m app.seed
"""
import asyncio

from sqlalchemy import select

from app.core.config import get_settings
from app.core.security import hash_password
from app.db.session import AsyncSessionLocal
from app.models.admin import AdminUser

settings = get_settings()


async def seed_admin() -> None:
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(AdminUser).where(AdminUser.email == settings.admin_email))
        existing = result.scalar_one_or_none()
        if existing is not None:
            print(f"Admin user already exists: {settings.admin_email}")
            return

        admin = AdminUser(
            email=settings.admin_email,
            password_hash=hash_password(settings.admin_password),
            name=settings.admin_name,
        )
        db.add(admin)
        await db.commit()
        print(f"Created admin user: {settings.admin_email}")


if __name__ == "__main__":
    asyncio.run(seed_admin())
