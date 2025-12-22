from sqlalchemy import Column, Integer, DateTime, ForeignKey, UniqueConstraint, Index
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base


class Conversation(Base):
    """
    Represents a chat conversation between users.
    Currently supports 1:1 conversations only.
    """
    __tablename__ = "conversations"

    id = Column(Integer, primary_key=True, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True), 
        server_default=func.now(), 
        onupdate=func.now()
    )
    last_message_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    participants = relationship(
        "ConversationParticipant", 
        back_populates="conversation",
        cascade="all, delete-orphan"
    )
    messages = relationship(
        "Message", 
        back_populates="conversation",
        cascade="all, delete-orphan",
        order_by="Message.created_at"
    )

    def __repr__(self):
        return f"<Conversation(id={self.id})>"


class ConversationParticipant(Base):
    """
    Junction table for conversation participants.
    Tracks when users joined and when they last read messages.
    """
    __tablename__ = "conversation_participants"

    id = Column(Integer, primary_key=True, index=True)
    conversation_id = Column(
        Integer, 
        ForeignKey("conversations.id", ondelete="CASCADE"), 
        nullable=False
    )
    user_id = Column(
        Integer, 
        ForeignKey("users.id", ondelete="CASCADE"), 
        nullable=False
    )
    joined_at = Column(DateTime(timezone=True), server_default=func.now())
    last_read_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    conversation = relationship("Conversation", back_populates="participants")
    user = relationship("User", backref="conversation_participations")

    # Constraints
    __table_args__ = (
        UniqueConstraint('conversation_id', 'user_id', name='unique_participant'),
        Index('idx_conversation_id', 'conversation_id'),
        Index('idx_participant_user_id', 'user_id'),
    )

    def __repr__(self):
        return f"<ConversationParticipant(conversation_id={self.conversation_id}, user_id={self.user_id})>"
