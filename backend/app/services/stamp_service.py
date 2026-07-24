import uuid
from typing import Dict, List, Optional
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import ForbiddenError
from app.models.stamp import Stamp
from app.services.image_processor import ImageProcessor
from app.services.storage_service import StorageService


class StampService:
    def __init__(self, db: AsyncSession, storage: StorageService, processor: ImageProcessor):
        self.db = db
        self.storage = storage
        self.processor = processor

    async def create_stamp(
        self,
        user_id: str,
        image_data: bytes,
        filename: str,
        content_type: str,
        style: dict,
        title: Optional[str] = None,
        description: Optional[str] = None,
        tags: Optional[List[str]] = None,
        is_public: bool = True,
    ) -> Stamp:
        # Generate a base unique UUID name for the files
        base_uuid = uuid.uuid4().hex
        ext = filename.split(".")[-1] if "." in filename else "jpg"

        # 1. Upload original image to 'stamps' bucket
        orig_filename = f"original_{base_uuid}.{ext}"
        orig_upload = await self.storage.upload_file(
            file_data=image_data,
            bucket="stamps",
            user_id=user_id,
            filename=orig_filename,
            content_type=content_type,
        )
        original_url = orig_upload["url"]

        # 2. Process image with stamp effects
        processed_data = self.processor.process(image_data, style)

        # 3. Upload processed image to 'stamps' bucket
        proc_filename = f"stamp_{base_uuid}.png"
        proc_upload = await self.storage.upload_file(
            file_data=processed_data,
            bucket="stamps",
            user_id=user_id,
            filename=proc_filename,
            content_type="image/png",  # Processed is always PNG
        )
        stamp_url = proc_upload["url"]

        # 4. Generate & Upload thumbnail to 'stamps' bucket
        thumb_data = self.processor.generate_thumbnail(processed_data)
        thumb_filename = f"thumb_{base_uuid}.png"
        thumb_upload = await self.storage.upload_file(
            file_data=thumb_data,
            bucket="stamps",
            user_id=user_id,
            filename=thumb_filename,
            content_type="image/png",
        )
        thumbnail_url = thumb_upload["url"]

        # 5. Save to database
        stamp = Stamp(
            id=str(uuid.uuid4()),
            user_id=user_id,
            original_image_url=original_url,
            stamp_image_url=stamp_url,
            thumbnail_url=thumbnail_url,
            title=title,
            description=description,
            stamp_style=style,
            tags=tags or [],
            is_public=is_public,
        )
        self.db.add(stamp)
        await self.db.commit()
        await self.db.refresh(stamp)
        return stamp

    async def get_stamp(self, stamp_id: str) -> Optional[Stamp]:
        result = await self.db.execute(select(Stamp).where(Stamp.id == stamp_id))
        return result.scalar_one_or_none()

    async def list_stamps(self, page: int = 1, limit: int = 20) -> List[Stamp]:
        offset = (page - 1) * limit
        result = await self.db.execute(
            select(Stamp)
            .where(Stamp.is_public == True)
            .order_by(Stamp.created_at.desc())
            .offset(offset)
            .limit(limit)
        )
        return list(result.scalars().all())

    async def delete_stamp(self, stamp_id: str, user_id: str) -> bool:
        stamp = await self.get_stamp(stamp_id)
        if not stamp:
            return False

        # Ensure only the owner can delete the stamp
        if stamp.user_id != user_id:
            raise ForbiddenError("Anda tidak memiliki izin untuk menghapus stamp ini")

        # Delete from DB
        await self.db.execute(delete(Stamp).where(Stamp.id == stamp_id))
        await self.db.commit()

        # Helper to parse filename path from URL
        def get_path_from_url(url: str) -> Optional[str]:
            for pattern in ["/stamps/", "stamps/"]:
                if pattern in url:
                    return url.split(pattern)[-1]
            return None

        # Delete files from storage
        for url in [stamp.original_image_url, stamp.stamp_image_url, stamp.thumbnail_url]:
            if url:
                path = get_path_from_url(url)
                if path:
                    # Clean query params if any (e.g. from Supabase URLs)
                    path = path.split("?")[0]
                    self.storage.delete_file("stamps", path)

        return True
