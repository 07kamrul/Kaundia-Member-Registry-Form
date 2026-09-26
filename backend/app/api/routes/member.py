from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_current_member, get_current_member_detail
from app.core.security import hash_password_async, verify_password_async
from app.db.session import get_db
from app.models.credential import MemberCredential
from app.models.installment import Installment
from app.models.member import Member
from app.schemas.auth import ChangePasswordRequest
from app.schemas.installment import InstallmentOut
from app.schemas.member import MemberDetail

router = APIRouter(prefix="/member", tags=["member"])


@router.get("/me", response_model=MemberDetail)
async def get_my_profile(
    member: Member = Depends(get_current_member_detail),
) -> Member:
    # The dependency already authenticated *and* eager-loaded the detail graph
    # in a single query set; re-selecting the member here used to double the
    # round-trips for the most frequently hit member endpoint.
    return member


@router.get("/installments", response_model=list[InstallmentOut])
async def list_my_installments(
    member: Member = Depends(get_current_member),
    db: AsyncSession = Depends(get_db),
) -> list[Installment]:
    result = await db.execute(
        select(Installment).where(Installment.member_id == member.id).order_by(
            Installment.year, Installment.month
        )
    )
    return list(result.scalars().all())


@router.post("/change-password", status_code=status.HTTP_204_NO_CONTENT)
async def change_password(
    payload: ChangePasswordRequest,
    member: Member = Depends(get_current_member),
    db: AsyncSession = Depends(get_db),
) -> None:
    result = await db.execute(
        select(MemberCredential).where(MemberCredential.member_id == member.id)
    )
    credential = result.scalar_one_or_none()
    if credential is None or not await verify_password_async(payload.current_password, credential.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid current password")

    credential.password_hash = await hash_password_async(payload.new_password)
    credential.must_change_password = False
    await db.commit()
