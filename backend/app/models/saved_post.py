from sqlalchemy import Column, Integer, ForeignKey, DateTime, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base


class SavedPost(Base):
    __tablename__ = "saved_posts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    post_id = Column(Integer, ForeignKey("posts.id", ondelete="CASCADE"), nullable=False)
    saved_at = Column(DateTime(timezone=True), server_default=func.now())

    # Unique constraint to prevent duplicate saves
    __table_args__ = (
        UniqueConstraint('user_id', 'post_id', name='uq_user_post_saved'),
    )

    # Relationships
    user = relationship("User", back_populates="saved_posts")
    post = relationship("Post", back_populates="saved_by")
