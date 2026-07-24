import pytest
import asyncio
import uuid
from httpx import AsyncClient, ASGITransport
from app.main import app





@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


async def get_auth_token(client):
    uid = uuid.uuid4().hex[:8]
    username = f"user_{uid}"
    email = f"{username}@example.com"

    reg_response = await client.post(
        "/api/v1/auth/register",
        json={
            "username": username,
            "email": email,
            "password": "securepass123",
            "display_name": "Uploader User",
        },
    )
    assert reg_response.status_code == 201
    return reg_response.json()["access_token"]


@pytest.mark.asyncio
async def test_upload_image_unauthorized(client):
    response = await client.post(
        "/api/v1/upload/image",
        data={"bucket": "stamps"},
        files={"file": ("test.png", b"fake_bytes", "image/png")}
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_upload_image_success(client):
    token = await get_auth_token(client)
    response = await client.post(
        "/api/v1/upload/image",
        data={"bucket": "stamps"},
        files={"file": ("test.png", b"fake_bytes", "image/png")},
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "url" in data["data"]
    assert data["data"]["bucket"] == "stamps"


@pytest.mark.asyncio
async def test_upload_image_invalid_bucket(client):
    token = await get_auth_token(client)
    response = await client.post(
        "/api/v1/upload/image",
        data={"bucket": "invalid_bucket"},
        files={"file": ("test.png", b"fake_bytes", "image/png")},
        headers={"Authorization": f"Bearer {token}"}
    )
    # Validation errors return 422 in FastAPI or 400 depending on implementation
    assert response.status_code in (400, 422)


@pytest.mark.asyncio
async def test_upload_image_invalid_type(client):
    token = await get_auth_token(client)
    response = await client.post(
        "/api/v1/upload/image",
        data={"bucket": "stamps"},
        files={"file": ("test.txt", b"some text", "text/plain")},
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code in (400, 422)


@pytest.mark.asyncio
async def test_upload_image_too_large(client):
    token = await get_auth_token(client)
    # 6MB for avatar which has a 5MB limit
    large_bytes = b"0" * (6 * 1024 * 1024)
    response = await client.post(
        "/api/v1/upload/image",
        data={"bucket": "avatars"},
        files={"file": ("test.png", large_bytes, "image/png")},
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code in (400, 422)


@pytest.mark.asyncio
async def test_upload_multiple_success(client):
    token = await get_auth_token(client)
    files = [
        ("files", ("img1.png", b"img1", "image/png")),
        ("files", ("img2.png", b"img2", "image/png")),
    ]
    response = await client.post(
        "/api/v1/upload/multiple",
        data={"bucket": "stamps"},
        files=files,
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert len(data["data"]["uploaded"]) == 2
    assert len(data["data"]["failed"]) == 0


@pytest.mark.asyncio
async def test_upload_multiple_too_many(client):
    token = await get_auth_token(client)
    # 6 files (limit is 5)
    files = [("files", (f"img{i}.png", b"data", "image/png")) for i in range(6)]
    response = await client.post(
        "/api/v1/upload/multiple",
        data={"bucket": "stamps"},
        files=files,
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code in (400, 422)


@pytest.mark.asyncio
async def test_delete_file_success(client):
    token = await get_auth_token(client)
    
    # 1. Upload first
    upload_res = await client.post(
        "/api/v1/upload/image",
        data={"bucket": "stamps"},
        files={"file": ("test.png", b"fake_bytes", "image/png")},
        headers={"Authorization": f"Bearer {token}"}
    )
    assert upload_res.status_code == 200
    path = upload_res.json()["data"]["path"]

    # 2. Delete it
    delete_res = await client.request(
        "DELETE",
        "/api/v1/upload",
        json={"bucket": "stamps", "path": path},
        headers={"Authorization": f"Bearer {token}"}
    )
    assert delete_res.status_code == 200
    assert delete_res.json()["success"] is True


@pytest.mark.asyncio
async def test_delete_file_unauthorized_owner(client):
    token1 = await get_auth_token(client)
    token2 = await get_auth_token(client)

    # 1. User 1 uploads
    upload_res = await client.post(
        "/api/v1/upload/image",
        data={"bucket": "stamps"},
        files={"file": ("test.png", b"fake_bytes", "image/png")},
        headers={"Authorization": f"Bearer {token1}"}
    )
    assert upload_res.status_code == 200
    path = upload_res.json()["data"]["path"]

    # 2. User 2 tries to delete it (should fail)
    delete_res = await client.request(
        "DELETE",
        "/api/v1/upload",
        json={"bucket": "stamps", "path": path},
        headers={"Authorization": f"Bearer {token2}"}
    )
    assert delete_res.status_code in (400, 403, 422)
