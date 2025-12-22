from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.base import Base


class SocialConnection(Base):
    """
    Stores OAuth connections to social platforms.
    Tokens are stored encrypted.
    """
    __tablename__ = "social_connections"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    
    # Platform identification
    platform = Column(String(50), nullable=False, index=True)  # instagram, twitter, linkedin, facebook
    platform_user_id = Column(String(255), nullable=False)
    platform_username = Column(String(255), nullable=True)
    platform_display_name = Column(String(255), nullable=True)
    platform_profile_picture = Column(Text, nullable=True)
    
    # OAuth tokens (stored encrypted)
    access_token = Column(Text, nullable=False)
    refresh_token = Column(Text, nullable=True)
    token_expires_at = Column(DateTime, nullable=True)
    
    # Granted permissions
    scopes = Column(Text, nullable=True)  # Comma-separated scopes
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationship to user
    user = relationship("User", backref="social_connections")

    class Config:
        orm_mode = True
