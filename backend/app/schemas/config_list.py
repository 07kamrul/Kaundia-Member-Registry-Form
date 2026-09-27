from datetime import datetime

from pydantic import BaseModel, ConfigDict


class ConfigListItemCreate(BaseModel):
    category: str
    value: str
    label: str
    sort_order: int = 0


class ConfigListItemUpdate(BaseModel):
    label: str | None = None
    sort_order: int | None = None
    is_active: bool | None = None


class ConfigListItemOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    category: str
    value: str
    label: str
    sort_order: int
    is_active: int
    created_at: datetime
    updated_at: datetime
