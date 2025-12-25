from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List


class SocialConnectionBase(BaseModel):
    """Base schema for social connection"""
    platform: str
    platform_username: Optional[str] = None
    platform_display_name: Optional[str] = None
    platform_profile_picture: Optional[str] = None


class SocialConnectionCreate(SocialConnectionBase):
    """Schema for creating a social connection"""
    platform_user_id: str
    access_token: str
    refresh_token: Optional[str] = None
    token_expires_at: Optional[datetime] = None
    scopes: Optional[str] = None


class SocialConnectionResponse(SocialConnectionBase):
    """Schema for returning social connection info (no tokens)"""
    id: int
    platform_user_id: str
    is_token_valid: bool
    token_expires_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class SocialConnectionList(BaseModel):
    """List of social connections"""
    connections: List[SocialConnectionResponse]


class OAuthAuthorizeResponse(BaseModel):
    """Response containing OAuth authorization URL"""
    authorization_url: str
    state: str


class OAuthCallbackRequest(BaseModel):
    """Request for OAuth callback"""
    code: Optional[str] = None
    state: Optional[str] = None
    oauth_token: Optional[str] = None
    oauth_verifier: Optional[str] = None


class PublishRequest(BaseModel):
    """Request for publishing content to social platforms"""
    platforms: List[str]  # List of platform names
    content: str
    media_urls: Optional[List[str]] = None
    scheduled_at: Optional[datetime] = None


class PublishResponse(BaseModel):
    """Response from publish request"""
    success: bool
    results: dict  # platform -> result
