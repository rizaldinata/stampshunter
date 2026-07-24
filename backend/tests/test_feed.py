import pytest
import asyncio
import uuid
import json
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.database import AsyncSessionLocal
from app.models.follow import Follow
from PIL import Image
import io

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

def create_test_image(size=(100, 100)) -> bytes:
    img = Image.new("RGB", size, "blue")
    out = io.BytesIO()
    img.save(out, format="JPEG")
    return out.getvalue()

async def register_user(client, display_name="Test User"):
    uid = uuid.uuid4().hex[:8]
    username = f"user_{uid}"
    email = f"{username}@example.com"
    reg_response = await client.post(
        "/api/v1/auth/register",
        json={
            "username": username,
            "email": email,
            "password": "securepass123",
            "display_name": display_name,
        },
    )
    assert reg_response.status_code == 201
    res_data = reg_response.json()
    return res_data["access_token"], res_data["user"]["id"], username

async def create_stamp(client, token, title="Test Stamp", is_public=True):
    img_bytes = create_test_image()
    style = {
        "version": "1.0",
        "border": {"enabled": True, "config": {"tooth_size": 10}},
        "filter": {"enabled": False}
    }
    response = await client.post(
        "/api/v1/stamps",
        data={
            "title": title,
            "description": "Retro vibes",
            "tags": json.dumps(["retro", "test"]),
            "is_public": "true" if is_public else "false",
            "stamp_style": json.dumps(style),
        },
        files={"file": ("test.jpg", img_bytes, "image/jpeg")},
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 201
    return response.json()["data"]["id"]

@pytest.mark.asyncio
async def test_get_public_feed(client):
    # Register two users and create stamps
    token1, user1_id, uname1 = await register_user(client, "User One")
    token2, user2_id, uname2 = await register_user(client, "User Two")

    stamp1_id = await create_stamp(client, token1, "Public Stamp 1", is_public=True)
    stamp2_id = await create_stamp(client, token2, "Public Stamp 2", is_public=True)
    stamp3_private_id = await create_stamp(client, token1, "Private Stamp", is_public=False)

    # 1. Get public feed without auth
    response = await client.get("/api/v1/feed/public")
    assert response.status_code == 200
    res_data = response.json()
    assert res_data["success"] is True
    stamps = res_data["data"]
    # Check that public stamps are present and private is not
    stamp_ids = [s["id"] for s in stamps]
    assert stamp1_id in stamp_ids
    assert stamp2_id in stamp_ids
    assert stamp3_private_id not in stamp_ids

    # 2. Get public feed with recent sort
    response_recent = await client.get("/api/v1/feed/public?sort=recent")
    assert response_recent.status_code == 200
    recent_stamps = response_recent.json()["data"]
    assert len(recent_stamps) >= 2

@pytest.mark.asyncio
async def test_following_feed(client):
    token1, user1_id, uname1 = await register_user(client, "Follower")
    token2, user2_id, uname2 = await register_user(client, "Following User")
    token3, user3_id, uname3 = await register_user(client, "Not Followed")

    # Create stamps
    stamp_followed_id = await create_stamp(client, token2, "Followed Stamp", is_public=True)
    stamp_not_followed_id = await create_stamp(client, token3, "Stranger Stamp", is_public=True)

    # unauthenticated should fail
    unauth_response = await client.get("/api/v1/feed/following")
    assert unauth_response.status_code == 401

    # Before follow: following feed should be empty
    response_before = await client.get(
        "/api/v1/feed/following",
        headers={"Authorization": f"Bearer {token1}"}
    )
    assert response_before.status_code == 200
    assert len(response_before.json()["data"]) == 0

    # Create follow relationship directly in DB
    async with AsyncSessionLocal() as session:
        follow = Follow(follower_id=user1_id, following_id=user2_id)
        session.add(follow)
        await session.commit()

    # After follow: following feed should contain followed stamp, but not strangers
    response_after = await client.get(
        "/api/v1/feed/following",
        headers={"Authorization": f"Bearer {token1}"}
    )
    assert response_after.status_code == 200
    following_stamps = response_after.json()["data"]
    following_ids = [s["id"] for s in following_stamps]
    assert stamp_followed_id in following_ids
    assert stamp_not_followed_id not in following_ids

@pytest.mark.asyncio
async def test_toggle_like(client):
    token1, user1_id, uname1 = await register_user(client, "Liker")
    token2, user2_id, uname2 = await register_user(client, "Creator")

    stamp_id = await create_stamp(client, token2, "Like Target", is_public=True)

    # 1. Unauthenticated like should fail
    unauth_response = await client.post(f"/api/v1/stamps/{stamp_id}/like")
    assert unauth_response.status_code == 401

    # 2. Like target stamp
    like_response = await client.post(
        f"/api/v1/stamps/{stamp_id}/like",
        headers={"Authorization": f"Bearer {token1}"}
    )
    assert like_response.status_code == 200
    assert like_response.json()["data"]["is_liked"] is True
    assert like_response.json()["data"]["likes_count"] == 1

    # 3. Get public feed and check is_liked status
    feed_response = await client.get(
        "/api/v1/feed/public",
        headers={"Authorization": f"Bearer {token1}"}
    )
    assert feed_response.status_code == 200
    stamps = feed_response.json()["data"]
    matched_stamps = [s for s in stamps if s["id"] == stamp_id]
    assert len(matched_stamps) == 1
    assert matched_stamps[0]["is_liked"] is True

    # 4. Unlike target stamp
    unlike_response = await client.post(
        f"/api/v1/stamps/{stamp_id}/like",
        headers={"Authorization": f"Bearer {token1}"}
    )
    assert unlike_response.status_code == 200
    assert unlike_response.json()["data"]["is_liked"] is False
    assert unlike_response.json()["data"]["likes_count"] == 0

@pytest.mark.asyncio
async def test_comments_crud(client):
    token1, user1_id, uname1 = await register_user(client, "Commenter")
    token2, user2_id, uname2 = await register_user(client, "Creator")

    stamp_id = await create_stamp(client, token2, "Comment Target", is_public=True)

    # 1. Get empty comments
    get_empty = await client.get(f"/api/v1/stamps/{stamp_id}/comments")
    assert get_empty.status_code == 200
    assert len(get_empty.json()["data"]) == 0

    # 2. Add comment unauthenticated
    unauth_response = await client.post(
        f"/api/v1/stamps/{stamp_id}/comments",
        json={"content": "Nice stamp!"}
    )
    assert unauth_response.status_code == 401

    # 3. Add comment authenticated
    comment1_response = await client.post(
        f"/api/v1/stamps/{stamp_id}/comments",
        json={"content": "Super awesome vintage style!"},
        headers={"Authorization": f"Bearer {token1}"}
    )
    assert comment1_response.status_code == 200
    c1_data = comment1_response.json()["data"]
    assert c1_data["content"] == "Super awesome vintage style!"
    assert c1_data["parent_id"] is None
    c1_id = c1_data["id"]

    # 4. Add nested reply comment
    reply_response = await client.post(
        f"/api/v1/stamps/{stamp_id}/comments",
        json={"content": "I agree with that!", "parent_id": c1_id},
        headers={"Authorization": f"Bearer {token2}"}
    )
    assert reply_response.status_code == 200
    reply_data = reply_response.json()["data"]
    assert reply_data["content"] == "I agree with that!"
    assert reply_data["parent_id"] == c1_id

    # 5. Fetch comments and verify order and reply structure
    get_comments = await client.get(f"/api/v1/stamps/{stamp_id}/comments")
    assert get_comments.status_code == 200
    comments_list = get_comments.json()["data"]
    assert len(comments_list) == 2
    # Ordered oldest first chronologically
    assert comments_list[0]["id"] == c1_id
    assert comments_list[1]["parent_id"] == c1_id

    # 6. Add comment validation error (empty string)
    invalid_comment = await client.post(
        f"/api/v1/stamps/{stamp_id}/comments",
        json={"content": "   "},
        headers={"Authorization": f"Bearer {token1}"}
    )
    assert invalid_comment.status_code in (400, 422)
