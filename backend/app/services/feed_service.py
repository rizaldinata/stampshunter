from typing import Optional, List, Dict, Tuple
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, desc
from app.models.stamp import Stamp
from app.models.user import User
from app.models.follow import Follow
from app.models.like import Like
from app.models.comment import Comment
from app.core.exceptions import NotFoundError, ValidationError


class FeedService:
    @staticmethod
    async def get_public_feed(
        db: AsyncSession,
        current_user_id: Optional[str],
        page: int = 1,
        limit: int = 20,
        sort: str = "trending"
    ) -> Tuple[List[Dict], int]:
        """Fetch public stamps with user profiles and like status."""
        offset = (page - 1) * limit

        # Base query to select stamp and author
        query = select(Stamp, User).join(User, Stamp.user_id == User.id)
        query = query.where(Stamp.is_public == True)

        # Count query
        count_query = select(func.count(Stamp.id)).where(Stamp.is_public == True)
        total_result = await db.execute(count_query)
        total = total_result.scalar() or 0

        # Sort ordering
        if sort == "trending":
            query = query.order_by(desc(Stamp.likes_count), desc(Stamp.created_at))
        else:
            query = query.order_by(desc(Stamp.created_at))

        query = query.offset(offset).limit(limit)
        results = (await db.execute(query)).all()

        # Determine liked stamps if user is authenticated
        liked_stamp_ids = set()
        if current_user_id and results:
            stamp_ids = [s.id for s, _ in results]
            like_query = select(Like.stamp_id).where(
                Like.user_id == current_user_id,
                Like.stamp_id.in_(stamp_ids)
            )
            like_results = await db.execute(like_query)
            liked_stamp_ids = set(like_results.scalars().all())

        # Construct payload
        data = []
        for stamp, user in results:
            data.append({
                "id": stamp.id,
                "user": {
                    "id": user.id,
                    "username": user.username,
                    "display_name": user.display_name or user.username,
                    "avatar_url": user.avatar_url
                },
                "thumbnail_url": stamp.thumbnail_url,
                "stamp_image_url": stamp.stamp_image_url,
                "title": stamp.title,
                "likes_count": stamp.likes_count,
                "comments_count": stamp.comments_count,
                "is_liked": stamp.id in liked_stamp_ids,
                "created_at": stamp.created_at.isoformat() + "Z"
            })

        return data, total

    @staticmethod
    async def get_following_feed(
        db: AsyncSession,
        user_id: str,
        page: int = 1,
        limit: int = 20
    ) -> Tuple[List[Dict], int]:
        """Fetch stamps from followed users."""
        offset = (page - 1) * limit

        # Select followed user IDs
        following_subquery = select(Follow.following_id).where(Follow.follower_id == user_id)

        # Base query to select stamp and author
        query = select(Stamp, User).join(User, Stamp.user_id == User.id)
        query = query.where(Stamp.user_id.in_(following_subquery), Stamp.is_public == True)

        # Count query
        count_query = select(func.count(Stamp.id)).where(
            Stamp.user_id.in_(following_subquery), Stamp.is_public == True
        )
        total_result = await db.execute(count_query)
        total = total_result.scalar() or 0

        query = query.order_by(desc(Stamp.created_at)).offset(offset).limit(limit)
        results = (await db.execute(query)).all()

        # Determine liked stamps
        liked_stamp_ids = set()
        if results:
            stamp_ids = [s.id for s, _ in results]
            like_query = select(Like.stamp_id).where(
                Like.user_id == user_id,
                Like.stamp_id.in_(stamp_ids)
            )
            like_results = await db.execute(like_query)
            liked_stamp_ids = set(like_results.scalars().all())

        # Construct payload
        data = []
        for stamp, user in results:
            data.append({
                "id": stamp.id,
                "user": {
                    "id": user.id,
                    "username": user.username,
                    "display_name": user.display_name or user.username,
                    "avatar_url": user.avatar_url
                },
                "thumbnail_url": stamp.thumbnail_url,
                "stamp_image_url": stamp.stamp_image_url,
                "title": stamp.title,
                "likes_count": stamp.likes_count,
                "comments_count": stamp.comments_count,
                "is_liked": stamp.id in liked_stamp_ids,
                "created_at": stamp.created_at.isoformat() + "Z"
            })

        return data, total

    @staticmethod
    async def toggle_like(db: AsyncSession, user_id: str, stamp_id: str) -> Dict:
        """Toggle like state for a stamp."""
        stamp_result = await db.execute(select(Stamp).where(Stamp.id == stamp_id))
        stamp = stamp_result.scalar_one_or_none()
        if not stamp:
            raise NotFoundError("Stamp", stamp_id)

        like_result = await db.execute(
            select(Like).where(Like.user_id == user_id, Like.stamp_id == stamp_id)
        )
        like = like_result.scalar_one_or_none()

        if like:
            await db.delete(like)
            stamp.likes_count = max(0, stamp.likes_count - 1)
            is_liked = False
        else:
            new_like = Like(user_id=user_id, stamp_id=stamp_id)
            db.add(new_like)
            stamp.likes_count += 1
            is_liked = True

        await db.commit()
        return {"is_liked": is_liked, "likes_count": stamp.likes_count}

    @staticmethod
    async def get_comments(db: AsyncSession, stamp_id: str, page: int = 1, limit: int = 20) -> Tuple[List[Dict], int]:
        """Fetch comments for a stamp."""
        offset = (page - 1) * limit

        query = select(Comment, User).join(User, Comment.user_id == User.id)
        query = query.where(Comment.stamp_id == stamp_id)

        # Count query
        count_query = select(func.count(Comment.id)).where(Comment.stamp_id == stamp_id)
        total_result = await db.execute(count_query)
        total = total_result.scalar() or 0

        # Ordered chronologically (oldest comment first)
        query = query.order_by(Comment.created_at.asc()).offset(offset).limit(limit)
        results = (await db.execute(query)).all()

        data = []
        for comment, user in results:
            data.append({
                "id": comment.id,
                "user": {
                    "id": user.id,
                    "username": user.username,
                    "avatar_url": user.avatar_url
                },
                "content": comment.content,
                "parent_id": comment.parent_id,
                "created_at": comment.created_at.isoformat() + "Z"
            })

        return data, total

    @staticmethod
    async def add_comment(
        db: AsyncSession,
        user_id: str,
        stamp_id: str,
        content: str,
        parent_id: Optional[str] = None
    ) -> Dict:
        """Add comment to a stamp."""
        stamp_result = await db.execute(select(Stamp).where(Stamp.id == stamp_id))
        stamp = stamp_result.scalar_one_or_none()
        if not stamp:
            raise NotFoundError("Stamp", stamp_id)

        clean_content = content.strip()
        if not clean_content:
            raise ValidationError([{"loc": ["content"], "msg": "Komentar tidak boleh kosong."}])

        if parent_id:
            parent_result = await db.execute(select(Comment).where(Comment.id == parent_id))
            if not parent_result.scalar_one_or_none():
                raise NotFoundError("Comment", parent_id)

        new_comment = Comment(
            user_id=user_id,
            stamp_id=stamp_id,
            content=clean_content,
            parent_id=parent_id
        )
        db.add(new_comment)
        stamp.comments_count += 1
        await db.commit()

        # Fetch user
        user_result = await db.execute(select(User).where(User.id == user_id))
        user = user_result.scalar_one()

        return {
            "id": new_comment.id,
            "user": {
                "id": user.id,
                "username": user.username,
                "avatar_url": user.avatar_url
            },
            "content": new_comment.content,
            "parent_id": new_comment.parent_id,
            "created_at": new_comment.created_at.isoformat() + "Z"
        }
