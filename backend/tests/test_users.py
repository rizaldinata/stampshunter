import pytest
import asyncio
import uuid
from httpx import AsyncClient, ASGITransport
from app.main import app


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


@pytest.mark.asyncio
async def test_get_me_unauthorized(client):
    response = await client.get("/api/v1/users/me")
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_get_me_authorized(client):
    uid = uuid.uuid4().hex[:8]
    username = f"user_{uid}"
    email = f"{username}@example.com"

    reg_response = await client.post(
        "/api/v1/auth/register",
        json={
            "username": username,
            "email": email,
            "password": "securepass123",
            "display_name": "Profile User",
        },
    )
    assert reg_response.status_code == 201
    reg_data = reg_response.json()
    token = reg_data["access_token"]
    user_id = reg_data["user"]["id"]

    response = await client.get(
        "/api/v1/users/me", headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["id"] == user_id
    assert data["data"]["username"] == username
    assert data["data"]["email"] == email
    assert "stamps_count" in data["data"]
    assert "followers_count" in data["data"]
    assert "following_count" in data["data"]


@pytest.mark.asyncio
async def test_get_other_user_profile(client):
    uid = uuid.uuid4().hex[:8]
    username = f"user_{uid}"
    email = f"{username}@example.com"

    reg_response = await client.post(
        "/api/v1/auth/register",
        json={
            "username": username,
            "email": email,
            "password": "securepass123",
            "display_name": "Other User",
        },
    )
    assert reg_response.status_code == 201
    user_id = reg_response.json()["user"]["id"]

    response = await client.get(f"/api/v1/users/{user_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["id"] == user_id
    assert data["data"]["username"] == username
    assert "email" not in data["data"]
    assert "stamps_count" in data["data"]


@pytest.mark.asyncio
async def test_update_profile(client):
    uid = uuid.uuid4().hex[:8]
    username = f"user_{uid}"
    email = f"{username}@example.com"

    reg_response = await client.post(
        "/api/v1/auth/register",
        json={
            "username": username,
            "email": email,
            "password": "securepass123",
            "display_name": "Old Name",
        },
    )
    assert reg_response.status_code == 201
    token = reg_response.json()["access_token"]

    response = await client.put(
        "/api/v1/users/me",
        data={"display_name": "New Name", "bio": "Hello stamp world"},
        files={"avatar": ("test_avatar.png", b"fake_image_bytes", "image/png")},
        headers={"Authorization": f"Bearer {token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert data["data"]["display_name"] == "New Name"
    assert data["data"]["bio"] == "Hello stamp world"
    assert data["data"]["avatar_url"].startswith("/static/avatars/")


@pytest.mark.asyncio
async def test_get_user_stamps_empty(client):
    uid = uuid.uuid4().hex[:8]
    username = f"user_{uid}"
    email = f"{username}@example.com"

    reg_response = await client.post(
        "/api/v1/auth/register",
        json={
            "username": username,
            "email": email,
            "password": "securepass123",
        },
    )
    assert reg_response.status_code == 201
    user_id = reg_response.json()["user"]["id"]

    response = await client.get(f"/api/v1/users/{user_id}/stamps")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert len(data["data"]) == 0
    assert data["meta"]["total"] == 0
