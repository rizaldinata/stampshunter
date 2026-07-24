from datetime import datetime
from sqlalchemy import String, DateTime, ForeignKey, PrimaryKeyConstraint, CheckConstraint
from sqlalchemy.orm import Mapped, mapped_column
from app.database import Base


class Follow(Base):
    __tablename__ = "follows"

    follower_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    following_id: Mapped[str] = mapped_column(
        String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    __table_args__ = (
        PrimaryKeyConstraint("follower_id", "following_id"),
        CheckConstraint("follower_id <> following_id", name="check_follower_not_self"),
    )
