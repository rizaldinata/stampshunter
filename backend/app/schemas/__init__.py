from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime


# --- Auth Schemas ---

class RegisterRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: str = Field(..., max_length=255)
    password: str = Field(..., min_length=8, max_length=128)
    display_name: Optional[str] = Field(None, max_length=100)


class LoginRequest(BaseModel):
    email: str
    password: str


class RefreshRequest(BaseModel):
    refresh_token: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class AuthResponse(BaseModel):
    user: "UserResponse"
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


# --- User Schemas ---

class UserResponse(BaseModel):
    id: str
    username: str
    email: str
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    bio: Optional[str] = None
    is_verified: bool = False
    stamps_count: int = 0
    followers_count: int = 0
    following_count: int = 0
    created_at: datetime

    class Config:
        from_attributes = True


class UserPublicResponse(BaseModel):
    id: str
    username: str
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    bio: Optional[str] = None
    is_verified: bool = False
    stamps_count: int = 0
    followers_count: int = 0
    following_count: int = 0
    created_at: datetime

    class Config:
        from_attributes = True


class UserUpdateRequest(BaseModel):
    display_name: Optional[str] = Field(None, max_length=100)
    bio: Optional[str] = Field(None, max_length=500)


# --- Stamp Schemas ---

class StampStyle(BaseModel):
    version: str = "1.0"
    border: Optional[dict] = None
    filter: Optional[dict] = None
    template: Optional[dict] = None
    text: Optional[dict] = None


class StampCreateRequest(BaseModel):
    title: Optional[str] = Field(None, max_length=200)
    description: Optional[str] = Field(None, max_length=2000)
    stamp_style: StampStyle
    tags: Optional[list[str]] = None
    is_public: bool = True


class StampResponse(BaseModel):
    id: str
    user_id: str
    original_image_url: Optional[str] = None
    stamp_image_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    stamp_style: Optional[dict] = None
    tags: Optional[list[str]] = None
    is_public: bool = True
    likes_count: int = 0
    comments_count: int = 0
    views_count: int = 0
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# --- Common ---

class APIResponse(BaseModel):
    success: bool = True
    data: Optional[dict | list] = None
    message: str = "Success"
    meta: Optional[dict] = None


class ErrorResponse(BaseModel):
    success: bool = False
    error: dict
