"""
Pydantic schemas for Like operations.
"""
from typing import Optional
from datetime import datetime
from pydantic import BaseModel


class LikeBase(BaseModel):
    """Base schema for likes."""
    pass


class LikeCreate(LikeBase):
    """Schema for creating a like (no additional fields needed - post_id comes from URL)."""
    pass


class LikeResponse(BaseModel):
    """Response schema for a like."""
    id: int
    user_id: int
    post_id: int
    created_at: datetime

    class Config:
        from_attributes = True


class LikeUserInfo(BaseModel):
    """User info included in like list responses."""
    id: int
    username: str
    full_name: Optional[str] = None
    profile_picture: Optional[str] = None


class LikeWithUser(BaseModel):
    """Like with user information."""
    id: int
    user: LikeUserInfo
    created_at: datetime


class LikeListResponse(BaseModel):
    """Response for listing users who liked a post."""
    items: list[LikeWithUser]
    total: int


class LikeToggleResponse(BaseModel):
    """Response for like toggle action."""
    is_liked: bool
    likes_count: int
    message: str
