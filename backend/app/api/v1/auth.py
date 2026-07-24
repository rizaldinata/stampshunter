from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.database import get_db
from app.models.user import User
from app.schemas import RegisterRequest, LoginRequest, RefreshRequest, AuthResponse, UserResponse, TokenResponse
from app.core.security import hash_password, verify_password, create_access_token, create_refresh_token, decode_refresh_token
from app.core.exceptions import ConflictError, InvalidCredentialsError, AuthenticationError

router = APIRouter()


@router.post("/register", response_model=AuthResponse, status_code=201)
async def register(req: RegisterRequest, db: AsyncSession = Depends(get_db)):
    # Check duplicate
    result = await db.execute(select(User).where(User.email == req.email))
    if result.scalar_one_or_none():
        raise ConflictError("Email sudah terdaftar")

    result = await db.execute(select(User).where(User.username == req.username))
    if result.scalar_one_or_none():
        raise ConflictError("Username sudah digunakan")

    user = User(
        username=req.username,
        email=req.email,
        password_hash=hash_password(req.password),
        display_name=req.display_name,
    )
    db.add(user)
    await db.flush()
    await db.refresh(user)

    access_token = create_access_token({"sub": user.id})
    refresh_token = create_refresh_token({"sub": user.id})

    return AuthResponse(
        user=UserResponse.model_validate(user),
        access_token=access_token,
        refresh_token=refresh_token,
    )


@router.post("/login", response_model=AuthResponse)
async def login(req: LoginRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == req.email))
    user = result.scalar_one_or_none()

    if not user or not verify_password(req.password, user.password_hash):
        raise InvalidCredentialsError()

    access_token = create_access_token({"sub": user.id})
    refresh_token = create_refresh_token({"sub": user.id})

    return AuthResponse(
        user=UserResponse.model_validate(user),
        access_token=access_token,
        refresh_token=refresh_token,
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_access_token(
    req: RefreshRequest,
    db: AsyncSession = Depends(get_db),
):
    """Tukar refresh token yang valid dengan access token baru."""
    try:
        payload = decode_refresh_token(req.refresh_token)
    except ValueError as e:
        raise AuthenticationError(str(e))

    user_id = payload.get("sub")
    if not user_id:
        raise AuthenticationError("Payload refresh token tidak valid")

    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user or not user.is_active:
        raise AuthenticationError("Akun tidak ditemukan atau tidak aktif")

    new_access_token = create_access_token({"sub": user.id})
    new_refresh_token = create_refresh_token({"sub": user.id})

    return TokenResponse(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
    )
