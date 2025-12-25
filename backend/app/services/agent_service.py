"""
AI Agent Service with Groq Integration.

This service provides the core agent functionality using Groq's LLM API.
It acts as an "Expert Guide" using real-time user context to answer questions
and provide instructions, rather than executing actions directly.
"""
from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session
from sqlalchemy import desc
from groq import Groq

from app.core.config import settings
from app.schemas.agent import AgentAction, AgentMessage
from app.models.user import User
from app.models.post import Post

# System prompt that defines the agent's personality
SYSTEM_PROMPT = """You are Vextra AI, the expert guide and creative co-pilot for the Vextra app.

## YOUR ROLE:
You are a "Consultant" and "Teacher". You DO NOT execute actions directly. Instead, you GUIDE the user on how to do things and Answer questions about their data.

## YOUR CONTEXT:
You have access to the user's real-time data:
{user_context}

## GUIDELINES:
1.  **Be Helpful & Educational**: If a user asks "Create a post", say: "Head over to the Create tab (the plus icon) to start a new post. Would you like some ideas?"
2.  **Use Data**: If asked "How is my account doing?", use the simplified stats provided in the context to give a specific answer.
3.  **Be Creative**: Help write bio, captions, or brainstorm ideas using your general knowledge.
4.  **Audio Friendly**: Keep responses conversational and easy to listen to (avoid complex markdown).

## EXAMPLES:
- User: "Create a post."
  Agent: "I can't create it for you, but you can tap the '+' button below. I can help you write the caption though! What's the topic?"
- User: "How many followers do I have?"
  Agent: "You currently have 124 followers." (Based on context)
"""


class AgentService:
    """Service for AI agent interactions using Groq."""
    
    def __init__(self):
        """Initialize the Groq client."""
        self.client = None
        if settings.GROQ_API_KEY:
            self.client = Groq(api_key=settings.GROQ_API_KEY)
    
    def is_available(self) -> bool:
        """Check if the agent service is configured and available."""
        return self.client is not None
        
    def get_user_context(self, db: Session, user_id: int) -> str:
        """Fetch real-time user stats and recent activity."""
        try:
            user = db.query(User).filter(User.id == user_id).first()
            if not user:
                return "User data not found."
            
            # Fetch recent posts
            recent_posts = db.query(Post).filter(
                Post.user_id == user_id,
                Post.is_draft == False
            ).order_by(desc(Post.created_at)).limit(3).all()
            
            post_summaries = []
            for p in recent_posts:
                content_preview = (p.content[:30] + "...") if p.content else "Image Post"
                post_summaries.append(f"- Post '{content_preview}' ({p.likes_count} likes)")
                
            drafts_count = db.query(Post).filter(
                Post.user_id == user_id, 
                Post.is_draft == True
            ).count()

            context_str = f"""
            - Name: {user.full_name or user.username}
            - Bio: {user.bio or 'No bio set'}
            - Followers: {user.followers_count}
            - Following: {user.following_count}
            - Total Posts: {user.posts_count}
            - Drafts Pending: {drafts_count}
            - Recent Activity:
              {chr(10).join(post_summaries) if post_summaries else "No recent posts."}
            """
            return context_str
        except Exception as e:
            print(f"Error fetching context: {e}")
            return "Error loading user context."
    
    async def chat(
        self,
        message: str,
        history: Optional[List[AgentMessage]] = None,
        user_context: Optional[Dict[str, Any]] = None,
        db: Optional[Session] = None
    ) -> Dict[str, Any]:
        """
        Process a user message and return agent response.
        """
        if not self.is_available():
            return {
                "message": "I'm sorry, but the AI service is not configured. Please contact support.",
                "actions": [],
                "success": False,
                "error": "GROQ_API_KEY not configured"
            }
        
        try:
            # 1. Fetch rich context if DB is available
            context_data = "No user data available."
            if db and user_context and "user_id" in user_context:
                context_data = self.get_user_context(db, user_context["user_id"])
            
            # 2. Inject context into Prompt
            current_system_prompt = SYSTEM_PROMPT.format(user_context=context_data)

            # 3. Build messages
            messages = [{"role": "system", "content": current_system_prompt}]
            if history:
                for msg in history:
                    messages.append({"role": msg.role, "content": msg.content})
            messages.append({"role": "user", "content": message})
            
            # 4. Call LLM (No Tools)
            response = self.client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=messages,
                temperature=0.7,
                max_tokens=500
            )
            
            response_text = response.choices[0].message.content or "I didn't catch that."
            
            return {
                "message": response_text,
                "actions": [], # No actions in Guide Mode
                "success": True
            }
            
        except Exception as e:
            import traceback
            print(f"Error in agent chat: {e}")
            traceback.print_exc()
            return {
                "message": "I encountered an error. Please try again.",
                "actions": [],
                "success": False,
                "error": str(e)
            }
    
    async def generate_content(
        self,
        topic: str,
        style: str = "casual",
        existing_content: Optional[str] = None
    ) -> str:
        """Generate or improve content for a post."""
        if not self.is_available():
            return ""
        
        prompt = f"Generate a social media post about: {topic}\nStyle: {style}"
        if existing_content:
            prompt = f"Improve this content:\n{existing_content}\n\nMake it more {style}."
        
        try:
            response = self.client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=[
                    {"role": "system", "content": "You are a social media content creator. Generate engaging, concise content. No hashtags unless asked."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.8,
                max_tokens=280
            )
            return response.choices[0].message.content or ""
        except Exception:
            return ""
    
    async def suggest_hashtags(self, content: str, count: int = 5) -> List[str]:
        """Suggest relevant hashtags for content."""
        if not self.is_available():
            return []
        
        try:
            response = self.client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=[
                    {"role": "system", "content": f"Generate exactly {count} relevant hashtags for social media content. Return ONLY the hashtags separated by spaces, starting with #. No explanations."},
                    {"role": "user", "content": content}
                ],
                temperature=0.6,
                max_tokens=100
            )
            hashtags_text = response.choices[0].message.content or ""
            return [tag.strip() for tag in hashtags_text.split() if tag.startswith("#")][:count]
        except Exception:
            return []


# Singleton instance
agent_service = AgentService()
