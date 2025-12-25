"""
Content Publishing API endpoint.
Publish content to connected social platforms.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Dict, Any
from datetime import datetime

from app.api import deps
from app.models.user import User
from app.models.social_connection import SocialConnection
from app.models.post import Post  # Added import
from app.schemas.social_connection import PublishRequest, PublishResponse
from app.core.encryption import decrypt_token
from app.core.encryption import decrypt_token
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
        
        # Check token expiry
        if connection.token_expires_at and datetime.utcnow() >= connection.token_expires_at:
            results[platform] = {
                "success": False,
                "error": "Token expired. Please reconnect your account."
            }
            continue
        
        # Try to publish
        service = SERVICES[platform]
        try:
            access_token = decrypt_token(connection.access_token)
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
