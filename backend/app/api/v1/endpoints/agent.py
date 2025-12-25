"""AI Agent API endpoint."""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.api import deps
from app.models.user import User
from app.schemas.agent import AgentChatRequest, AgentChatResponse
from app.services.agent_service import agent_service

router = APIRouter()


@router.post("/chat", response_model=AgentChatResponse)
async def agent_chat(
    request: AgentChatRequest,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
):
    """
    Chat with the AI agent.
    """
    # Create user context
    user_context = {
        "user_id": current_user.id,
        "username": current_user.username or current_user.full_name,
        "email": current_user.email
    }
    
    response = await agent_service.chat(
        message=request.message,
        history=request.history,
        user_context=user_context,
        db=db
    )
    
    return AgentChatResponse(
        message=response["message"],
        actions=response.get("actions", []),
        success=response["success"],
        error=response.get("error")
    )


@router.get("/health")
async def agent_health():
    """Check if the agent service is available."""
    return {
        "available": agent_service.is_available(),
        "model": "llama-3.3-70b-versatile" if agent_service.is_available() else None
    }
