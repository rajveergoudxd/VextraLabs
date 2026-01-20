from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, UniqueConstraint, Index
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base


class MessageReaction(Base):
    """
    Represents an emoji reaction on a message.
    Users can add one reaction per emoji type per message.
    """
    __tablename__ = "message_reactions"

    id = Column(Integer, primary_key=True, index=True)
    message_id = Column(
        Integer, 
        ForeignKey("messages.id", ondelete="CASCADE"), 
        nullable=False
    )
    user_id = Column(
        Integer, 
        ForeignKey("users.id", ondelete="CASCADE"), 
        nullable=False
    )
    emoji = Column(String(10), nullable=False)  # ❤️, 👍, 😂, 😮, 😢, 🙏
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    message = relationship("Message", back_populates="reactions")
    user = relationship("User", backref="message_reactions")

    # Constraints
    __table_args__ = (
        # One reaction per emoji type per user per message
        UniqueConstraint('message_id', 'user_id', 'emoji', name='uq_message_user_emoji'),
        Index('idx_reaction_message_id', 'message_id'),
        Index('idx_reaction_user_id', 'user_id'),
    )

    def __repr__(self):
        return f"<MessageReaction(id={self.id}, emoji={self.emoji}, user={self.user_id})>"
