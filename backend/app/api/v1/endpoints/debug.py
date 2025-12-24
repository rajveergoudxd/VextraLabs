from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session
from datetime import datetime
from app.api import deps
from app.models.user import User
from app.models.social_connection import SocialConnection
from app.core.encryption import decrypt_token
from app.services.social import LinkedInService

router = APIRouter()

@router.get("/db-status", response_model=List[str])
def check_db_tables(
    db: Session = Depends(deps.get_db),
) -> Any:
    """
    Fetch list of all tables in the current database.
    Useful for debugging migration issues.
    """
    try:
        # PostgreSQL specific query to get all table names in public schema
        result = db.execute(text(
            "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"
        ))
        tables = [row[0] for row in result.fetchall()]
        return tables
    except Exception as e:
        return [f"Error: {str(e)}"]


@router.get("/linkedin-status")
async def check_linkedin_status(
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """
    Check LinkedIn connection status and token validity.
    """
    connection = db.query(SocialConnection).filter(
        SocialConnection.user_id == current_user.id,
        SocialConnection.platform == "linkedin"
    ).first()
    
    if not connection:
        return {
            "connected": False,
            "error": "LinkedIn not connected. Please connect your LinkedIn account."
        }
    
    # Check token expiry
    token_expired = False
    if connection.token_expires_at:
        token_expired = datetime.utcnow() >= connection.token_expires_at
    
    return {
        "connected": True,
        "username": connection.platform_username,
        "platform_user_id": connection.platform_user_id,
        "token_expires_at": connection.token_expires_at.isoformat() if connection.token_expires_at else None,
        "token_expired": token_expired,
        "has_access_token": bool(connection.access_token),
    }


@router.post("/linkedin-test-post")
async def test_linkedin_post(
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(deps.get_db),
) -> Any:
    """
    Test LinkedIn posting with a simple message.
    """
    connection = db.query(SocialConnection).filter(
        SocialConnection.user_id == current_user.id,
        SocialConnection.platform == "linkedin"
    ).first()
    
    if not connection:
        raise HTTPException(status_code=400, detail="LinkedIn not connected")
    
    if connection.token_expires_at and datetime.utcnow() >= connection.token_expires_at:
        raise HTTPException(status_code=400, detail="LinkedIn token expired. Please reconnect.")
    
    try:
        access_token = decrypt_token(connection.access_token)
        service = LinkedInService()
        
        result = await service.publish_post(
            access_token=access_token,
            content="🧪 Test post from Vextra - please ignore! #test",
            media_urls=None
        )
        
        return {
            "success": True,
            "post_id": result.get("post_id"),
            "post_url": result.get("url"),
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "error_type": type(e).__name__
        }
