"""
Global presence tracking for online status.
Manages WebSocket connections for real-time online/offline updates.
"""
from typing import Dict, Set
import logging

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query
from sqlalchemy.orm import Session

from app.api import deps
from app.models.user import User as UserModel
from app.models.follow import Follow
from app.schemas.presence import OnlineUser, OnlineFollowingResponse, PresenceEvent

router = APIRouter()
logger = logging.getLogger(__name__)


class PresenceManager:
    """
    Manages global presence tracking for all connected users.
    Tracks who is online and broadcasts presence changes to followers.
    """
    
    def __init__(self):
        # user_id -> WebSocket connection
        self.active_connections: Dict[int, WebSocket] = {}
        # user_id -> set of follower user_ids (for efficient broadcasting)
        self.follower_cache: Dict[int, Set[int]] = {}
    
    async def connect(self, websocket: WebSocket, user: UserModel, db: Session):
        """Accept connection and add user to online tracking."""
        await websocket.accept()
        self.active_connections[user.id] = websocket
        
        # Cache this user's followers for efficient broadcasting
        followers = db.query(Follow.follower_id).filter(
            Follow.following_id == user.id
        ).all()
        self.follower_cache[user.id] = {f.follower_id for f in followers}
        
        logger.info(f"User {user.id} ({user.username}) connected to presence")
        
        # Notify followers that this user is now online
        await self.broadcast_presence_change(user, is_online=True)
    
    def disconnect(self, user_id: int):
        """Remove user from online tracking."""
        if user_id in self.active_connections:
            del self.active_connections[user_id]
        if user_id in self.follower_cache:
            del self.follower_cache[user_id]
        logger.info(f"User {user_id} disconnected from presence")
    
    def is_online(self, user_id: int) -> bool:
        """Check if a user is currently online."""
        return user_id in self.active_connections
    
    def get_online_user_ids(self) -> Set[int]:
        """Get set of all online user IDs."""
        return set(self.active_connections.keys())
    
    async def broadcast_presence_change(self, user: UserModel, is_online: bool):
        """Broadcast online/offline status change to user's followers."""
        followers = self.follower_cache.get(user.id, set())
        
        event = {
            "type": "presence_change",
            "data": {
                "user_id": user.id,
                "is_online": is_online,
                "username": user.username,
                "full_name": user.full_name,
                "profile_picture": user.profile_picture,
            }
        }
        
        # Send to all online followers
        for follower_id in followers:
            if follower_id in self.active_connections:
                try:
                    await self.active_connections[follower_id].send_json(event)
                except Exception as e:
                    logger.error(f"Error sending presence to user {follower_id}: {e}")
    
    async def send_initial_online_list(self, websocket: WebSocket, user_id: int, db: Session):
        """Send the list of currently online following users to a newly connected user."""
        # Get users that this user is following
        following = db.query(Follow.following_id).filter(
            Follow.follower_id == user_id
        ).all()
        following_ids = {f.following_id for f in following}
        
        # Filter to only online users
        online_following_ids = following_ids & self.get_online_user_ids()
        
        if online_following_ids:
            # Fetch user details
            online_users = db.query(UserModel).filter(
                UserModel.id.in_(online_following_ids)
            ).all()
            
            await websocket.send_json({
                "type": "initial_online_list",
                "data": {
                    "online_users": [
                        {
                            "id": u.id,
                            "username": u.username,
                            "full_name": u.full_name,
                            "profile_picture": u.profile_picture,
                        }
                        for u in online_users
                    ]
                }
            })


# Global presence manager instance
presence_manager = PresenceManager()


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


# ============== REST Endpoints ==============

@router.get("/following/online", response_model=OnlineFollowingResponse)
def get_online_following(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
):
    """
    Get list of following users who are currently online.
    Used for initial load of the online users bar.
    """
    # Get users that current user is following
    following = db.query(Follow.following_id).filter(
        Follow.follower_id == current_user.id
    ).all()
    following_ids = {f.following_id for f in following}
    
    # Filter to only online users
    online_ids = following_ids & presence_manager.get_online_user_ids()
    
    if not online_ids:
        return OnlineFollowingResponse(online_users=[], total=0)
    
    # Fetch user details
    online_users = db.query(UserModel).filter(
        UserModel.id.in_(online_ids)
    ).all()
    
    return OnlineFollowingResponse(
        online_users=[
            OnlineUser(
                id=u.id,
                username=u.username,
                full_name=u.full_name,
                profile_picture=u.profile_picture,
            )
            for u in online_users
        ],
        total=len(online_users)
    )


# ============== WebSocket Endpoint ==============

@router.websocket("/ws")
async def websocket_presence(
    websocket: WebSocket,
    token: str = Query(...),
):
    """
    WebSocket endpoint for global presence tracking.
    
    Connect with: ws://host/api/v1/presence/ws?token={jwt_token}
    
    Events received:
    - initial_online_list: List of following users currently online
    - presence_change: User came online/offline
    
    Events to send:
    - heartbeat: Send periodically to keep connection alive
    """
    db = next(deps.get_db())
    
    try:
        # Authenticate user
        user = get_user_from_token(token, db)
        if not user:
            await websocket.close(code=4001, reason="Invalid token")
            return
        
        # Connect and mark as online
        await presence_manager.connect(websocket, user, db)
        
        # Send initial list of online following users
        await presence_manager.send_initial_online_list(websocket, user.id, db)
        
        try:
            while True:
                # Keep connection alive, handle heartbeats
                data = await websocket.receive_json()
                message_type = data.get("type")
                
                if message_type == "heartbeat":
                    # Respond to heartbeat
                    await websocket.send_json({"type": "heartbeat_ack"})
        
        except WebSocketDisconnect:
            presence_manager.disconnect(user.id)
            # Notify followers that user went offline
            await presence_manager.broadcast_presence_change(user, is_online=False)
    
    finally:
        db.close()
