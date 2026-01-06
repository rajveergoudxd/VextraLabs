"""
Refresh token model for persistent token storage.
Enables secure token refresh without requiring user re-authentication.
"""
from sqlalchemy import Column, Integer, String, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from app.db.base import Base


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    token_hash = Column(String, unique=True, index=True, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    revoked = Column(Boolean, default=False)
    
    # Device/client info for multi-device support (optional for future use)
    device_info = Column(String, nullable=True)
    
    # Relationship
    user = relationship("User", backref="refresh_tokens")
    
    def is_valid(self) -> bool:
        """Check if the token is still valid (not expired and not revoked)."""
        if self.revoked:
            return False
        return datetime.now(timezone.utc) < self.expires_at.replace(tzinfo=timezone.utc)
