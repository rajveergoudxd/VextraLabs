from typing import Optional, List, Dict, Any
from datetime import datetime
from pydantic import BaseModel

# Shared properties
class PostBase(BaseModel):
    content: Optional[str] = None
    media_urls: Optional[List[str]] = None
    platforms: Optional[List[str]] = None
    title: Optional[str] = None

# Properties to receive on item creation
class PostCreate(PostBase):
    is_draft: bool = False

# Properties for draft creation
class DraftCreate(PostBase):
    pass  # is_draft will be set to True by the endpoint

# Properties to receive on item update
class PostUpdate(PostBase):
    pass

# Properties for updating a draft
class DraftUpdate(PostBase):
    pass

# Properties shared by models stored in DB
class PostInDBBase(PostBase):
    id: int
    user_id: int
    is_draft: bool = False
    created_at: datetime
    updated_at: Optional[datetime] = None
    published_at: Optional[datetime] = None
    likes_count: Optional[int] = 0
    comments_count: Optional[int] = 0

    class Config:
        from_attributes = True

# Additional properties to return via API
class Post(PostInDBBase):
    user: Optional[Dict[str, Any]] = None  # Simplified user info
    is_liked: bool = False  # Whether current user has liked the post
    is_saved: bool = False  # Whether current user has saved the post
    share_token: Optional[str] = None  # Token for shareable link

# Additional properties stored in DB
class PostInDB(PostInDBBase):
    pass

class PostFeed(BaseModel):
    items: List[Post]
    total: int
    page: int
    size: int
    has_more: bool

# Draft list response
class DraftList(BaseModel):
    items: List[Post]
    total: int

