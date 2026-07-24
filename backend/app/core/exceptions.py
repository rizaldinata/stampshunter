from fastapi import HTTPException


class AppException(HTTPException):
    def __init__(self, code: str, message: str, status_code: int = 500, details: list = None):
        self.code = code
        self.message = message
        self.details = details or []
        super().__init__(status_code=status_code, detail=message)


class AuthenticationError(AppException):
    def __init__(self, message: str = "Autentikasi diperlukan"):
        super().__init__(code="AUTH_ERROR", message=message, status_code=401)


class InvalidCredentialsError(AppException):
    def __init__(self):
        super().__init__(code="INVALID_CREDENTIALS", message="Email atau password salah", status_code=401)


class ForbiddenError(AppException):
    def __init__(self, message: str = "Kamu tidak punya akses"):
        super().__init__(code="FORBIDDEN", message=message, status_code=403)


class NotFoundError(AppException):
    def __init__(self, resource: str = "Data", resource_id: str = ""):
        msg = f"{resource} tidak ditemukan" + (f": {resource_id}" if resource_id else "")
        super().__init__(code="NOT_FOUND", message=msg, status_code=404)


class ConflictError(AppException):
    def __init__(self, message: str = "Data sudah ada"):
        super().__init__(code="CONFLICT", message=message, status_code=409)


class ValidationError(AppException):
    def __init__(self, details: list):
        super().__init__(code="VALIDATION_ERROR", message="Data yang dimasukkan tidak valid", status_code=422, details=details)


class RateLimitError(AppException):
    def __init__(self, retry_after: int = 60):
        super().__init__(code="RATE_LIMITED", message=f"Terlalu banyak percobaan. Coba lagi dalam {retry_after} detik.", status_code=429)
