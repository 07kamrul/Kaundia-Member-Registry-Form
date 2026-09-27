from datetime import datetime

from pydantic import BaseModel, ConfigDict


class AuditLogOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    actor_admin_id: int | None = None
    action: str
    entity_type: str
    entity_id: str
    detail: str | None = None
    created_at: datetime
