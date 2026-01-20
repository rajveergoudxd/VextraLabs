from typing import Any, List, Optional
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_, desc, func

from app.api import deps
from app.models.user import User as UserModel
from app.models.conversation import Conversation, ConversationParticipant
from app.models.message import Message, MessageType
from app.models.message_reaction import MessageReaction
from app.models.post import Post
from app.schemas.chat import (
    ConversationCreate,
    ConversationResponse,
    ConversationListResponse,
    ConversationDetailResponse,
    ConversationParticipantInfo,
    MessageCreate,
    MessageEdit,
    MessageResponse,
    MessageSender,
    ReactionCreate,
    ReactionInfo,
    ReplyPreview,
)

router = APIRouter()

# Edit time limit in minutes
MESSAGE_EDIT_TIME_LIMIT = 15


def get_participant_info(participant: ConversationParticipant, user: UserModel) -> ConversationParticipantInfo:
    """Helper to create participant info from models."""
    return ConversationParticipantInfo(
        id=user.id,
        username=user.username,
        full_name=user.full_name,
        profile_picture=user.profile_picture,
        profile_picture=user.profile_picture,
        last_read_at=participant.last_read_at
    )

# Import manager for broadcasting
from fastapi import BackgroundTasks
from app.api.v1.endpoints.websocket import manager


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
    
    # Get shared post data if this is a post_share message
    shared_post = None
    if message.shared_post_id:
        post = db.query(Post).filter(Post.id == message.shared_post_id).first()
        if post:
            shared_post = {
                "id": post.id,
                "content": post.content,
                "media_urls": post.media_urls,
                "user": {
                    "id": post.owner.id,
                    "username": post.owner.username,
                    "profile_picture": post.owner.profile_picture,
                } if post.owner else None,
                "likes_count": post.likes_count,
                "comments_count": post.comments_count,
            }
    
    # Get reply_to preview if this is a reply
    reply_preview = None
    if message.reply_to_id:
        reply_msg = db.query(Message).filter(Message.id == message.reply_to_id).first()
        if reply_msg:
            reply_sender_name = None
            if reply_msg.sender_id:
                reply_sender = db.query(UserModel).filter(UserModel.id == reply_msg.sender_id).first()
                if reply_sender:
                    reply_sender_name = reply_sender.full_name or reply_sender.username
            reply_preview = ReplyPreview(
                id=reply_msg.id,
                sender_id=reply_msg.sender_id,
                sender_name=reply_sender_name,
                content=reply_msg.content[:100] if reply_msg.content else None,
                message_type=reply_msg.message_type
            )
    
    # Aggregate reactions
    reactions = []
    reactions_query = db.query(
        MessageReaction.emoji,
        func.count(MessageReaction.id).label('count'),
        func.array_agg(MessageReaction.user_id).label('user_ids')
    ).filter(
        MessageReaction.message_id == message.id
    ).group_by(MessageReaction.emoji).all()
    
    for emoji, count, user_ids in reactions_query:
        reactions.append(ReactionInfo(
            emoji=emoji,
            count=count,
            user_ids=user_ids or []
        ))
    
    return MessageResponse(
        id=message.id,
        conversation_id=message.conversation_id,
        sender_id=message.sender_id,
        sender=sender,
        content=message.content,
        message_type=message.message_type,
        media_url=message.media_url,
        shared_post_id=message.shared_post_id,
        shared_post=shared_post,
        created_at=message.created_at,
        is_read=message.is_read,
        read_at=message.read_at,
        reply_to_id=message.reply_to_id,
        reply_to=reply_preview,
        reactions=reactions,
        edited_at=message.edited_at
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
    background_tasks: BackgroundTasks,
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
        media_url=message_in.media_url,
        shared_post_id=message_in.shared_post_id,
        reply_to_id=message_in.reply_to_id
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
    
    # Send push notification to other participants
    from app.api.v1.endpoints.notifications import create_notification
    from app.models.notification import NotificationType
    
    for p in conversation.participants:
        if p.user_id != current_user.id:
            # Truncate message for notification preview
            preview = message_in.content[:50] + "..." if message_in.content and len(message_in.content) > 50 else (message_in.content or "Sent a message")
            create_notification(
                db=db,
                user_id=p.user_id,
                notification_type=NotificationType.MESSAGE,
                message=preview,
                actor_id=current_user.id,
                title=f"Message from {current_user.username}",
                related_id=conversation_id,
                related_type="conversation"
            )
    
    
    # Prepare response
    response = get_message_response(message, db)

    # Broadcast to all participants using background task
    participant_ids = {p.user_id for p in conversation.participants}
    
    # We need to serialize the Pydantic model to dict for JSON serialization
    # Pydantic v1 uses .dict(), v2 uses .model_dump() - assuming v1 based on context or standard v1 usage in surrounding code
    # Inspecting usage, likely v1. safe to use jsonable_encoder or .dict()
    from fastapi.encoders import jsonable_encoder
    response_data = jsonable_encoder(response)
    
    broadcast_msg = {
        "type": "message",
        "data": response_data["data"] if "data" in response_data else response_data
        # Note: get_message_response returns flat MessageResponse. 
        # WebSocket expects {"type": "message", "data": ...}
        # But MessageResponse structure: id, conversation_id, ... 
        # So we wrap it.
    }
    # Wait, 'get_message_response' returns the flat model. 
    # In websocket.py we constructed:
    # { "type": "message", "data": { ... fields ... } }
    # So here:
    
    final_broadcast = {
        "type": "message",
        "data": response_data
    }
    
    background_tasks.add_task(
        manager.broadcast_to_conversation,
        conversation_id,
        final_broadcast,
        participant_ids,
        exclude_user_id=current_user.id
    )

    return response


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
    background_tasks: BackgroundTasks,
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
    # Find unread messages first to get IDs for broadcast
    unread_messages = db.query(Message).filter(
        Message.conversation_id == conversation_id,
        Message.sender_id != current_user.id,
        Message.is_read == False
    ).all()
    
    message_ids = [m.id for m in unread_messages]
    
    # Mark all unread messages as read
    updated = 0
    if message_ids:
        updated = db.query(Message).filter(
            Message.id.in_(message_ids)
        ).update({
            "is_read": True,
            "read_at": now
        }, synchronize_session=False)
    
    db.commit()
    
    # Broadcast read receipt
    if message_ids:
        # Get participants
        conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
        if conversation:
            participant_ids = {p.user_id for p in conversation.participants}
            
            background_tasks.add_task(
                manager.broadcast_to_conversation,
                conversation_id,
                {
                    "type": "read_receipt",
                    "data": {
                        "user_id": current_user.id,
                        "message_ids": message_ids,
                        "read_at": now.isoformat(),
                         "conversation_id": conversation_id
                    }
                },
                participant_ids,
                exclude_user_id=current_user.id
            )
    
    db.commit()
    
    return {"marked_read": updated}


# ============== Edit & Reactions ==============

@router.put("/conversations/{conversation_id}/messages/{message_id}", response_model=MessageResponse)
def edit_message(
    conversation_id: int,
    message_id: int,
    edit_in: MessageEdit,
    background_tasks: BackgroundTasks,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> MessageResponse:
    """Edit a sent message (sender only, within time limit)."""
    # Get the message
    message = db.query(Message).filter(
        Message.id == message_id,
        Message.conversation_id == conversation_id
    ).first()
    
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found"
        )
    
    # Verify sender
    if message.sender_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You can only edit your own messages"
        )
    
    # Check time limit
    time_since_sent = datetime.utcnow() - message.created_at.replace(tzinfo=None)
    if time_since_sent > timedelta(minutes=MESSAGE_EDIT_TIME_LIMIT):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Messages can only be edited within {MESSAGE_EDIT_TIME_LIMIT} minutes"
        )
    
    # Store original content if first edit
    if not message.original_content:
        message.original_content = message.content
    
    # Update message
    message.content = edit_in.content
    message.edited_at = datetime.utcnow()
    
    db.commit()
    db.refresh(message)
    
    response = get_message_response(message, db)
    
    # Broadcast edit to all participants
    conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
    if conversation:
        participant_ids = {p.user_id for p in conversation.participants}
        from fastapi.encoders import jsonable_encoder
        
        background_tasks.add_task(
            manager.broadcast_to_conversation,
            conversation_id,
            {
                "type": "message_edit",
                "data": {
                    "message_id": message_id,
                    "conversation_id": conversation_id,
                    "content": message.content,
                    "edited_at": message.edited_at.isoformat()
                }
            },
            participant_ids,
            exclude_user_id=None  # Send to all including sender for sync
        )
    
    return response


@router.post("/conversations/{conversation_id}/messages/{message_id}/reactions")
def add_reaction(
    conversation_id: int,
    message_id: int,
    reaction_in: ReactionCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> dict:
    """Add an emoji reaction to a message."""
    # Validate emoji (allowed emojis)
    allowed_emojis = ["❤️", "👍", "😂", "😮", "😢", "🙏"]
    if reaction_in.emoji not in allowed_emojis:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid emoji. Allowed: ❤️ 👍 😂 😮 😢 🙏"
        )
    
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
    
    # Verify message exists
    message = db.query(Message).filter(
        Message.id == message_id,
        Message.conversation_id == conversation_id
    ).first()
    
    if not message:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Message not found"
        )
    
    # Check if reaction already exists (toggle behavior)
    existing = db.query(MessageReaction).filter(
        MessageReaction.message_id == message_id,
        MessageReaction.user_id == current_user.id,
        MessageReaction.emoji == reaction_in.emoji
    ).first()
    
    if existing:
        # Remove reaction (toggle off)
        db.delete(existing)
        action = "removed"
    else:
        # Add reaction
        reaction = MessageReaction(
            message_id=message_id,
            user_id=current_user.id,
            emoji=reaction_in.emoji
        )
        db.add(reaction)
        action = "added"
    
    db.commit()
    
    # Get updated reactions
    reactions_query = db.query(
        MessageReaction.emoji,
        func.count(MessageReaction.id).label('count'),
        func.array_agg(MessageReaction.user_id).label('user_ids')
    ).filter(
        MessageReaction.message_id == message_id
    ).group_by(MessageReaction.emoji).all()
    
    reactions = [
        {"emoji": emoji, "count": count, "user_ids": user_ids or []}
        for emoji, count, user_ids in reactions_query
    ]
    
    # Broadcast reaction update
    conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
    if conversation:
        participant_ids = {p.user_id for p in conversation.participants}
        
        background_tasks.add_task(
            manager.broadcast_to_conversation,
            conversation_id,
            {
                "type": "reaction_update",
                "data": {
                    "message_id": message_id,
                    "conversation_id": conversation_id,
                    "reactions": reactions
                }
            },
            participant_ids,
            exclude_user_id=None
        )
    
    return {"action": action, "reactions": reactions}


@router.delete("/conversations/{conversation_id}/messages/{message_id}/reactions/{emoji}")
def remove_reaction(
    conversation_id: int,
    message_id: int,
    emoji: str,
    background_tasks: BackgroundTasks,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> dict:
    """Remove an emoji reaction from a message."""
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
    
    # Find and remove reaction
    reaction = db.query(MessageReaction).filter(
        MessageReaction.message_id == message_id,
        MessageReaction.user_id == current_user.id,
        MessageReaction.emoji == emoji
    ).first()
    
    if not reaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Reaction not found"
        )
    
    db.delete(reaction)
    db.commit()
    
    # Get updated reactions
    reactions_query = db.query(
        MessageReaction.emoji,
        func.count(MessageReaction.id).label('count'),
        func.array_agg(MessageReaction.user_id).label('user_ids')
    ).filter(
        MessageReaction.message_id == message_id
    ).group_by(MessageReaction.emoji).all()
    
    reactions = [
        {"emoji": emoji, "count": count, "user_ids": user_ids or []}
        for emoji, count, user_ids in reactions_query
    ]
    
    # Broadcast reaction update
    conversation = db.query(Conversation).filter(Conversation.id == conversation_id).first()
    if conversation:
        participant_ids = {p.user_id for p in conversation.participants}
        
        background_tasks.add_task(
            manager.broadcast_to_conversation,
            conversation_id,
            {
                "type": "reaction_update",
                "data": {
                    "message_id": message_id,
                    "conversation_id": conversation_id,
                    "reactions": reactions
                }
            },
            participant_ids,
            exclude_user_id=None
        )
    
    return {"action": "removed", "reactions": reactions}


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
