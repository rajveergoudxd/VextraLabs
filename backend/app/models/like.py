"""
Like model for tracking user likes on posts.
Implements a proper many-to-many relationship between users and posts.
"""
from sqlalchemy import Column, Integer, ForeignKey, DateTime, UniqueConstraint, Index
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base


class Like(Base):
    """
    Represents a like on a post by a user.
    Each user can only like a post once (enforced by unique constraint).
    """
    __tablename__ = "likes"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer, 
        ForeignKey("users.id", ondelete="CASCADE"), 
        nullable=False
    )
    post_id = Column(
        Integer, 
        ForeignKey("posts.id", ondelete="CASCADE"), 
        nullable=False
    )
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user = relationship("User", backref="likes")
    post = relationship("Post", back_populates="likes")

    # Ensure a user can only like a post once
    __table_args__ = (
        UniqueConstraint('user_id', 'post_id', name='uq_user_post_like'),
        Index('idx_like_user_id', 'user_id'),
        Index('idx_like_post_id', 'post_id'),
    )

    def __repr__(self):
        return f"<Like(id={self.id}, user_id={self.user_id}, post_id={self.post_id})>"
