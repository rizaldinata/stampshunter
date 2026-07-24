from fastapi import Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.core.security import decode_access_token
from app.core.exceptions import AuthenticationError, NotFoundError
from app.models.user import User
from sqlalchemy import select

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db),
) -> User:
    token = credentials.credentials
    try:
        payload = decode_access_token(token)
    except ValueError as e:
        raise AuthenticationError(str(e))

    user_id = payload.get("sub")
    if not user_id:
        raise AuthenticationError("Payload token tidak valid")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise NotFoundError("User", user_id)

    if not user.is_active:
        raise AuthenticationError("Akun tidak aktif")

    return user
