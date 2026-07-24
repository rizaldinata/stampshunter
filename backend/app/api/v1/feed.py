from typing import Optional
from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.api.deps import get_current_user
from app.core.security import decode_access_token
from app.models.user import User
from app.services.feed_service import FeedService
from app.schemas import APIResponse
from sqlalchemy import select

router = APIRouter()


async def get_optional_user(
    request: Request,
    db: AsyncSession = Depends(get_db)
) -> Optional[User]:
    """Helper dependency to extract current user optionally without raising error."""
    auth_header = request.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        return None
    token = auth_header.split(" ")[1]
    try:
        payload = decode_access_token(token)
        user_id = payload.get("sub")
        if not user_id:
            return None
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if user and user.is_active:
            return user
    except Exception:
        pass
    return None


@router.get("/public", response_model=APIResponse)
async def get_public_feed(
    page: int = 1,
    limit: int = 20,
    sort: str = "trending",
    current_user: Optional[User] = Depends(get_optional_user),
    db: AsyncSession = Depends(get_db),
):
    """Retrieve public stamps feed with user context."""
    user_id = current_user.id if current_user else None
    data, total = await FeedService.get_public_feed(
        db=db,
        current_user_id=user_id,
        page=page,
        limit=limit,
        sort=sort
    )
    return APIResponse(
        success=True,
        data=data,
        meta={"page": page, "limit": limit, "total": total}
    )


@router.get("/following", response_model=APIResponse)
async def get_following_feed(
    page: int = 1,
    limit: int = 20,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Retrieve private feed containing only followed users' stamps."""
    data, total = await FeedService.get_following_feed(
        db=db,
        user_id=current_user.id,
        page=page,
        limit=limit
    )
    return APIResponse(
        success=True,
        data=data,
        meta={"page": page, "limit": limit, "total": total}
    )
