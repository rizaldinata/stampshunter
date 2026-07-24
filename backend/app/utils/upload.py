import uuid
from typing import Set
from app.core.exceptions import ValidationError

ALLOWED_TYPES: Set[str] = {"image/jpeg", "image/png", "image/webp", "image/jpg"}


def get_file_extension(filename: str) -> str:
    """Extract and sanitize file extension from a filename."""
    if "." in filename:
        return filename.rsplit(".", 1)[-1].lower()
    return "png"


def generate_unique_filename(filename: str) -> str:
    """Generate a unique filename using UUID and original extension."""
    ext = get_file_extension(filename)
    return f"{uuid.uuid4().hex}.{ext}"


def validate_image_properties(content_type: str, size: int, bucket: str) -> None:
    """Validate image MIME type and size based on bucket policies."""
    if content_type not in ALLOWED_TYPES:
        raise ValidationError(
            [
                {
                    "loc": ["file"],
                    "msg": f"Tipe file tidak didukung: {content_type}. Hanya JPG, PNG, dan WEBP yang diizinkan.",
                }
            ]
        )

    # Determine size limits per bucket rules
    limit = 10 * 1024 * 1024  # Default 10MB
    if bucket == "avatars":
        limit = 5 * 1024 * 1024  # 5MB
    elif bucket == "thumbnails":
        limit = 2 * 1024 * 1024  # 2MB

    if size > limit:
        limit_mb = limit // (1024 * 1024)
        raise ValidationError(
            [
                {
                    "loc": ["file"],
                    "msg": f"Ukuran file terlalu besar untuk bucket '{bucket}' (maksimal {limit_mb}MB)",
                }
            ]
        )
