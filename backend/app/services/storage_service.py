import os
from typing import Optional
from supabase import create_client, Client
from app.config import settings
from app.utils.upload import validate_image_properties, generate_unique_filename


class StorageService:
    """Supabase Storage service with local storage fallback."""

    def __init__(self):
        self.url = settings.SUPABASE_URL
        self.key = settings.SUPABASE_SERVICE_KEY or settings.SUPABASE_ANON_KEY
        
        self.use_local = True
        self.client: Optional[Client] = None

        if self.url and self.key and "your-project-id" not in self.url:
            try:
                self.client = create_client(self.url, self.key)
                self.use_local = False
            except Exception as e:
                # Fallback to local storage if connection/initialization fails
                print(f"[StorageService] Gagal menginisialisasi Supabase client: {e}. Mengaktifkan fallback lokal.")
                self.use_local = True

    async def upload_file(
        self,
        file_data: bytes,
        bucket: str,
        user_id: str,
        filename: str,
        content_type: str,
    ) -> dict:
        """Upload file to Supabase Storage or local fallback."""
        validate_image_properties(content_type, len(file_data), bucket)

        # Generate unique filename
        unique_name = generate_unique_filename(filename)
        file_path = f"{user_id}/{unique_name}"

        if not self.use_local and self.client is not None:
            try:
                import asyncio
                # Upload to Supabase Storage with 5s timeout to prevent hanging when offline
                await asyncio.wait_for(
                    asyncio.to_thread(
                        self.client.storage.from_(bucket).upload,
                        path=file_path,
                        file=file_data,
                        file_options={"content-type": content_type},
                    ),
                    timeout=5.0
                )
                
                # Get public URL
                public_url = self.client.storage.from_(bucket).get_public_url(file_path)
                return {
                    "url": public_url,
                    "path": file_path,
                    "bucket": bucket,
                    "size": len(file_data),
                    "content_type": content_type,
                }
            except Exception as e:
                # Fallback to local storage on upload error
                print(f"[StorageService] Supabase upload failed: {e}. Falling back to local storage.")

        # Local storage fallback
        local_dir = f"static/uploads/{bucket}/{user_id}"
        os.makedirs(local_dir, exist_ok=True)
        local_path = os.path.join(local_dir, unique_name)
        
        with open(local_path, "wb") as f:
            f.write(file_data)
            
        # Return local static URL path
        public_url = f"/static/uploads/{bucket}/{user_id}/{unique_name}"
        return {
            "url": public_url,
            "path": file_path,
            "bucket": bucket,
            "size": len(file_data),
            "content_type": content_type,
            "is_local": True
        }

    def delete_file(self, bucket: str, path: str) -> bool:
        """Delete file from Supabase Storage or local filesystem."""
        if not self.use_local and self.client is not None:
            try:
                self.client.storage.from_(bucket).remove([path])
                return True
            except Exception as e:
                print(f"[StorageService] Supabase delete failed: {e}")
                # Try local file deletion as fallback if not deleted from Supabase
        
        # Local deletion
        local_path = f"static/uploads/{bucket}/{path}"
        if os.path.exists(local_path):
            try:
                os.remove(local_path)
                return True
            except Exception:
                return False
        return False

    def get_public_url(self, bucket: str, path: str) -> str:
        """Get public URL for a file."""
        if not self.use_local and self.client is not None:
            return self.client.storage.from_(bucket).get_public_url(path)
        return f"/static/uploads/{bucket}/{path}"
