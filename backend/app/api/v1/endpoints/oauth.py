"""
OAuth and Social Connection API endpoints.
Handles OAuth flow and managing social platform connections.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import secrets
from datetime import datetime

from app.api import deps
from app.models.user import User
from app.models.social_connection import SocialConnection
from app.schemas.social_connection import (
    SocialConnectionResponse,
    SocialConnectionList,
    OAuthAuthorizeResponse,
    OAuthCallbackRequest,
)
from app.core.encryption import encrypt_token, decrypt_token
from app.services.social import (
    InstagramService,
    TwitterService,
    LinkedInService,
    FacebookService,
)

router = APIRouter()

# Service instances
SERVICES = {
    "instagram": InstagramService(),
    "twitter": TwitterService(),
    "linkedin": LinkedInService(),
    "facebook": FacebookService(),
}

# In-memory state storage (in production, use Redis or DB)
OAUTH_STATES = {}


@router.get("/connections", response_model=SocialConnectionList)
async def get_connections(
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
):
    """Get all social connections for the authenticated user"""
    connections = db.query(SocialConnection).filter(
        SocialConnection.user_id == current_user.id
    ).all()
    
    # Check token validity for each connection
    result = []
    for conn in connections:
        is_valid = True
        if conn.token_expires_at:
            is_valid = datetime.utcnow() < conn.token_expires_at
        
        result.append(SocialConnectionResponse(
            id=conn.id,
            platform=conn.platform,
            platform_user_id=conn.platform_user_id,
            platform_username=conn.platform_username,
            platform_display_name=conn.platform_display_name,
            platform_profile_picture=conn.platform_profile_picture,
            is_token_valid=is_valid,
            token_expires_at=conn.token_expires_at,
            created_at=conn.created_at,
            updated_at=conn.updated_at,
        ))
    
    return SocialConnectionList(connections=result)


@router.get("/{platform}/authorize", response_model=OAuthAuthorizeResponse)
async def authorize(
    platform: str,
    current_user: User = Depends(deps.get_current_user),
):
    """Get OAuth authorization URL for a platform"""
    if platform not in SERVICES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unknown platform: {platform}. Supported: {list(SERVICES.keys())}"
        )
    
    service = SERVICES[platform]
    state = secrets.token_urlsafe(32)
    
    # Store state with user info
    OAUTH_STATES[state] = {
        "user_id": current_user.id,
        "platform": platform,
    }
    
    auth_data = await service.get_authorization_url(state)
    
    if isinstance(auth_data, dict):
        authorization_url = auth_data["url"]
        # Store code_verifier for PKCE (OAuth 2.0) or request_secret for OAuth 1.0a
        if "code_verifier" in auth_data:
            OAUTH_STATES[state]["code_verifier"] = auth_data["code_verifier"]
        if "oauth_token_secret" in auth_data:
            OAUTH_STATES[state]["request_secret"] = auth_data["oauth_token_secret"]
            if "oauth_token" in auth_data:
                OAUTH_STATES[auth_data["oauth_token"]] = OAUTH_STATES[state]
    else:
        authorization_url = auth_data
    
    return OAuthAuthorizeResponse(
        authorization_url=authorization_url,
        state=state,
    )


@router.post("/{platform}/callback")
async def callback(
    platform: str,
    request: OAuthCallbackRequest,
    db: Session = Depends(deps.get_db),
):
    """Handle OAuth callback and store tokens"""
    if platform not in SERVICES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unknown platform: {platform}"
        )
    
    # Verify state
    # Try state first, then oauth_token (for OAuth 1.0a)
    state_key = request.state
    if not state_key and request.oauth_token:
        state_key = request.oauth_token
        
    state_data = OAUTH_STATES.pop(state_key, None)
    
    # If not found, try looking up by oauth_token explicitly if state was sent but invalid
    if not state_data and request.oauth_token:
        state_data = OAUTH_STATES.pop(request.oauth_token, None)
        
    if not state_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired state parameter"
        )
    
    if state_data["platform"] != platform:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Platform mismatch in state"
        )
    
    service = SERVICES[platform]
    
    try:
        # Exchange code for tokens
        token_data = await service.exchange_code_for_token(
            code=request.code,
            state=request.state,
            oauth_verifier=request.oauth_verifier,
            oauth_token=request.oauth_token,
            request_secret=state_data.get("request_secret"),
            code_verifier=state_data.get("code_verifier"),  # For PKCE
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    user_id = state_data["user_id"]
    
    # Check if connection already exists
    existing = db.query(SocialConnection).filter(
        SocialConnection.user_id == user_id,
        SocialConnection.platform == platform,
    ).first()
    
    if existing:
        # Update existing connection
        existing.platform_user_id = token_data["user_id"]
        existing.platform_username = token_data.get("username", "")
        existing.platform_display_name = token_data.get("display_name", "")
        existing.platform_profile_picture = token_data.get("profile_picture", "")
        existing.access_token = encrypt_token(token_data["access_token"])
        existing.refresh_token = encrypt_token(token_data.get("refresh_token", "") or "")
        existing.token_expires_at = token_data.get("expires_at")
        existing.updated_at = datetime.utcnow()
        db.commit()
        connection = existing
    else:
        # Create new connection
        connection = SocialConnection(
            user_id=user_id,
            platform=platform,
            platform_user_id=token_data["user_id"],
            platform_username=token_data.get("username", ""),
            platform_display_name=token_data.get("display_name", ""),
            platform_profile_picture=token_data.get("profile_picture", ""),
            access_token=encrypt_token(token_data["access_token"]),
            refresh_token=encrypt_token(token_data.get("refresh_token", "") or ""),
            token_expires_at=token_data.get("expires_at"),
        )
        db.add(connection)
        db.commit()
        db.refresh(connection)
    
    return {
        "success": True,
        "platform": platform,
        "username": connection.platform_username,
    }


@router.delete("/{platform}/disconnect")
async def disconnect(
    platform: str,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
):
    """Disconnect a social platform"""
    connection = db.query(SocialConnection).filter(
        SocialConnection.user_id == current_user.id,
        SocialConnection.platform == platform,
    ).first()
    
    if not connection:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No {platform} connection found"
        )
    
    # Try to revoke access on the platform
    if platform in SERVICES:
        service = SERVICES[platform]
        try:
            access_token = decrypt_token(connection.access_token)
            await service.revoke_access(access_token)
        except Exception:
            pass  # Continue with deletion even if revocation fails
    
    db.delete(connection)
    db.commit()
    
    return {"success": True, "message": f"{platform} disconnected"}


@router.post("/{platform}/refresh")
async def refresh_token(
    platform: str,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
):
    """Refresh access token for a platform"""
    connection = db.query(SocialConnection).filter(
        SocialConnection.user_id == current_user.id,
        SocialConnection.platform == platform,
    ).first()
    
    if not connection:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No {platform} connection found"
        )
    
    if not connection.refresh_token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No refresh token available. Please reconnect."
        )
    
    service = SERVICES[platform]
    
    try:
        refresh_token = decrypt_token(connection.refresh_token)
        new_tokens = await service.refresh_access_token(refresh_token)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    
    # Update tokens
    connection.access_token = encrypt_token(new_tokens["access_token"])
    if new_tokens.get("refresh_token"):
        connection.refresh_token = encrypt_token(new_tokens["refresh_token"])
    connection.token_expires_at = new_tokens.get("expires_at")
    connection.updated_at = datetime.utcnow()
    db.commit()
    
    return {"success": True, "expires_at": connection.token_expires_at}
