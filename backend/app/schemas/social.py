from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List


# ============== Follow Schemas ==============

class FollowCreate(BaseModel):
    """Schema for creating a follow relationship."""
    following_id: int


class FollowStatus(BaseModel):
    """Schema for follow status between two users."""
    is_following: bool
    is_followed_by: bool  # Whether target follows the current user


class FollowerInfo(BaseModel):
    """Schema for follower information in lists."""
    id: int
    username: Optional[str]
    full_name: Optional[str]
    profile_picture: Optional[str]
    is_following: bool  # Whether current user follows this person back

    class Config:
        from_attributes = True


class FollowingInfo(BaseModel):
    """Schema for following information in lists."""
    id: int
    username: Optional[str]
    full_name: Optional[str]
    profile_picture: Optional[str]
    is_followed_by: bool  # Whether this person follows current user back

    class Config:
        from_attributes = True


class FollowersResponse(BaseModel):
    """Response schema for followers list."""
    followers: List[FollowerInfo]
    total: int


class FollowingResponse(BaseModel):
    """Response schema for following list."""
    following: List[FollowingInfo]
    total: int


# ============== User Search Schemas ==============

class UserSearchResult(BaseModel):
    """Schema for user search results."""
    id: int
    username: Optional[str]
    full_name: Optional[str]
    bio: Optional[str]
    profile_picture: Optional[str]
    followers_count: int
    is_following: bool  # Whether current user follows this person

    class Config:
        from_attributes = True


class UserSearchResponse(BaseModel):
    """Response schema for user search."""
    results: List[UserSearchResult]
    total: int
    query: str


# ============== Public Profile Schema ==============

class PublicProfile(BaseModel):
    """Schema for viewing another user's public profile."""
    id: int
    username: Optional[str]
    full_name: Optional[str]
    bio: Optional[str]
    profile_picture: Optional[str]
    posts_count: int
    followers_count: int
    following_count: int
    is_following: bool  # Whether current user follows this person
    is_followed_by: bool  # Whether this person follows current user

    class Config:
        from_attributes = True
