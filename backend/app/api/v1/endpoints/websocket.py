from typing import Dict, Set, Optional
from datetime import datetime
import json
import logging
import asyncio
from collections import defaultdict

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query, HTTPException, status
from sqlalchemy.orm import Session

from app.api import deps
from app.models.user import User as UserModel
from app.models.conversation import ConversationParticipant
from app.models.message import Message
from app.core.redis_service import redis_manager

router = APIRouter()
logger = logging.getLogger(__name__)


class ConnectionManager:
    """
    Manages WebSocket connections for real-time chat using Redis Pub/Sub.
    Scales horizontally by using Redis to route messages to the correct server instance.
    """
    
    def __init__(self):
        # user_id -> Set[WebSocket] (support multiple devices per user)
        self.active_connections: Dict[int, Set[WebSocket]] = defaultdict(set)
        # Lock for local state
        self.lock = asyncio.Lock()
        self.pubsub = None
        self.listener_task = None
        
    async def _init_redis_listener(self):
        """Initialize the background Redis listener if not running."""
        if self.pubsub:
            return
            
        redis = redis_manager.get_redis()
        if not redis:
            await redis_manager.connect()
            redis = redis_manager.get_redis()
            
        self.pubsub = redis.pubsub()
        self.listener_task = asyncio.create_task(self._redis_listener())
        logger.info("Redis listener task started")

    async def _redis_listener(self):
        """Background task to listen for messages on subscribed channels."""
        try:
            # First, we need to subscribe to something to start the loop? 
            # Or just start loop.
            # aioredis pubsub loop:
            async for message in self.pubsub.listen():
                if message["type"] == "message":
                    await self._handle_redis_message(message)
        except Exception as e:
            logger.error(f"Redis listener error: {e}")
            # Logic to restart listener could go here
            self.pubsub = None

    async def _handle_redis_message(self, message):
        """Dispatch Redis message to local WebSockets."""
        try:
            channel = message["channel"]
            data_str = message["data"]
            data = json.loads(data_str)
            
            # Channel format: "chat:user:{user_id}"
            if ":" in channel:
                parts = channel.split(":")
                if len(parts) >= 3 and parts[1] == "user":
                    target_user_id = int(parts[2])
                    await self._send_to_local_user(target_user_id, data)
        except Exception as e:
            logger.error(f"Error handling Redis message: {e}")

    async def _send_to_local_user(self, user_id: int, message: dict):
        """Send data to all local connections for a user."""
        async with self.lock:
            websockets = self.active_connections.get(user_id, set())
            
        # Send outside lock to avoid blocking
        for ws in list(websockets):
            try:
                await ws.send_json(message)
            except Exception as e:
                logger.error(f"Error sending to WS for user {user_id}: {e}")
                # Cleanup dead connection? Handled by disconnect logic usually.

    async def connect(self, websocket: WebSocket, user_id: int):
        """Accept connection and subscribe to user channel."""
        await websocket.accept()
        
        # Ensure Redis listener is running
        if not self.pubsub:
            await self._init_redis_listener()
            
        async with self.lock:
            is_first_connection = len(self.active_connections[user_id]) == 0
            self.active_connections[user_id].add(websocket)
            
        if is_first_connection and self.pubsub:
            # Subscribe to user's personal channel
            await self.pubsub.subscribe(f"chat:user:{user_id}")
            logger.info(f"Subscribed to chat:user:{user_id}")
            
        logger.info(f"User {user_id} connected via WebSocket")
    
    async def disconnect(self, websocket: WebSocket, user_id: int):
        """Remove connection and unsubscribe if last one."""
        async with self.lock:
            if user_id in self.active_connections:
                self.active_connections[user_id].discard(websocket)
                if not self.active_connections[user_id]:
                    del self.active_connections[user_id]
                    # Unsubscribe
                    if self.pubsub:
                        await self.pubsub.unsubscribe(f"chat:user:{user_id}")
                        logger.info(f"Unsubscribed from chat:user:{user_id}")

        logger.info(f"User {user_id} disconnected")
    
    async def send_message_to_user(self, user_id: int, message: dict):
        """
        Send message to a specific user.
        Publishes to Redis, so it works across all instances.
        """
        channel = f"chat:user:{user_id}"
        await redis_manager.publish(channel, message)
    
    async def broadcast_to_conversation(
        self, 
        conversation_id: int, 
        message: dict, 
        participant_ids: Set[int],
        exclude_user_id: int = None
    ):
        """
        Broadcast to all participants in a conversation.
        Iterates participants and publishes to their user channels.
        """
        for pid in participant_ids:
            if exclude_user_id and pid == exclude_user_id:
                continue
            await self.send_message_to_user(pid, message)

manager = ConnectionManager()


def get_user_from_token(token: str, db: Session) -> UserModel:
    """Validate JWT token and return user."""
    from app.core.security import decode_access_token
    
    try:
        payload = decode_access_token(token)
        if not payload:
            return None
        
        user_id = payload.get("sub")
        if not user_id:
            return None
        
        user = db.query(UserModel).filter(UserModel.id == int(user_id)).first()
        return user
    except Exception as e:
        logger.error(f"Token validation error: {e}")
        return None


@router.websocket("/chat/{conversation_id}")
async def websocket_chat(
    websocket: WebSocket,
    conversation_id: int,
    token: str = Query(...),
):
    """
    WebSocket endpoint for real-time chat.
    Uses Redis-backed ConnectionManager.
    """
    # Get database session
    db = next(deps.get_db())
    
    try:
        # Authenticate
        user = get_user_from_token(token, db)
        if not user:
            await websocket.close(code=4001, reason="Invalid token")
            return
        
        # Verify participation
        participant = db.query(ConversationParticipant).filter(
            ConversationParticipant.conversation_id == conversation_id,
            ConversationParticipant.user_id == user.id
        ).first()
        
        if not participant:
            await websocket.close(code=4004, reason="Not a participant")
            return
            
        # Get all participant IDs for broadcasting
        # We query this once per connection setup? 
        # Better: Query it when sending message to ensure up-to-date.
        # But for optimization, we can fetch it now.
        # Actually, best to fetch on Send.
        
        # Connect
        await manager.connect(websocket, user.id)
        
        # Notify others: User Online
        # We need participant list for this.
        conversation_participants = db.query(ConversationParticipant.user_id).filter(
            ConversationParticipant.conversation_id == conversation_id
        ).all()
        p_ids = {p.user_id for p in conversation_participants}
        
        await manager.broadcast_to_conversation(
            conversation_id,
            {
                "type": "online_status",
                "data": {
                    "user_id": user.id,
                    "is_online": True,
                    "conversation_id": conversation_id
                }
            },
            p_ids,
            exclude_user_id=user.id
        )
        
        try:
            while True:
                # Receive message
                data = await websocket.receive_json()
                message_type = data.get("type")
                
                # Fetch participants again to be safe? Or use cached?
                # Using cached p_ids for this session is usually fine for chat.
                
                if message_type == "message":
                    content = data.get("data", {}).get("content")
                    media_url = data.get("data", {}).get("media_url")
                    msg_type = data.get("data", {}).get("message_type", "text")
                    shared_post_id = data.get("data", {}).get("shared_post_id")
                    
                    if not content and not media_url and not shared_post_id:
                        continue
                    
                    # 1. Save to DB
                    message = Message(
                        conversation_id=conversation_id,
                        sender_id=user.id,
                        content=content,
                        message_type=msg_type,
                        media_url=media_url,
                        shared_post_id=shared_post_id
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
                    
                    # 2. Send ACK to sender
                    ack_msg = {
                        "type": "ack",
                        "data": {
                            "message_id": message.id,
                            "conversation_id": conversation_id,
                            "temp_id": data.get("data", {}).get("temp_id") # If client sent one
                        }
                    }
                    await websocket.send_json(ack_msg)
                    
                    # 3. Build Broadcast Message
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
                            "shared_post_id": message.shared_post_id,
                            "created_at": message.created_at.isoformat(),
                            "is_read": message.is_read
                        }
                    }
                    
                    # 4. Broadcast via Redis
                    await manager.broadcast_to_conversation(
                        conversation_id,
                        message_response,
                        p_ids,
                        exclude_user_id=user.id
                    )
                    
                    # 5. Push Notification (Best Effort)
                    # Note: We don't know who is offline here easily without checking Redis presence for everyone.
                    # But since we Fan-Out, we could potentially check if a user consumed the message?
                    # Hard in PubSub.
                    # Industry Standard: Send Push always, let Client suppress if app is open?
                    # OR: use a reliable queue or presence system.
                    # Current App Logic: Check active_connections.
                    # With Redis: We can't check 'active_connections' of OTHER servers.
                    # Solution:
                    #  a) Send Push to everyone (noisy).
                    #  b) Maintain a 'Presence' in Redis (Set of online_user_ids).
                    # Let's add Redis Presence checking.
                    
                    # Check Redis Presence (Plan: store "online:{user_id}" key with TTL)
                    # For now, let's keep the existing logic but use a simpler heuristic or just send push.
                    # Better: Send Push Task to background.
                    
                    # We will implement a quick Redis Presence check
                    # manager.is_user_online(user_id) -> checks Redis key
                    
                elif message_type == "read_receipt":
                    # Mark as read
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
                            conversation_id,
                            {
                                "type": "read_receipt",
                                "data": {
                                    "user_id": user.id,
                                    "message_ids": message_ids,
                                    "read_at": now.isoformat(),
                                    "conversation_id": conversation_id
                                }
                            },
                            p_ids,
                            exclude_user_id=user.id
                        )
                
                elif message_type == "typing":
                     is_typing = data.get("data", {}).get("is_typing", False)
                     await manager.broadcast_to_conversation(
                        conversation_id,
                        {
                            "type": "typing",
                            "data": {
                                "user_id": user.id,
                                "is_typing": is_typing,
                                "conversation_id": conversation_id
                            }
                        },
                        p_ids,
                        exclude_user_id=user.id
                    )

        except WebSocketDisconnect:
            await manager.disconnect(websocket, user.id)
            # Notify offline
            await manager.broadcast_to_conversation(
                conversation_id,
                {
                    "type": "online_status",
                    "data": {
                        "user_id": user.id,
                        "is_online": False,
                         "conversation_id": conversation_id
                    }
                },
                p_ids,
                exclude_user_id=user.id
            )
            
    finally:
        db.close()
