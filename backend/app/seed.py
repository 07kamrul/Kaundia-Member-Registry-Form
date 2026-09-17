"""Bootstrap script: creates an initial admin user from ADMIN_EMAIL /
ADMIN_PASSWORD / ADMIN_NAME env vars if one does not already exist.

Run with: python -m app.seed
"""
import asyncio

from sqlalchemy import select

from app.core.config import get_settings
from app.core.security import hash_password
from app.db.session import AsyncSessionLocal
from app.models.admin import AdminRole, AdminUser
from app.models.rbac import Role

settings = get_settings()


async def seed_admin() -> None:
    async with AsyncSessionLocal() as db:
        result = await db.execute(select(AdminUser).where(AdminUser.email == settings.admin_email))
        existing = result.scalar_one_or_none()
        if existing is not None:
            print(f"Admin user already exists: {settings.admin_email}")
            return

        role_result = await db.execute(select(Role).where(Role.name == settings.admin_role))
        role = role_result.scalar_one_or_none()

        admin = AdminUser(
            email=settings.admin_email,
            password_hash=hash_password(settings.admin_password),
            name=settings.admin_name,
            role=AdminRole(settings.admin_role),
            role_id=role.id if role is not None else None,
        )
        db.add(admin)
        await db.commit()
        print(f"Created admin user: {settings.admin_email} ({admin.role.value})")


if __name__ == "__main__":
    asyncio.run(seed_admin())
