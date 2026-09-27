from sqlalchemy.ext.asyncio import AsyncSession

from app.models.audit_log import AuditLog


def record_audit(
    db: AsyncSession,
    *,
    actor_admin_id: int | None,
    action: str,
    entity_type: str,
    entity_id: str,
    detail: str | None = None,
) -> None:
    """Stage an audit log row on `db`. Caller commits (usually alongside its own change)."""
    db.add(
        AuditLog(
            actor_admin_id=actor_admin_id,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            detail=detail,
        )
    )
