from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List
from enum import Enum


class NotificationType(str, Enum):
    """Notification types matching the database enum."""
    FOLLOW = "follow"
    LIKE = "like"
    COMMENT = "comment"
    MENTION = "mention"
    SYSTEM = "system"
    AI = "ai"


# ============== Actor Info Schema ==============

class ActorInfo(BaseModel):
    """Basic info about the user who triggered the notification."""
    id: int
    username: Optional[str]
    full_name: Optional[str]
    profile_picture: Optional[str]

    class Config:
        from_attributes = True


# ============== Notification Schemas ==============

class NotificationBase(BaseModel):
    """Base notification fields."""
    type: NotificationType
    message: str
    title: Optional[str] = None
    related_id: Optional[int] = None
    related_type: Optional[str] = None
    content_image_url: Optional[str] = None


class NotificationCreate(NotificationBase):
    """Schema for creating a notification."""
    user_id: int
    actor_id: Optional[int] = None


class NotificationResponse(BaseModel):
    """Schema for a single notification in API response."""
    id: int
    type: NotificationType
    title: Optional[str]
    message: str
    related_id: Optional[int]
    related_type: Optional[str]
    content_image_url: Optional[str]
    is_read: bool
    created_at: datetime
    read_at: Optional[datetime]
    
    # Actor information (who triggered the notification)
    actor: Optional[ActorInfo]
    
    # Computed fields
    time_ago: str  # Will be computed in the endpoint

    class Config:
        from_attributes = True


class NotificationsListResponse(BaseModel):
    """Response schema for paginated notifications list."""
    notifications: List[NotificationResponse]
    total: int
    unread_count: int
    has_more: bool


class UnreadCountResponse(BaseModel):
    """Response schema for unread notification count."""
    count: int


class MarkReadRequest(BaseModel):
    """Request schema for marking notifications as read."""
    notification_ids: Optional[List[int]] = None  # None means mark all as read
