from typing import Dict, Set
from datetime import datetime
import json
import logging

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query, HTTPException, status
from sqlalchemy.orm import Session

from app.api import deps
from app.models.user import User as UserModel
from app.models.conversation import ConversationParticipant
from app.models.message import Message
from app.schemas.chat import MessageResponse, MessageSender

router = APIRouter()
logger = logging.getLogger(__name__)


class ConnectionManager:
    """
    Manages WebSocket connections for real-time chat.
    Tracks active connections per conversation.
    """
    
    def __init__(self):
        # conversation_id -> {user_id -> WebSocket}
        self.active_connections: Dict[int, Dict[int, WebSocket]] = {}
    
    async def connect(self, websocket: WebSocket, conversation_id: int, user_id: int):
        """Accept connection and add to tracking."""
        await websocket.accept()
        if conversation_id not in self.active_connections:
            self.active_connections[conversation_id] = {}
        self.active_connections[conversation_id][user_id] = websocket
        logger.info(f"User {user_id} connected to conversation {conversation_id}")
    
    def disconnect(self, conversation_id: int, user_id: int):
        """Remove connection from tracking."""
        if conversation_id in self.active_connections:
            if user_id in self.active_connections[conversation_id]:
                del self.active_connections[conversation_id][user_id]
            if not self.active_connections[conversation_id]:
                del self.active_connections[conversation_id]
        logger.info(f"User {user_id} disconnected from conversation {conversation_id}")
    
    async def send_personal_message(self, message: dict, conversation_id: int, user_id: int):
        """Send message to a specific user in conversation."""
        if conversation_id in self.active_connections:
            if user_id in self.active_connections[conversation_id]:
                websocket = self.active_connections[conversation_id][user_id]
                await websocket.send_json(message)
    
    async def broadcast_to_conversation(
        self, 
        message: dict, 
        conversation_id: int, 
        exclude_user_id: int = None
    ):
        """Broadcast message to all users in a conversation."""
        if conversation_id in self.active_connections:
            for user_id, websocket in self.active_connections[conversation_id].items():
                if exclude_user_id and user_id == exclude_user_id:
                    continue
                try:
                    await websocket.send_json(message)
                except Exception as e:
                    logger.error(f"Error sending to user {user_id}: {e}")
    
    def get_online_users(self, conversation_id: int) -> Set[int]:
        """Get set of online user IDs in a conversation."""
        if conversation_id in self.active_connections:
            return set(self.active_connections[conversation_id].keys())
        return set()


manager = ConnectionManager()


def get_user_from_token(token: str, db: Session) -> UserModel:
    """Validate JWT token and return user."""
    from app.core.security import decode_access_token
    
    payload = decode_access_token(token)
    if not payload:
        return None
    
    user_id = payload.get("sub")
    if not user_id:
        return None
    
    user = db.query(UserModel).filter(UserModel.id == int(user_id)).first()
    return user


@router.websocket("/chat/{conversation_id}")
async def websocket_chat(
    websocket: WebSocket,
    conversation_id: int,
    token: str = Query(...),
):
    """
    WebSocket endpoint for real-time chat.
    
    Connect with: ws://host/api/v1/ws/chat/{conversation_id}?token={jwt_token}
    
    Message types:
    - message: New message sent
    - read_receipt: Messages marked as read  
    - typing: User typing indicator
    - online_status: User came online/offline
    """
    # Get database session
    db = next(deps.get_db())
    
    try:
        # Authenticate user
        user = get_user_from_token(token, db)
        if not user:
            await websocket.close(code=4001, reason="Invalid token")
            return
        
        # Verify user is participant of this conversation
        participant = db.query(ConversationParticipant).filter(
            ConversationParticipant.conversation_id == conversation_id,
            ConversationParticipant.user_id == user.id
        ).first()
        
        if not participant:
            await websocket.close(code=4004, reason="Not a participant")
            return
        
        # Connect
        await manager.connect(websocket, conversation_id, user.id)
        
        # Notify others that user is online
        await manager.broadcast_to_conversation(
            {
                "type": "online_status",
                "data": {
                    "user_id": user.id,
                    "is_online": True
                }
            },
            conversation_id,
            exclude_user_id=user.id
        )
        
        try:
            while True:
                # Receive message from client
                data = await websocket.receive_json()
                message_type = data.get("type")
                
                if message_type == "message":
                    # Save message to database
                    content = data.get("data", {}).get("content")
                    media_url = data.get("data", {}).get("media_url")
                    msg_type = data.get("data", {}).get("message_type", "text")
                    
                    if not content and not media_url:
                        continue
                    
                    message = Message(
                        conversation_id=conversation_id,
                        sender_id=user.id,
                        content=content,
                        message_type=msg_type,
                        media_url=media_url
                    )
                    db.add(message)
                    
                    # Update conversation timestamp
                    from app.models.conversation import Conversation
                    conversation = db.query(Conversation).filter(
                        Conversation.id == conversation_id
                    ).first()
                    if conversation:
                        conversation.last_message_at = datetime.utcnow()
                    
                    db.commit()
                    db.refresh(message)
                    
                    # Build response
                    message_response = {
                        "type": "message",
                        "data": {
                            "id": message.id,
                            "conversation_id": message.conversation_id,
                            "sender_id": message.sender_id,
                            "sender": {
                                "id": user.id,
                                "username": user.username,
                                "full_name": user.full_name,
                                "profile_picture": user.profile_picture
                            },
                            "content": message.content,
                            "message_type": message.message_type,
                            "media_url": message.media_url,
                            "created_at": message.created_at.isoformat(),
                            "is_read": message.is_read,
                            "read_at": None
                        }
                    }
                    
                    # Broadcast to all in conversation (including sender for confirmation)
                    await manager.broadcast_to_conversation(
                        message_response,
                        conversation_id
                    )
                
                elif message_type == "read_receipt":
                    # Mark messages as read
                    message_ids = data.get("data", {}).get("message_ids", [])
                    now = datetime.utcnow()
                    
                    if message_ids:
                        db.query(Message).filter(
                            Message.id.in_(message_ids),
                            Message.conversation_id == conversation_id,
                            Message.sender_id != user.id
                        ).update({
                            "is_read": True,
                            "read_at": now
                        }, synchronize_session=False)
                        db.commit()
                        
                        # Notify sender
                        await manager.broadcast_to_conversation(
                            {
                                "type": "read_receipt",
                                "data": {
                                    "user_id": user.id,
                                    "message_ids": message_ids,
                                    "read_at": now.isoformat()
                                }
                            },
                            conversation_id,
                            exclude_user_id=user.id
                        )
                
                elif message_type == "typing":
                    # Broadcast typing indicator
                    is_typing = data.get("data", {}).get("is_typing", False)
                    await manager.broadcast_to_conversation(
                        {
                            "type": "typing",
                            "data": {
                                "user_id": user.id,
                                "is_typing": is_typing
                            }
                        },
                        conversation_id,
                        exclude_user_id=user.id
                    )
        
        except WebSocketDisconnect:
            manager.disconnect(conversation_id, user.id)
            # Notify others that user went offline
            await manager.broadcast_to_conversation(
                {
                    "type": "online_status",
                    "data": {
                        "user_id": user.id,
                        "is_online": False
                    }
                },
                conversation_id
            )
    
    finally:
        db.close()
