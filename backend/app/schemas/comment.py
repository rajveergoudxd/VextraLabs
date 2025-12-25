"""
Pydantic schemas for Comment operations.
"""
from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, Field


class CommentBase(BaseModel):
    """Base schema for comments."""
    content: str = Field(..., min_length=1, max_length=2000)


class CommentCreate(CommentBase):
    """Schema for creating a comment."""
    pass


class CommentUpdate(BaseModel):
    """Schema for updating a comment."""
    content: str = Field(..., min_length=1, max_length=2000)


class CommentUserInfo(BaseModel):
    """User info included in comment responses."""
    id: int
    username: str
    full_name: Optional[str] = None
    profile_picture: Optional[str] = None


class CommentResponse(BaseModel):
    """Response schema for a single comment."""
    id: int
    post_id: int
    content: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    user: CommentUserInfo

    class Config:
        from_attributes = True


class CommentListResponse(BaseModel):
    """Response for listing comments on a post."""
    items: List[CommentResponse]
    total: int
    has_more: bool


class CommentDeleteResponse(BaseModel):
    """Response for deleting a comment."""
    message: str
    id: int
