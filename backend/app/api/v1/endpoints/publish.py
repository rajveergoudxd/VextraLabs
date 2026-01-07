"""
Content Publishing API endpoint.
Publish content to connected social platforms.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Dict, Any
from datetime import datetime, timedelta

from app.api import deps
from app.models.user import User
from app.models.social_connection import SocialConnection
from app.models.post import Post  # Added import
from app.schemas.social_connection import PublishRequest, PublishResponse
from app.core.encryption import decrypt_token, encrypt_token
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


async def _refresh_platform_token(
    connection: SocialConnection,
    service,
    db: Session
) -> Dict[str, Any]:
    """
    Refresh a platform's access token.
    
    Twitter rotates refresh tokens - each refresh returns a new one.
    This function handles the refresh and updates the database.
    """
    if not connection.refresh_token:
        return {
            "success": False, 
            "error": "No refresh token available. Please reconnect your account."
        }
    
    try:
        refresh_token = decrypt_token(connection.refresh_token)
        new_tokens = await service.refresh_access_token(refresh_token)
        
        # Update connection with new tokens
        connection.access_token = encrypt_token(new_tokens["access_token"])
        # Twitter rotates refresh tokens, so always update if provided
        if new_tokens.get("refresh_token"):
            connection.refresh_token = encrypt_token(new_tokens["refresh_token"])
        connection.token_expires_at = new_tokens.get("expires_at")
        connection.updated_at = datetime.utcnow()
        db.commit()
        
        print(f"Token refreshed successfully for {connection.platform}")
        return {
            "success": True,
            "access_token": new_tokens["access_token"]
        }
    except Exception as e:
        print(f"Token refresh failed for {connection.platform}: {str(e)}")
        return {
            "success": False, 
            "error": f"Token refresh failed: {str(e)}. Please reconnect your account."
        }

@router.post("/", response_model=PublishResponse)
async def publish_content(
    request: PublishRequest,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
):
    """
    Publish content to one or more connected social platforms.
    
    The content will be posted to all specified platforms that have
    valid connections.
    """
    if not request.platforms:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="At least one platform must be specified"
        )
    
    # Get user's connections
    connections = db.query(SocialConnection).filter(
        SocialConnection.user_id == current_user.id,
        SocialConnection.platform.in_(request.platforms),
    ).all()
    
    connections_by_platform = {c.platform: c for c in connections}
    
    # Create internal post record
    internal_post = Post(
        user_id=current_user.id,
        content=request.content,
        media_urls=request.media_urls,
        platforms=request.platforms,
        published_at=datetime.utcnow()
    )
    db.add(internal_post)
    current_user.posts_count += 1
    db.commit()
    db.refresh(internal_post)
    
    results: Dict[str, Any] = {}
    success_count = 0
    
    for platform in request.platforms:
        # Handle 'inspire' as internal platform - always succeeds since post is already created
        if platform == "inspire":
            results[platform] = {
                "success": True,
                "post_id": internal_post.id,
                "message": "Published to Inspire feed"
            }
            success_count += 1
            continue
        
        if platform not in SERVICES:
            results[platform] = {
                "success": False,
                "error": f"Unknown platform: {platform}"
            }
            continue
        
        connection = connections_by_platform.get(platform)
        if not connection:
            results[platform] = {
                "success": False,
                "error": f"Not connected to {platform}. Please connect your {platform} account first."
            }
            continue
        
        # Get the service for this platform
        service = SERVICES[platform]
        
        # Check token expiry and auto-refresh if needed
        access_token = None
        if connection.token_expires_at:
            # Refresh if expired or expiring within 5 minutes (buffer)
            buffer = timedelta(minutes=5)
            if datetime.utcnow() >= (connection.token_expires_at - buffer):
                refresh_result = await _refresh_platform_token(connection, service, db)
                if not refresh_result["success"]:
                    results[platform] = {
                        "success": False,
                        "error": refresh_result["error"]
                    }
                    continue
                # Token refreshed successfully, use new access token
                access_token = refresh_result["access_token"]
        
        # If token wasn't refreshed, decrypt the current one
        if access_token is None:
            access_token = decrypt_token(connection.access_token)
        
        # Try to publish
        try:
            result = await service.publish_post(
                access_token=access_token,
                content=request.content,
                media_urls=request.media_urls,
            )
            results[platform] = {
                "success": True,
                "post_id": result.get("post_id"),
                "url": result.get("url"),
            }
            success_count += 1
        except Exception as e:
            results[platform] = {
                "success": False,
                "error": str(e)
            }
            
    # Update post platforms with successful publish details (IDs, URLs)
    successful_platforms = {k: v for k, v in results.items() if v.get("success")}
    # Update the JSON column with the dictionary of successful platforms and their metadata
    internal_post.platforms = successful_platforms
    db.add(internal_post)
    db.commit()
    
    return PublishResponse(
        success=success_count > 0,
        results=results,
    )


@router.get("/platforms")
async def get_available_platforms():
    """Get list of available social platforms"""
    return {
        "platforms": [
            {
                "id": "instagram",
                "name": "Instagram",
                "supports_text_only": False,
                "max_images": 10,
                "note": "Requires Business/Creator account"
            },
            {
                "id": "twitter",
                "name": "Twitter / X",
                "supports_text_only": True,
                "max_images": 4,
                "max_characters": 280,
            },
            {
                "id": "linkedin",
                "name": "LinkedIn",
                "supports_text_only": True,
                "max_images": 20,
                "max_characters": 3000,
            },
            {
                "id": "facebook",
                "name": "Facebook",
                "supports_text_only": True,
                "max_images": 10,
                "note": "Posts to your Facebook Page"
            },
        ]
    }
