from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Boolean, Index, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base
import enum


class MessageType(str, enum.Enum):
    """Enum for message content types."""
    TEXT = "text"
    IMAGE = "image"
    VIDEO = "video"


class Message(Base):
    """
    Represents a single message in a conversation.
    Supports text, images, and videos with read receipt tracking.
    """
    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, index=True)
    conversation_id = Column(
        Integer, 
        ForeignKey("conversations.id", ondelete="CASCADE"), 
        nullable=False
    )
    sender_id = Column(
        Integer, 
        ForeignKey("users.id", ondelete="SET NULL"), 
        nullable=True  # Allow null if user is deleted
    )
    
    # Message content
    content = Column(Text, nullable=True)  # Text content
    message_type = Column(
        String(20), 
        default=MessageType.TEXT.value,
        nullable=False
    )
    media_url = Column(String(500), nullable=True)  # URL for images/videos
    
    # Timestamps and status
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    read_at = Column(DateTime(timezone=True), nullable=True)  # When recipient read
    is_read = Column(Boolean, default=False)

    # Relationships
    conversation = relationship("Conversation", back_populates="messages")
    sender = relationship("User", backref="sent_messages")

    # Indexes for performance
    __table_args__ = (
        Index('idx_message_conversation_id', 'conversation_id'),
        Index('idx_message_sender_id', 'sender_id'),
        Index('idx_message_created_at', 'created_at'),
    )

    def __repr__(self):
        return f"<Message(id={self.id}, type={self.message_type}, sender={self.sender_id})>"
