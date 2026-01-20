from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List, ForwardRef
from enum import Enum


class MessageTypeEnum(str, Enum):
    """Message content type enum."""
    TEXT = "text"
    IMAGE = "image"
    VIDEO = "video"
    POST_SHARE = "post_share"  # Shared post from Inspire section


# ============== Message Schemas ==============

class MessageCreate(BaseModel):
    """Schema for creating a new message."""
    content: Optional[str] = None
    message_type: MessageTypeEnum = MessageTypeEnum.TEXT
    media_url: Optional[str] = None
    shared_post_id: Optional[int] = None  # For POST_SHARE type
    reply_to_id: Optional[int] = None  # Reply to another message


class MessageEdit(BaseModel):
    """Schema for editing a message."""
    content: str


class MessageSender(BaseModel):
    """Minimal sender info for messages."""
    id: int
    username: Optional[str]
    full_name: Optional[str]
    profile_picture: Optional[str]

    class Config:
        from_attributes = True


class ReactionInfo(BaseModel):
    """Aggregated reaction info for a message."""
    emoji: str
    count: int
    user_ids: List[int]  # User IDs who reacted with this emoji


class ReactionCreate(BaseModel):
    """Schema for adding a reaction."""
    emoji: str  # ❤️, 👍, 😂, 😮, 😢, 🙏


class ReplyPreview(BaseModel):
    """Minimal info for replied-to message preview."""
    id: int
    sender_id: Optional[int]
    sender_name: Optional[str]
    content: Optional[str]
    message_type: str


class MessageResponse(BaseModel):
    """Schema for message in responses."""
    id: int
    conversation_id: int
    sender_id: Optional[int]
    sender: Optional[MessageSender]
    content: Optional[str]
    message_type: str
    media_url: Optional[str]
    shared_post_id: Optional[int] = None  # For POST_SHARE type
    shared_post: Optional[dict] = None  # Embedded post data for display
    created_at: datetime
    is_read: bool
    read_at: Optional[datetime]
    # Reply support
    reply_to_id: Optional[int] = None
    reply_to: Optional[ReplyPreview] = None
    # Reactions
    reactions: List[ReactionInfo] = []
    # Edit tracking
    edited_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ============== Conversation Schemas ==============

class ConversationCreate(BaseModel):
    """Schema for creating/getting a conversation with a user."""
    participant_id: int  # The other user's ID


class ConversationParticipantInfo(BaseModel):
    """Schema for participant info in conversation."""
    id: int
    username: Optional[str]
    full_name: Optional[str]
    profile_picture: Optional[str]
    last_read_at: Optional[datetime]

    class Config:
        from_attributes = True


class ConversationResponse(BaseModel):
    """Schema for conversation in list view."""
    id: int
    participants: List[ConversationParticipantInfo]
    last_message: Optional[MessageResponse]
    last_message_at: Optional[datetime]
    unread_count: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ConversationListResponse(BaseModel):
    """Response schema for conversations list."""
    conversations: List[ConversationResponse]
    total: int


class ConversationDetailResponse(BaseModel):
    """Schema for single conversation with messages."""
    id: int
    participants: List[ConversationParticipantInfo]
    messages: List[MessageResponse]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ============== WebSocket Message Schemas ==============

class WebSocketMessage(BaseModel):
    """Schema for WebSocket message payloads."""
    type: str  # 'message', 'read_receipt', 'typing', 'message_edit', 'reaction_update', etc.
    data: dict


class NewMessageEvent(BaseModel):
    """Event when a new message is sent."""
    message: MessageResponse


class ReadReceiptEvent(BaseModel):
    """Event when messages are read."""
    conversation_id: int
    user_id: int
    read_at: datetime
    message_ids: List[int]


class TypingEvent(BaseModel):
    """Event when user is typing."""
    conversation_id: int
    user_id: int
    is_typing: bool


class MessageEditEvent(BaseModel):
    """Event when a message is edited."""
    message_id: int
    conversation_id: int
    content: str
    edited_at: datetime


class ReactionUpdateEvent(BaseModel):
    """Event when a reaction is added/removed."""
    message_id: int
    conversation_id: int
    reactions: List[ReactionInfo]
