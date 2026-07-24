import json
import uuid
import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
from PIL import Image
import io


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac


def create_test_image(size=(100, 100)) -> bytes:
    img = Image.new("RGB", size, "blue")
    out = io.BytesIO()
    img.save(out, format="JPEG")
    return out.getvalue()


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
            "display_name": "Stamp Tester",
        },
    )
    assert reg_response.status_code == 201
    return reg_response.json()["access_token"]


@pytest.mark.asyncio
async def test_create_stamp_unauthorized(client):
    img_bytes = create_test_image()
    style_str = json.dumps({
        "border": {"enabled": True, "config": {"tooth_size": 10}},
        "filter": {"enabled": False}
    })
    
    response = await client.post(
        "/api/v1/stamps",
        data={
            "title": "Unauth Stamp",
            "stamp_style": style_str,
        },
        files={"file": ("sunset.jpg", img_bytes, "image/jpeg")}
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_create_stamp_success(client):
    token = await get_auth_token(client)
    img_bytes = create_test_image()
    
    style = {
        "version": "1.0",
        "border": {
            "enabled": True,
            "config": {
                "tooth_size": 10,
                "tooth_spacing": 5,
                "border_width": 20,
                "border_color": "#FFFFFF"
            }
        },
        "filter": {
            "enabled": True,
            "config": {
                "intensity": 0.5,
                "warmth": 0.4
            }
        }
    }
    
    response = await client.post(
        "/api/v1/stamps",
        data={
            "title": "Beautiful Sunset",
            "description": "Retro sunset vibes",
            "tags": json.dumps(["sunset", "vintage"]),
            "is_public": "true",
            "stamp_style": json.dumps(style),
        },
        files={"file": ("sunset.jpg", img_bytes, "image/jpeg")},
        headers={"Authorization": f"Bearer {token}"}
    )
    
    assert response.status_code == 201
    data = response.json()
    assert data["success"] is True
    assert "data" in data
    stamp = data["data"]
    assert stamp["title"] == "Beautiful Sunset"
    assert stamp["description"] == "Retro sunset vibes"
    assert "sunset" in stamp["tags"]
    assert stamp["stamp_style"]["border"]["config"]["tooth_size"] == 10
    assert "stamp_image_url" in stamp
    assert "original_image_url" in stamp
    assert "thumbnail_url" in stamp


@pytest.mark.asyncio
async def test_get_and_list_stamps(client):
    token = await get_auth_token(client)
    img_bytes = create_test_image()
    style_str = json.dumps({"border": {"enabled": False}})
    
    # 1. Create a stamp
    create_res = await client.post(
        "/api/v1/stamps",
        data={
            "title": "Listable Stamp",
            "stamp_style": style_str,
        },
        files={"file": ("sunset.jpg", img_bytes, "image/jpeg")},
        headers={"Authorization": f"Bearer {token}"}
    )
    assert create_res.status_code == 201
    stamp_id = create_res.json()["data"]["id"]
    
    # 2. Get stamp details
    get_res = await client.get(f"/api/v1/stamps/{stamp_id}")
    assert get_res.status_code == 200
    assert get_res.json()["title"] == "Listable Stamp"
    
    # 3. List stamps
    list_res = await client.get("/api/v1/stamps/")
    assert list_res.status_code == 200
    list_data = list_res.json()
    assert list_data["success"] is True
    # Verify the list contains at least our newly created stamp
    titles = [s["title"] for s in list_data["data"]]
    assert "Listable Stamp" in titles


@pytest.mark.asyncio
async def test_delete_stamp_flow(client):
    token1 = await get_auth_token(client)
    token2 = await get_auth_token(client)
    img_bytes = create_test_image()
    style_str = json.dumps({"border": {"enabled": False}})
    
    # 1. Create stamp with user 1
    create_res = await client.post(
        "/api/v1/stamps",
        data={
            "title": "Deletable Stamp",
            "stamp_style": style_str,
        },
        files={"file": ("sunset.jpg", img_bytes, "image/jpeg")},
        headers={"Authorization": f"Bearer {token1}"}
    )
    assert create_res.status_code == 201
    stamp_id = create_res.json()["data"]["id"]
    
    # 2. Delete with user 2 (should fail)
    delete_unauth = await client.delete(
        f"/api/v1/stamps/{stamp_id}",
        headers={"Authorization": f"Bearer {token2}"}
    )
    # Since it checks user_id inside delete_stamp and raises UnauthorizedError
    assert delete_unauth.status_code in (400, 401, 403, 422)
    
    # 3. Delete with user 1 (should succeed)
    delete_auth = await client.delete(
        f"/api/v1/stamps/{stamp_id}",
        headers={"Authorization": f"Bearer {token1}"}
    )
    assert delete_auth.status_code == 200
    assert delete_auth.json()["success"] is True
    
    # 4. Get again (should be 404)
    get_res = await client.get(f"/api/v1/stamps/{stamp_id}")
    assert get_res.status_code == 404
