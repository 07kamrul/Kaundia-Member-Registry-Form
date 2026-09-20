from pydantic import BaseModel


class PublicStatsOut(BaseModel):
    pending_count: int
    approved_count: int
    monthly_subscription_total: float
