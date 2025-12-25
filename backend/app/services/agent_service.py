"""
AI Agent Service with Groq Integration.

This service provides the core agent functionality using Groq's LLM API
with function calling to control all app features via voice/text commands.
"""
import json
from typing import List, Dict, Any, Optional
from groq import Groq
from app.core.config import settings
from app.schemas.agent import AgentAction, AgentMessage


# =============================================================================
# TOOL DEFINITIONS
# =============================================================================
# These tools define ALL actions the agent can perform in the app.
# The agent uses function calling to determine which actions to execute.

AGENT_TOOLS = [
    # ------------- NAVIGATION -------------
    {
        "type": "function",
        "function": {
            "name": "navigate_to",
            "description": "Navigate to a specific screen. Use this for 'show me...', 'go to...', or 'refresh' commands.",
            "parameters": {
                "type": "object",
                "properties": {
                    "screen": {
                        "type": "string",
                        "description": "Screen to open",
                        "enum": [
                            "home", "profile", "settings", "inspire", "create",
                            "notifications", "saved_posts", "drafts", "chat",
                            "followers", "following", "search"
                        ]
                    }
                },
                "required": ["screen"]
            }
        }
    },
    
    # ------------- CONTENT CREATION -------------
    {
        "type": "function",
        "function": {
            "name": "create_post",
            "description": "Create a new post. Use when user wants to write/publish content.",
            "parameters": {
                "type": "object",
                "properties": {
                    "content": {
                        "type": "string",
                        "description": "The post text"
                    },
                    "platforms": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Target platforms"
                    }
                },
                "required": ["content"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "manage_draft",
            "description": "Save, publish, or delete drafts.",
            "parameters": {
                "type": "object",
                "properties": {
                    "action": {
                        "type": "string",
                        "enum": ["save", "publish", "delete"],
                        "description": "Action to perform on draft"
                    },
                    "draft_id": {
                        "type": "integer",
                        "description": "ID of draft (for publish/delete)"
                    },
                    "content": {
                        "type": "string",
                        "description": "Content to save (for save)"
                    },
                    "title": {
                        "type": "string",
                        "description": "Title (optional for save)"
                    }
                },
                "required": ["action"]
            }
        }
    },
    
    # ------------- INTERACTIONS -------------
    {
        "type": "function",
        "function": {
            "name": "interact_with_post",
            "description": "Perform actions on a post: like, save, delete, share, comment.",
            "parameters": {
                "type": "object",
                "properties": {
                    "action": {
                        "type": "string",
                        "enum": ["like", "save", "unsave", "delete", "share", "comment"],
                        "description": "Interaction type"
                    },
                    "post_id": {
                        "type": "integer",
                        "description": "ID of the target post"
                    },
                    "content": {
                        "type": "string",
                        "description": "Comment text (only for 'comment' action)"
                    }
                },
                "required": ["action", "post_id"]
            }
        }
    },
    
    # ------------- SOCIAL -------------
    {
        "type": "function",
        "function": {
            "name": "manage_relationship",
            "description": "Follow or unfollow a user.",
            "parameters": {
                "type": "object",
                "properties": {
                    "action": {
                        "type": "string",
                        "enum": ["follow", "unfollow"]
                    },
                    "user_id": {
                        "type": "integer"
                    },
                    "username": {
                        "type": "string"
                    }
                },
                "required": ["action"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "search_users",
            "description": "Search for users.",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {"type": "string"}
                },
                "required": ["query"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "view_profile",
            "description": "View a user's profile.",
            "parameters": {
                "type": "object",
                "properties": {
                    "username": {"type": "string"}
                },
                "required": ["username"]
            }
        }
    },
    
    # ------------- SETTINGS & ACCOUNT -------------
    {
        "type": "function",
        "function": {
            "name": "change_theme",
            "description": "Change app theme (light/dark/system).",
            "parameters": {
                "type": "object",
                "properties": {
                    "mode": {"type": "string", "enum": ["light", "dark", "system"]}
                },
                "required": ["mode"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "toggle_notifications",
            "description": "Enable/disable push notifications.",
            "parameters": {
                "type": "object",
                "properties": {
                    "enabled": {"type": "boolean"}
                },
                "required": ["enabled"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "update_profile",
            "description": "Update profile info.",
            "parameters": {
                "type": "object",
                "properties": {
                    "full_name": {"type": "string"},
                    "bio": {"type": "string"}
                }
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "logout",
            "description": "Log out.",
            "parameters": {}
        }
    },
    
    # ------------- EXTRAS -------------
    {
        "type": "function",
        "function": {
            "name": "mark_notifications_read",
            "description": "Mark all notifications read.",
            "parameters": {}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "generate_caption",
            "description": "Generate caption using AI.",
            "parameters": {
                "type": "object",
                "properties": {
                    "topic": {"type": "string"},
                    "style": {"type": "string"},
                    "existing_content": {"type": "string"}
                },
                "required": ["topic"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "suggest_hashtags",
            "description": "Suggest hashtags.",
            "parameters": {
                "type": "object",
                "properties": {
                    "content": {"type": "string"},
                    "count": {"type": "integer"}
                },
                "required": ["content"]
            }
        }
    },
]

# System prompt that defines the agent's personality and capabilities
# System prompt that defines the agent's personality and capabilities
SYSTEM_PROMPT = """You are Vextra AI, the creative co-pilot and voice assistant for the Vextra app.

## YOUR DUAL PERSONA:
You must dynamically switch between two modes based on the user's input:

### 1. THE DOER (Action Mode)
- **Trigger**: User gives a clear command (e.g., "Create post", "Go to settings", "Turn on dark mode").
- **Behavior**: Be efficient, brief, and precise. Confirm the action and do it.
- **Example Response**: "Opening settings." or "Creating a post about AI."

### 2. THE THINKER (Chat Mode)
- **Trigger**: User asks a question, seeks advice, or wants ideas (e.g., "How do I make my bio better?", "Give me ideas for a tech post").
- **Behavior**: Be conversational, helpful, creative, and detailed. Use your vast knowledge to consult and guide the user.
- **Example Response**: "To make your bio stand out, try focusing on what you *do* for your audience. Instead of 'Tech Enthusiast', how about 'Helping developers build better apps'? usage?"

## Capabilities:
- **Navigation**: Open any screen (home, profile, settings, inspire feed, create post, notifications, saved posts, drafts, chat, etc.)
- **Content Creation**: Create posts, save drafts, publish drafts, generate captions, suggest hashtags
- **Social Features**: Search users, view profiles, follow/unfollow users
- **Post Interactions**: Like, save, share, comment on posts
- **Settings**: Change theme, toggle notifications, update profile
- **Account**: View notifications, log out
- **Consultation**: Answer general questions, provide social media strategy, explain concepts, tell jokes.

## Guidelines:
1. **Match the User's Energy**: If they are quick, be quick. If they are chatty, be chatty.
2. **Proactive Co-Creation**: If the user wants to create content but is vague, ASK questions to help refine their idea.
   - *Bad*: "Post created." (when content is missing)
   - *Good*: "I can help with that! What topic should we focus on? Tech, lifestyle, or something else?"
3. **Memory**: You have access to the conversation history. Use it to understand context (e.g., "Change *it* to blue").
4. **General Knowledge**: You CAN answer questions not related to the app using your general training data.

## Critical Rules:
- **MISSING INFO**: If a user asks to "create a post" without specifying a topic, DO NOT call the function yet. Ask "What would you like the post to be about?" first.
- **Audio Friendly**: Even in "Thinker" mode, keep individual sentences simple so they sound natural when spoken by TTS. Avoid markdown formatting like bolding or bullet points in your *spoken* response text if possible, or keep them minimal.
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
    
    async def chat(
        self,
        message: str,
        history: Optional[List[AgentMessage]] = None,
        user_context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Process a user message and return agent response with actions.
        
        Args:
            message: User's message or voice transcript
            history: Previous conversation history
            user_context: Optional context about the current user
            
        Returns:
            Dict with 'message', 'actions', 'success', and optionally 'error'
        """
        if not self.is_available():
            return {
                "message": "I'm sorry, but the AI service is not configured. Please contact support.",
                "actions": [],
                "success": False,
                "error": "GROQ_API_KEY not configured"
            }
        
        try:
            # Build messages array for the API
            messages = [{"role": "system", "content": SYSTEM_PROMPT}]
            
            # Add conversation history if provided
            if history:
                for msg in history:
                    messages.append({"role": msg.role, "content": msg.content})
            
            # Add current user message
            messages.append({"role": "user", "content": message})
            
            # Call Groq API with function calling
            response = self.client.chat.completions.create(
                model="llama-3.3-70b-versatile",  # Best model for function calling
                messages=messages,
                tools=AGENT_TOOLS,
                tool_choice="auto",  # Let the model decide when to use tools
                temperature=0.7,
                max_tokens=1024
            )
            
            # Extract response
            assistant_message = response.choices[0].message
            actions = []
            response_text = assistant_message.content or ""
            
            # Process tool calls if any
            if assistant_message.tool_calls:
                for tool_call in assistant_message.tool_calls:
                    function = tool_call.function
                    try:
                        params = json.loads(function.arguments) if function.arguments else {}
                    except json.JSONDecodeError:
                        params = {}
                    
                    actions.append(AgentAction(
                        name=function.name,
                        parameters=params
                    ))
                
                # If there are actions but no text, generate a confirmation
                if not response_text and actions:
                    action_names = [a.name for a in actions]
                    if "navigate_to" in action_names:
                        screen = actions[0].parameters.get("screen", "requested screen")
                        response_text = f"Taking you to {screen.replace('_', ' ')}."
                    elif "create_post" in action_names:
                        response_text = "Creating your post now."
                    elif "manage_draft" in action_names:
                        action = actions[0].parameters.get("action", "manage")
                        response_text = f"{action.capitalize()}ing draft."
                    elif "manage_relationship" in action_names:
                        action = actions[0].parameters.get("action", "update")
                        response_text = f"{action.capitalize()}ing user."
                    elif "interact_with_post" in action_names:
                        action = actions[0].parameters.get("action", "interact")
                        response_text = f"{action.capitalize()}ing post."
                    elif "change_theme" in action_names:
                        mode = actions[0].parameters.get("mode", "selected")
                        response_text = f"Switching to {mode} theme."
                    else:
                        response_text = "Done!"
            
            return {
                "message": response_text,
                "actions": [a.model_dump() for a in actions],
                "success": True
            }
            
        except Exception as e:
            import traceback
            print(f"Error in agent chat: {e}")
            traceback.print_exc()
            return {
                "message": f"I encountered an error processing your request. Please try again. (Error: {str(e)})",
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
                max_tokens=280  # Twitter-friendly length
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
            # Parse hashtags
            hashtags = [tag.strip() for tag in hashtags_text.split() if tag.startswith("#")]
            return hashtags[:count]
        except Exception:
            return []


# Singleton instance
agent_service = AgentService()
