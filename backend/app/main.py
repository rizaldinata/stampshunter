from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.config import settings
from app.api.v1 import auth, users, stamps, upload, feed
from app.core.exceptions import AppException


def create_app() -> FastAPI:
    app = FastAPI(
        title="StampsHunter API",
        description="API untuk StampsHunter - stamp digital platform",
        version="0.1.0",
        docs_url="/docs" if settings.DEBUG else None,
        redoc_url="/redoc" if settings.DEBUG else None,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.exception_handler(AppException)
    async def app_exception_handler(request: Request, exc: AppException):
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "detail": {
                    "code": exc.code,
                    "message": exc.message,
                }
            },
        )

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception):
        return JSONResponse(
            status_code=500,
            content={
                "detail": {
                    "code": "INTERNAL_ERROR",
                    "message": "Terjadi kesalahan server. Coba lagi nanti.",
                }
            },
        )

    from fastapi.staticfiles import StaticFiles
    import os

    os.makedirs("static/avatars", exist_ok=True)
    app.mount("/static", StaticFiles(directory="static"), name="static")

    app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
    app.include_router(users.router, prefix="/api/v1/users", tags=["users"])
    app.include_router(stamps.router, prefix="/api/v1/stamps", tags=["stamps"])
    app.include_router(upload.router, prefix="/api/v1/upload", tags=["upload"])
    app.include_router(feed.router, prefix="/api/v1/feed", tags=["feed"])

    @app.get("/health")
    async def health():
        return {"status": "ok", "service": "stampshunter-api"}

    return app


app = create_app()
