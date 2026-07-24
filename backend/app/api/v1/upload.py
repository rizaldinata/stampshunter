from typing import List
from fastapi import APIRouter, Depends, File, Form, UploadFile
from pydantic import BaseModel, Field
from app.api.deps import get_current_user
from app.models.user import User
from app.services.storage_service import StorageService
from app.core.exceptions import ValidationError, NotFoundError

router = APIRouter()
storage_service = StorageService()

VALID_BUCKETS = {"avatars", "stamps", "thumbnails", "originals"}


class DeleteRequest(BaseModel):
    bucket: str = Field(..., description="Nama storage bucket")
    path: str = Field(..., description="Path relatif file di dalam bucket")


@router.post("/image")
async def upload_image(
    file: UploadFile = File(...),
    bucket: str = Form(...),
    current_user: User = Depends(get_current_user),
):
    """Upload a single image to the specified bucket."""
    if bucket not in VALID_BUCKETS:
        raise ValidationError(
            [
                {
                    "loc": ["bucket"],
                    "msg": f"Bucket '{bucket}' tidak valid. Pilih salah satu dari {list(VALID_BUCKETS)}.",
                }
            ]
        )

    file_data = await file.read()
    result = await storage_service.upload_file(
        file_data=file_data,
        bucket=bucket,
        user_id=str(current_user.id),
        filename=file.filename or "image.png",
        content_type=file.content_type or "image/png",
    )
    return {"success": True, "data": result}


@router.post("/multiple")
async def upload_multiple_images(
    files: List[UploadFile] = File(...),
    bucket: str = Form(...),
    current_user: User = Depends(get_current_user),
):
    """Upload multiple images (maximum 5) to the specified bucket."""
    if bucket not in VALID_BUCKETS:
        raise ValidationError(
            [
                {
                    "loc": ["bucket"],
                    "msg": f"Bucket '{bucket}' tidak valid. Pilih salah satu dari {list(VALID_BUCKETS)}.",
                }
            ]
        )

    if len(files) > 5:
        raise ValidationError(
            [
                {
                    "loc": ["files"],
                    "msg": "Jumlah file maksimal adalah 5 berkas.",
                }
            ]
        )

    uploaded = []
    failed = []

    for file in files:
        try:
            file_data = await file.read()
            result = await storage_service.upload_file(
                file_data=file_data,
                bucket=bucket,
                user_id=str(current_user.id),
                filename=file.filename or "image.png",
                content_type=file.content_type or "image/png",
            )
            uploaded.append({
                "url": result["url"],
                "path": result["path"],
                "bucket": result["bucket"],
                "filename": file.filename
            })
        except Exception as e:
            failed.append({
                "filename": file.filename or "unknown",
                "error": str(e)
            })

    return {
        "success": True,
        "data": {
            "uploaded": uploaded,
            "failed": failed
        }
    }


@router.delete("")
async def delete_file(
    req: DeleteRequest,
    current_user: User = Depends(get_current_user),
):
    """Delete a file from the specified bucket."""
    if req.bucket not in VALID_BUCKETS:
        raise ValidationError(
            [
                {
                    "loc": ["bucket"],
                    "msg": f"Bucket '{req.bucket}' tidak valid.",
                }
            ]
        )

    # Security check: Ensure user can only delete their own files
    # The path starts with user_id/
    path_owner = req.path.split("/")[0] if "/" in req.path else ""
    if path_owner != str(current_user.id):
         raise ValidationError(
            [
                {
                    "loc": ["path"],
                    "msg": "Anda tidak memiliki izin untuk menghapus file ini.",
                }
            ]
        )

    deleted = storage_service.delete_file(req.bucket, req.path)
    if not deleted:
        raise NotFoundError("File", req.path)

    return {"success": True, "message": "File berhasil dihapus"}
