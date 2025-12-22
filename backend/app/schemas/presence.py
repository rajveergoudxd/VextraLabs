"""
Schemas for online presence/status tracking.
"""
from pydantic import BaseModel
from typing import Optional, List


class OnlineUser(BaseModel):
    """Schema for an online user in the following list."""
    id: int
    username: Optional[str]
    full_name: Optional[str]
    profile_picture: Optional[str]

    class Config:
        from_attributes = True


class OnlineFollowingResponse(BaseModel):
    """Response schema for online following users endpoint."""
    online_users: List[OnlineUser]
    total: int


class PresenceEvent(BaseModel):
    """Schema for presence change events (WebSocket)."""
    user_id: int
    is_online: bool
    username: Optional[str] = None
    full_name: Optional[str] = None
    profile_picture: Optional[str] = None
