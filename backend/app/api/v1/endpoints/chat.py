from typing import Any, List, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_, desc, func

from app.api import deps
from app.models.user import User as UserModel
from app.models.conversation import Conversation, ConversationParticipant
from app.models.message import Message, MessageType
from app.schemas.chat import (
    ConversationCreate,
    ConversationResponse,
    ConversationListResponse,
    ConversationDetailResponse,
    ConversationParticipantInfo,
    MessageCreate,
    MessageResponse,
    MessageSender,
)

router = APIRouter()


def get_participant_info(participant: ConversationParticipant, user: UserModel) -> ConversationParticipantInfo:
    """Helper to create participant info from models."""
    return ConversationParticipantInfo(
        id=user.id,
        username=user.username,
        full_name=user.full_name,
        profile_picture=user.profile_picture,
        last_read_at=participant.last_read_at
    )


def get_message_response(message: Message, db: Session) -> MessageResponse:
    """Helper to create message response from model."""
    sender = None
    if message.sender_id:
        sender_user = db.query(UserModel).filter(UserModel.id == message.sender_id).first()
        if sender_user:
            sender = MessageSender(
                id=sender_user.id,
                username=sender_user.username,
                full_name=sender_user.full_name,
                profile_picture=sender_user.profile_picture
            )
    
    return MessageResponse(
        id=message.id,
        conversation_id=message.conversation_id,
        sender_id=message.sender_id,
        sender=sender,
        content=message.content,
        message_type=message.message_type,
        media_url=message.media_url,
        created_at=message.created_at,
        is_read=message.is_read,
        read_at=message.read_at
    )


# ============== Conversations ==============

@router.post("/conversations", response_model=ConversationResponse)
def create_or_get_conversation(
    conversation_in: ConversationCreate,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> ConversationResponse:
    """Create a new conversation with a user or get existing one."""
    participant_id = conversation_in.participant_id
    
    # Can't message yourself
    if participant_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot start a conversation with yourself"
        )
    
    # Check if target user exists
    target_user = db.query(UserModel).filter(UserModel.id == participant_id).first()
    if not target_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Check for existing 1:1 conversation between these users
    existing_conversation = db.query(Conversation).join(
        ConversationParticipant
    ).filter(
        ConversationParticipant.user_id == current_user.id
    ).filter(
        Conversation.id.in_(
            db.query(ConversationParticipant.conversation_id).filter(
                ConversationParticipant.user_id == participant_id
            )
        )
    ).first()
    
    if existing_conversation:
        # Return existing conversation
        return _build_conversation_response(existing_conversation, current_user, db)
    
    # Create new conversation
    conversation = Conversation()
    db.add(conversation)
    db.flush()  # Get the ID
    
    # Add participants
    participant1 = ConversationParticipant(
        conversation_id=conversation.id,
        user_id=current_user.id
    )
    participant2 = ConversationParticipant(
        conversation_id=conversation.id,
        user_id=participant_id
    )
    db.add_all([participant1, participant2])
    db.commit()
    db.refresh(conversation)
    
    return _build_conversation_response(conversation, current_user, db)


@router.get("/conversations", response_model=ConversationListResponse)
def get_conversations(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
    skip: int = 0,
    limit: int = 50,
) -> ConversationListResponse:
    """Get all conversations for current user."""
    # Get conversation IDs where current user is a participant
    conversation_ids = db.query(ConversationParticipant.conversation_id).filter(
        ConversationParticipant.user_id == current_user.id
    ).subquery()
    
    conversations = db.query(Conversation).filter(
        Conversation.id.in_(conversation_ids)
    ).order_by(
        desc(Conversation.last_message_at),
        desc(Conversation.created_at)
    ).offset(skip).limit(limit).all()
    
    total = db.query(Conversation).filter(
        Conversation.id.in_(conversation_ids)
    ).count()
    
    return ConversationListResponse(
        conversations=[
            _build_conversation_response(conv, current_user, db) 
            for conv in conversations
        ],
        total=total
    )


@router.get("/conversations/{conversation_id}", response_model=ConversationDetailResponse)
def get_conversation_detail(
    conversation_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> ConversationDetailResponse:
    """Get a specific conversation with messages."""
    # Check if user is a participant
    participant = db.query(ConversationParticipant).filter(
        ConversationParticipant.conversation_id == conversation_id,
        ConversationParticipant.user_id == current_user.id
    ).first()
    
    if not participant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found"
        )
    
    conversation = db.query(Conversation).filter(
        Conversation.id == conversation_id
    ).first()
    
    # Update last_read_at for current user
    participant.last_read_at = datetime.utcnow()
    
    # Mark unread messages as read
    db.query(Message).filter(
        Message.conversation_id == conversation_id,
        Message.sender_id != current_user.id,
        Message.is_read == False
    ).update({
        "is_read": True,
        "read_at": datetime.utcnow()
    })
    
    db.commit()
    
    # Build response with messages
    participants_info = []
    for p in conversation.participants:
        user = db.query(UserModel).filter(UserModel.id == p.user_id).first()
        if user:
            participants_info.append(get_participant_info(p, user))
    
    messages = [get_message_response(m, db) for m in conversation.messages]
    
    return ConversationDetailResponse(
        id=conversation.id,
        participants=participants_info,
        messages=messages,
        created_at=conversation.created_at,
        updated_at=conversation.updated_at
    )


# ============== Messages ==============

@router.post("/conversations/{conversation_id}/messages", response_model=MessageResponse)
def send_message(
    conversation_id: int,
    message_in: MessageCreate,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> MessageResponse:
    """Send a message in a conversation."""
    # Check if user is a participant
    participant = db.query(ConversationParticipant).filter(
        ConversationParticipant.conversation_id == conversation_id,
        ConversationParticipant.user_id == current_user.id
    ).first()
    
    if not participant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found"
        )
    
    # Validate message content
    if not message_in.content and not message_in.media_url:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Message must have content or media"
        )
    
    # Create message
    message = Message(
        conversation_id=conversation_id,
        sender_id=current_user.id,
        content=message_in.content,
        message_type=message_in.message_type.value,
        media_url=message_in.media_url
    )
    db.add(message)
    
    # Update conversation last_message_at
    conversation = db.query(Conversation).filter(
        Conversation.id == conversation_id
    ).first()
    conversation.last_message_at = datetime.utcnow()
    
    # Update sender's last_read_at
    participant.last_read_at = datetime.utcnow()
    
    db.commit()
    db.refresh(message)
    
    return get_message_response(message, db)


@router.get("/conversations/{conversation_id}/messages", response_model=List[MessageResponse])
def get_messages(
    conversation_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
    skip: int = 0,
    limit: int = 50,
    before_id: Optional[int] = None,
) -> List[MessageResponse]:
    """Get messages for a conversation with pagination."""
    # Check if user is a participant
    participant = db.query(ConversationParticipant).filter(
        ConversationParticipant.conversation_id == conversation_id,
        ConversationParticipant.user_id == current_user.id
    ).first()
    
    if not participant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found"
        )
    
    query = db.query(Message).filter(
        Message.conversation_id == conversation_id
    )
    
    if before_id:
        query = query.filter(Message.id < before_id)
    
    messages = query.order_by(desc(Message.created_at)).offset(skip).limit(limit).all()
    
    # Reverse to get chronological order
    messages.reverse()
    
    return [get_message_response(m, db) for m in messages]


@router.put("/conversations/{conversation_id}/read")
def mark_conversation_read(
    conversation_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> dict:
    """Mark all messages in a conversation as read."""
    # Check if user is a participant
    participant = db.query(ConversationParticipant).filter(
        ConversationParticipant.conversation_id == conversation_id,
        ConversationParticipant.user_id == current_user.id
    ).first()
    
    if not participant:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation not found"
        )
    
    now = datetime.utcnow()
    
    # Update participant's last_read_at
    participant.last_read_at = now
    
    # Mark all unread messages as read
    updated = db.query(Message).filter(
        Message.conversation_id == conversation_id,
        Message.sender_id != current_user.id,
        Message.is_read == False
    ).update({
        "is_read": True,
        "read_at": now
    })
    
    db.commit()
    
    return {"marked_read": updated}


# ============== Helper Functions ==============

def _build_conversation_response(
    conversation: Conversation,
    current_user: UserModel,
    db: Session
) -> ConversationResponse:
    """Build conversation response with all needed data."""
    # Get participants (excluding current user for display)
    participants_info = []
    for p in conversation.participants:
        user = db.query(UserModel).filter(UserModel.id == p.user_id).first()
        if user:
            participants_info.append(get_participant_info(p, user))
    
    # Get last message
    last_message = db.query(Message).filter(
        Message.conversation_id == conversation.id
    ).order_by(desc(Message.created_at)).first()
    
    last_message_response = None
    if last_message:
        last_message_response = get_message_response(last_message, db)
    
    # Count unread messages for current user
    current_participant = db.query(ConversationParticipant).filter(
        ConversationParticipant.conversation_id == conversation.id,
        ConversationParticipant.user_id == current_user.id
    ).first()
    
    unread_count = 0
    if current_participant:
        unread_query = db.query(Message).filter(
            Message.conversation_id == conversation.id,
            Message.sender_id != current_user.id,
            Message.is_read == False
        )
        unread_count = unread_query.count()
    
    return ConversationResponse(
        id=conversation.id,
        participants=participants_info,
        last_message=last_message_response,
        last_message_at=conversation.last_message_at,
        unread_count=unread_count,
        created_at=conversation.created_at,
        updated_at=conversation.updated_at
    )
