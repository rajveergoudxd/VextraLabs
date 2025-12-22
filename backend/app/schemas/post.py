from typing import Optional, List, Dict, Any
from datetime import datetime
from pydantic import BaseModel

# Shared properties
class PostBase(BaseModel):
    content: Optional[str] = None
    media_urls: Optional[List[str]] = None
    platforms: Optional[List[str]] = None

# Properties to receive on item creation
class PostCreate(PostBase):
    pass

# Properties to receive on item update
class PostUpdate(PostBase):
    pass

# Properties shared by models stored in DB
class PostInDBBase(PostBase):
    id: int
    user_id: int
    created_at: datetime
    published_at: Optional[datetime] = None
    likes_count: int = 0
    comments_count: int = 0

    class Config:
        from_attributes = True

# Additional properties to return via API
class Post(PostInDBBase):
    user: Optional[Dict[str, Any]] = None # Simplified user info

# Additional properties stored in DB
class PostInDB(PostInDBBase):
    pass

class PostFeed(BaseModel):
    items: List[Post]
    total: int
    page: int
    size: int
    has_more: bool
