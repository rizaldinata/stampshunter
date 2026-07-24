from fastapi import APIRouter, Depends, Form, File, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional
from app.database import get_db
from app.models.user import User
from app.schemas import UserResponse, UserPublicResponse, StampResponse
from app.api.deps import get_current_user
from app.services import user_service

router = APIRouter()


@router.get("/me")
async def get_my_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    profile = await user_service.get_user_profile_with_stats(db, current_user.id)
    return {"success": True, "data": UserResponse.model_validate(profile)}


@router.get("/{user_id}")
async def get_user_profile(user_id: str, db: AsyncSession = Depends(get_db)):
    profile = await user_service.get_user_profile_with_stats(db, user_id)
    return {"success": True, "data": UserPublicResponse.model_validate(profile)}


@router.put("/me")
async def update_my_profile(
    display_name: Optional[str] = Form(None),
    bio: Optional[str] = Form(None),
    avatar: Optional[UploadFile] = File(None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    updated_user = await user_service.update_user_profile(
        db, current_user, display_name=display_name, bio=bio, avatar_file=avatar
    )
    profile = await user_service.get_user_profile_with_stats(db, updated_user.id)
    return {
        "success": True,
        "data": UserResponse.model_validate(profile),
        "message": "Profil berhasil diperbarui",
    }


@router.get("/{user_id}/stamps")
async def get_user_stamps(
    user_id: str,
    page: int = 1,
    limit: int = 20,
    db: AsyncSession = Depends(get_db),
):
    stamps = await user_service.get_user_stamps(
        db, user_id, page=page, limit=limit
    )
    total = await user_service.get_user_stamps_count(db, user_id)
    stamp_data = [StampResponse.model_validate(s) for s in stamps]
    return {
        "success": True,
        "data": stamp_data,
        "meta": {"page": page, "limit": limit, "total": total},
    }
