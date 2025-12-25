"""Pydantic schemas for the AI Agent chat endpoint."""
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field


class AgentMessage(BaseModel):
    """A single message in the conversation history."""
    role: str = Field(..., description="Role: 'user' or 'assistant'")
    content: str = Field(..., description="Message content")


class AgentChatRequest(BaseModel):
    """Request to chat with the AI agent."""
    message: str = Field(..., description="User's message or voice transcript")
    history: Optional[List[AgentMessage]] = Field(
        default=None,
        description="Conversation history for context"
    )


class AgentAction(BaseModel):
    """An action for the Flutter app to execute."""
    name: str = Field(..., description="Action/tool name to execute")
    parameters: Dict[str, Any] = Field(
        default_factory=dict,
        description="Parameters for the action"
    )


class AgentChatResponse(BaseModel):
    """Response from the AI agent."""
    message: str = Field(..., description="Agent's response message")
    actions: List[AgentAction] = Field(
        default_factory=list,
        description="Actions for the app to execute"
    )
    success: bool = Field(default=True, description="Whether the request succeeded")
    error: Optional[str] = Field(default=None, description="Error message if failed")
