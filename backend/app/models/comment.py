"""
Comment model for tracking comments on posts.
"""
from sqlalchemy import Column, Integer, Text, ForeignKey, DateTime, Index
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base


class Comment(Base):
    """
    Represents a comment on a post by a user.
    """
    __tablename__ = "comments"

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
    content = Column(Text, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    user = relationship("User", backref="comments")
    post = relationship("Post", back_populates="comments")

    # Indexes for performance
    __table_args__ = (
        Index('idx_comment_post_id', 'post_id'),
        Index('idx_comment_user_id', 'user_id'),
        Index('idx_comment_created_at', 'created_at'),
    )

    def __repr__(self):
        return f"<Comment(id={self.id}, user_id={self.user_id}, post_id={self.post_id})>"
