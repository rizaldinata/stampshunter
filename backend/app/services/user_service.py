import os
import uuid
from typing import Optional, List
from fastapi import UploadFile
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.models.user import User
from app.models.stamp import Stamp
from app.models.follow import Follow
from app.core.exceptions import NotFoundError, ValidationError


async def get_user_profile_with_stats(db: AsyncSession, user_id: str) -> User:
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise NotFoundError("User", user_id)

    stamps_count_result = await db.execute(
        select(func.count(Stamp.id)).where(
            Stamp.user_id == user_id
        )
    )
    stamps_count = stamps_count_result.scalar() or 0

    followers_count_result = await db.execute(
        select(func.count(Follow.follower_id)).where(Follow.following_id == user_id)
    )
    followers_count = followers_count_result.scalar() or 0

    following_count_result = await db.execute(
        select(func.count(Follow.following_id)).where(Follow.follower_id == user_id)
    )
    following_count = following_count_result.scalar() or 0

    user.stamps_count = stamps_count
    user.followers_count = followers_count
    user.following_count = following_count

    return user


async def update_user_profile(
    db: AsyncSession,
    user: User,
    display_name: Optional[str] = None,
    bio: Optional[str] = None,
    avatar_file: Optional[UploadFile] = None,
) -> User:
    if display_name is not None:
        if len(display_name) > 100:
            raise ValidationError(
                [
                    {
                        "loc": ["display_name"],
                        "msg": "Display name terlalu panjang (maksimal 100 karakter)",
                    }
                ]
            )
        user.display_name = display_name

    if bio is not None:
        if len(bio) > 500:
            raise ValidationError(
                [
                    {
                        "loc": ["bio"],
                        "msg": "Bio terlalu panjang (maksimal 500 karakter)",
                    }
                ]
            )
        user.bio = bio

    if avatar_file is not None:
        if avatar_file.content_type not in ["image/jpeg", "image/png", "image/jpg"]:
            raise ValidationError(
                [
                    {
                        "loc": ["avatar"],
                        "msg": "Format file tidak didukung (harus JPG/PNG)",
                    }
                ]
            )

        contents = await avatar_file.read()
        if len(contents) > 5 * 1024 * 1024:
            raise ValidationError(
                [
                    {
                        "loc": ["avatar"],
                        "msg": "Ukuran file terlalu besar (maksimal 5MB)",
                    }
                ]
            )

        os.makedirs("static/avatars", exist_ok=True)
        ext = (
            avatar_file.filename.split(".")[-1].lower()
            if avatar_file.filename
            else "png"
        )
        filename = f"{uuid.uuid4().hex}.{ext}"
        filepath = os.path.join("static/avatars", filename)

        with open(filepath, "wb") as f:
            f.write(contents)

        user.avatar_url = f"/static/avatars/{filename}"

    db.add(user)
    await db.flush()
    return user


async def get_user_stamps(
    db: AsyncSession, user_id: str, page: int = 1, limit: int = 20
) -> List[Stamp]:
    query = (
        select(Stamp)
        .where(Stamp.user_id == user_id)
        .order_by(Stamp.created_at.desc())
        .offset((page - 1) * limit)
        .limit(limit)
    )
    result = await db.execute(query)
    return result.scalars().all()


async def get_user_stamps_count(db: AsyncSession, user_id: str) -> int:
    result = await db.execute(
        select(func.count(Stamp.id)).where(
            Stamp.user_id == user_id
        )
    )
    return result.scalar() or 0
