from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime, JSON, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base

class Post(Base):
    __tablename__ = "posts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    
    content = Column(Text, nullable=True)
    media_urls = Column(JSON, nullable=True)  # List of strings [url1, url2]
    platforms = Column(JSON, nullable=True)   # List of strings ["instagram", "inspire"]
    
    # Draft support
    is_draft = Column(Boolean, default=False, index=True)
    title = Column(String, nullable=True)  # Optional title for drafts
    
    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    published_at = Column(DateTime(timezone=True), nullable=True)
    
    # Stats
    likes_count = Column(Integer, default=0)
    comments_count = Column(Integer, default=0)
    
    # Sharing
    share_token = Column(String(32), unique=True, index=True, nullable=True)
    
    # Relationships
    owner = relationship("User", back_populates="posts")
    saved_by = relationship("SavedPost", back_populates="post", cascade="all, delete-orphan")

