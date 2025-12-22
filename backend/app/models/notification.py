from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Enum, Index
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
from app.db.base import Base


class NotificationType(str, enum.Enum):
    """Enum for notification types."""
    FOLLOW = "follow"
    LIKE = "like"
    COMMENT = "comment"
    MENTION = "mention"
    SYSTEM = "system"
    AI = "ai"


class Notification(Base):
    """
    Represents a user notification.
    Supports various notification types including social interactions,
    system messages, and AI-generated content notifications.
    """
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    
    # User receiving the notification
    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    
    # User who triggered the notification (nullable for system/AI notifications)
    actor_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=True
    )
    
    # Notification type
    type = Column(
        Enum(NotificationType),
        nullable=False,
        default=NotificationType.SYSTEM
    )
    
    # Notification content
    title = Column(String(255), nullable=True)
    message = Column(String(500), nullable=False)
    
    # Related entity (e.g., post ID, comment ID)
    related_id = Column(Integer, nullable=True)
    related_type = Column(String(50), nullable=True)  # "post", "comment", etc.
    
    # Content image URL (e.g., post thumbnail)
    content_image_url = Column(String(500), nullable=True)
    
    # Read status
    is_read = Column(Boolean, default=False, nullable=False)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    read_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    user = relationship(
        "User",
        foreign_keys=[user_id],
        backref="notifications"
    )
    actor = relationship(
        "User",
        foreign_keys=[actor_id],
        backref="triggered_notifications"
    )

    # Indexes for common queries
    __table_args__ = (
        Index('idx_notification_user_created', 'user_id', 'created_at'),
        Index('idx_notification_user_unread', 'user_id', 'is_read'),
    )

    def __repr__(self):
        return f"<Notification(id={self.id}, type={self.type}, user_id={self.user_id})>"
