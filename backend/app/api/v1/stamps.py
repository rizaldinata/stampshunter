import json
from typing import Optional

from fastapi import APIRouter, Depends, File, Form, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.api.deps import get_current_user
from app.core.exceptions import NotFoundError, ValidationError
from app.database import get_db
from app.models.stamp import Stamp
from app.models.user import User
from app.schemas import APIResponse, StampResponse
from app.services.image_processor import ImageProcessor
from app.services.stamp_service import StampService
from app.services.storage_service import StorageService
from app.services.feed_service import FeedService

router = APIRouter()

# Initialize services
storage_service = StorageService()
image_processor = ImageProcessor()


@router.get("/", response_model=APIResponse)
async def list_stamps(page: int = 1, limit: int = 20, db: AsyncSession = Depends(get_db)):
    """List public stamps ordered by newest creation date."""
    offset = (page - 1) * limit
    result = await db.execute(
        select(Stamp)
        .where(Stamp.is_public == True)
        .order_by(Stamp.created_at.desc())
        .offset(offset)
        .limit(limit)
    )
    stamps = [StampResponse.model_validate(s) for s in result.scalars().all()]
    return APIResponse(
        data=[s.model_dump() for s in stamps],
        meta={"page": page, "limit": limit}
    )


@router.get("/{stamp_id}", response_model=StampResponse)
async def get_stamp(stamp_id: str, db: AsyncSession = Depends(get_db)):
    """Get stamp details by its ID."""
    result = await db.execute(select(Stamp).where(Stamp.id == stamp_id))
    stamp = result.scalar_one_or_none()
    if not stamp:
        raise NotFoundError("Stamp", stamp_id)
    return StampResponse.model_validate(stamp)


@router.post("", response_model=APIResponse, status_code=status.HTTP_201_CREATED)
async def create_stamp(
    file: UploadFile = File(...),
    title: Optional[str] = Form(None),
    description: Optional[str] = Form(None),
    tags: Optional[str] = Form(None),
    is_public: bool = Form(True),
    stamp_style: str = Form(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new stamp from an uploaded file, apply styles and save it."""
    # Validate stamp style JSON
    try:
        style_dict = json.loads(stamp_style)
    except json.JSONDecodeError:
        raise ValidationError(
            [
                {
                    "loc": ["stamp_style"],
                    "msg": "stamp_style harus berupa JSON string yang valid.",
                }
            ]
        )

    # Parse tags
    parsed_tags = []
    if tags:
        try:
            loaded_tags = json.loads(tags)
            if isinstance(loaded_tags, list):
                parsed_tags = [str(t).strip() for t in loaded_tags]
            elif isinstance(loaded_tags, str):
                parsed_tags = [t.strip() for t in loaded_tags.split(",") if t.strip()]
        except json.JSONDecodeError:
            parsed_tags = [t.strip() for t in tags.split(",") if t.strip()]

    # Read original file bytes
    file_data = await file.read()
    
    # Initialize stamp service
    stamp_service = StampService(db, storage_service, image_processor)
    
    try:
        stamp = await stamp_service.create_stamp(
            user_id=str(current_user.id),
            image_data=file_data,
            filename=file.filename or "image.jpg",
            content_type=file.content_type or "image/jpeg",
            style=style_dict,
            title=title,
            description=description,
            tags=parsed_tags,
            is_public=is_public,
        )
        
        return APIResponse(
            success=True,
            data=StampResponse.model_validate(stamp).model_dump(),
            message="Stamp berhasil dibuat"
        )
    except Exception as e:
        raise ValidationError(
            [
                {
                    "loc": ["file"],
                    "msg": f"Gagal membuat stamp: {str(e)}",
                }
            ]
        )


@router.delete("/{stamp_id}")
async def delete_stamp(
    stamp_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Delete a stamp by ID (Owner only)."""
    stamp_service = StampService(db, storage_service, image_processor)
    
    deleted = await stamp_service.delete_stamp(
        stamp_id=stamp_id,
        user_id=str(current_user.id)
    )
    
    if not deleted:
        raise NotFoundError("Stamp", stamp_id)
        
    return {"success": True, "message": "Stamp berhasil dihapus"}


from pydantic import BaseModel, Field

class CommentCreate(BaseModel):
    content: str = Field(..., description="Isi komentar")
    parent_id: Optional[str] = Field(None, description="ID komentar induk untuk balasan")


@router.post("/{stamp_id}/like", response_model=APIResponse)
async def toggle_like(
    stamp_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Like or unlike a stamp."""
    result = await FeedService.toggle_like(db, current_user.id, stamp_id)
    return APIResponse(
        success=True,
        data=result,
        message="Like status diperbarui"
    )


@router.get("/{stamp_id}/comments", response_model=APIResponse)
async def get_comments(
    stamp_id: str,
    page: int = 1,
    limit: int = 20,
    db: AsyncSession = Depends(get_db)
):
    """Get list of comments for a stamp."""
    data, total = await FeedService.get_comments(db, stamp_id, page, limit)
    return APIResponse(
        success=True,
        data=data,
        meta={"page": page, "limit": limit, "total": total}
    )


@router.post("/{stamp_id}/comments", response_model=APIResponse)
async def add_comment(
    stamp_id: str,
    req: CommentCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Add a comment to a stamp."""
    result = await FeedService.add_comment(
        db=db,
        user_id=current_user.id,
        stamp_id=stamp_id,
        content=req.content,
        parent_id=req.parent_id
    )
    return APIResponse(
        success=True,
        data=result,
        message="Komentar berhasil ditambahkan"
    )
