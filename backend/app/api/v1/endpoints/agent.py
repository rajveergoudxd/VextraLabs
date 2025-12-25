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
    
    The agent can understand natural language commands and return actions
    for the app to execute (navigation, post creation, settings changes, etc.)
    """
    if not agent_service.is_available():
        raise HTTPException(
            status_code=503,
            detail="AI Agent service is not available. Please configure GROQ_API_KEY."
        )
    
    # Build user context for personalized responses
    user_context = {
        "user_id": current_user.id,
        "username": current_user.username,
        "full_name": current_user.full_name,
    }
    
    # Process the chat request
    result = await agent_service.chat(
        message=request.message,
        history=request.history,
        user_context=user_context
    )
    
    return AgentChatResponse(
        message=result["message"],
        actions=result["actions"],
        success=result["success"],
        error=result.get("error")
    )


@router.get("/health")
async def agent_health():
    """Check if the agent service is available."""
    return {
        "available": agent_service.is_available(),
        "model": "llama-3.3-70b-versatile" if agent_service.is_available() else None
    }
