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
            "description": "Navigate to a specific screen in the app",
            "parameters": {
                "type": "object",
                "properties": {
                    "screen": {
                        "type": "string",
                        "description": "Screen name to navigate to",
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
    
    # ------------- POST CREATION -------------
    {
        "type": "function",
        "function": {
            "name": "create_post",
            "description": "Create and publish a new post to social platforms. Use this when user wants to create, write, or publish content.",
            "parameters": {
                "type": "object",
                "properties": {
                    "content": {
                        "type": "string",
                        "description": "The text content of the post"
                    },
                    "platforms": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "Platforms to publish to: 'inspire', 'instagram', 'twitter', 'linkedin'"
                    }
                },
                "required": ["content"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "save_draft",
            "description": "Save the current content as a draft for later editing/publishing",
            "parameters": {
                "type": "object",
                "properties": {
                    "content": {
                        "type": "string",
                        "description": "Draft content to save"
                    },
                    "title": {
                        "type": "string",
                        "description": "Optional title for the draft"
                    }
                },
                "required": ["content"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_drafts",
            "description": "Retrieve all saved drafts for the user",
            "parameters": {
                "type": "object",
                "properties": {}
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "publish_draft",
            "description": "Publish a saved draft",
            "parameters": {
                "type": "object",
                "properties": {
                    "draft_id": {
                        "type": "integer",
                        "description": "ID of the draft to publish"
                    }
                },
                "required": ["draft_id"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "delete_draft",
            "description": "Delete a saved draft",
            "parameters": {
                "type": "object",
                "properties": {
                    "draft_id": {
                        "type": "integer",
                        "description": "ID of the draft to delete"
                    }
                },
                "required": ["draft_id"]
            }
        }
    },
    
    # ------------- POST INTERACTIONS -------------
    {
        "type": "function",
        "function": {
            "name": "like_post",
            "description": "Like or unlike a post",
            "parameters": {
                "type": "object",
                "properties": {
                    "post_id": {
                        "type": "integer",
                        "description": "ID of the post to like"
                    }
                },
                "required": ["post_id"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "save_post",
            "description": "Save/bookmark a post to the user's saved collection",
            "parameters": {
                "type": "object",
                "properties": {
                    "post_id": {
                        "type": "integer",
                        "description": "ID of the post to save"
                    }
                },
                "required": ["post_id"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "unsave_post",
            "description": "Remove a post from saved collection",
            "parameters": {
                "type": "object",
                "properties": {
                    "post_id": {
                        "type": "integer",
                        "description": "ID of the post to unsave"
                    }
                },
                "required": ["post_id"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "delete_post",
            "description": "Delete user's own post",
            "parameters": {
                "type": "object",
                "properties": {
                    "post_id": {
                        "type": "integer",
                        "description": "ID of the post to delete"
                    }
                },
                "required": ["post_id"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "add_comment",
            "description": "Add a comment to a post",
            "parameters": {
                "type": "object",
                "properties": {
                    "post_id": {
                        "type": "integer",
                        "description": "ID of the post to comment on"
                    },
                    "content": {
                        "type": "string",
                        "description": "Comment text"
                    }
                },
                "required": ["post_id", "content"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "share_post",
            "description": "Get a shareable link for a post",
            "parameters": {
                "type": "object",
                "properties": {
                    "post_id": {
                        "type": "integer",
                        "description": "ID of the post to share"
                    }
                },
                "required": ["post_id"]
            }
        }
    },
    
    # ------------- SOCIAL / USERS -------------
    {
        "type": "function",
        "function": {
            "name": "search_users",
            "description": "Search for users by name or username",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Search query (name or username)"
                    }
                },
                "required": ["query"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "view_profile",
            "description": "View a user's public profile",
            "parameters": {
                "type": "object",
                "properties": {
                    "username": {
                        "type": "string",
                        "description": "Username of the profile to view"
                    }
                },
                "required": ["username"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "follow_user",
            "description": "Follow a user",
            "parameters": {
                "type": "object",
                "properties": {
                    "user_id": {
                        "type": "integer",
                        "description": "ID of user to follow"
                    },
                    "username": {
                        "type": "string",
                        "description": "Username of user to follow (alternative to user_id)"
                    }
                }
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "unfollow_user",
            "description": "Unfollow a user",
            "parameters": {
                "type": "object",
                "properties": {
                    "user_id": {
                        "type": "integer",
                        "description": "ID of user to unfollow"
                    },
                    "username": {
                        "type": "string",
                        "description": "Username of user to unfollow (alternative to user_id)"
                    }
                }
            }
        }
    },
    
    # ------------- FEED / CONTENT -------------
    {
        "type": "function",
        "function": {
            "name": "refresh_feed",
            "description": "Refresh the inspire/home feed to get latest posts",
            "parameters": {
                "type": "object",
                "properties": {}
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_my_posts",
            "description": "Get the current user's own published posts",
            "parameters": {
                "type": "object",
                "properties": {}
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_saved_posts",
            "description": "Get all posts saved by the user",
            "parameters": {
                "type": "object",
                "properties": {}
            }
        }
    },
    
    # ------------- SETTINGS -------------
    {
        "type": "function",
        "function": {
            "name": "change_theme",
            "description": "Change the app theme",
            "parameters": {
                "type": "object",
                "properties": {
                    "mode": {
                        "type": "string",
                        "description": "Theme mode",
                        "enum": ["light", "dark", "system"]
                    }
                },
                "required": ["mode"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "toggle_notifications",
            "description": "Enable or disable push notifications",
            "parameters": {
                "type": "object",
                "properties": {
                    "enabled": {
                        "type": "boolean",
                        "description": "Whether notifications should be enabled"
                    }
                },
                "required": ["enabled"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "update_profile",
            "description": "Update user profile information",
            "parameters": {
                "type": "object",
                "properties": {
                    "full_name": {
                        "type": "string",
                        "description": "User's display name"
                    },
                    "bio": {
                        "type": "string",
                        "description": "User's bio/description"
                    }
                }
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "logout",
            "description": "Log out of the current account",
            "parameters": {
                "type": "object",
                "properties": {}
            }
        }
    },
    
    # ------------- NOTIFICATIONS -------------
    {
        "type": "function",
        "function": {
            "name": "get_notifications",
            "description": "Get user's notifications",
            "parameters": {
                "type": "object",
                "properties": {}
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "mark_notifications_read",
            "description": "Mark all notifications as read",
            "parameters": {
                "type": "object",
                "properties": {}
            }
        }
    },
    
    # ------------- CONTENT GENERATION (AI Assist) -------------
    {
        "type": "function",
        "function": {
            "name": "generate_caption",
            "description": "Generate or improve a caption/post content using AI",
            "parameters": {
                "type": "object",
                "properties": {
                    "topic": {
                        "type": "string",
                        "description": "Topic or theme for the caption"
                    },
                    "style": {
                        "type": "string",
                        "description": "Writing style",
                        "enum": ["professional", "casual", "funny", "inspirational", "informative"]
                    },
                    "existing_content": {
                        "type": "string",
                        "description": "Existing content to improve (optional)"
                    }
                },
                "required": ["topic"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "suggest_hashtags",
            "description": "Suggest relevant hashtags for content",
            "parameters": {
                "type": "object",
                "properties": {
                    "content": {
                        "type": "string",
                        "description": "The post content to generate hashtags for"
                    },
                    "count": {
                        "type": "integer",
                        "description": "Number of hashtags to suggest (default 5)"
                    }
                },
                "required": ["content"]
            }
        }
    },
]

# System prompt that defines the agent's personality and capabilities
SYSTEM_PROMPT = """You are Vextra AI, a helpful voice assistant integrated into the Vextra app - a content creation and social media management platform.

## Your Capabilities:
You can help users with:
- **Navigation**: Open any screen (home, profile, settings, inspire feed, create post, notifications, saved posts, drafts, chat, etc.)
- **Content Creation**: Create posts, save drafts, publish drafts, generate captions, suggest hashtags
- **Social Features**: Search users, view profiles, follow/unfollow users
- **Post Interactions**: Like, save, share, comment on posts
- **Settings**: Change theme, toggle notifications, update profile
- **Account**: View notifications, log out

## Guidelines:
1. Be conversational and helpful. You're speaking to the user, so keep responses natural and concise.
2. When asked to do something, confirm what you're doing: "I'll create a post about..." or "Opening your profile now."
3. If a request is ambiguous, ask for clarification.
4. If you can't do something, explain why and suggest alternatives.
5. For content creation, be creative and helpful with suggestions.
6. Keep responses SHORT for voice - max 2-3 sentences unless more detail is needed.
7. MEMORY: You have access to the conversation history. Use it to understand context (e.g., if user says "create it", refer to the previous topic).
8. MISSING INFO: If a user asks to "create a post" without specifying a topic, DO NOT call the function yet. Ask "What would you like the post to be about?" first.

## Context:
- The user interacts via voice or text
- Actions you return will be executed by the app
- You have access to the user's current session and can perform actions on their behalf

Remember: You are a voice assistant, so be conversational and efficient!"""


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
                    elif "follow_user" in action_names:
                        response_text = "Following that user for you."
                    elif "unfollow_user" in action_names:
                        response_text = "Unfollowing that user."
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
            return {
                "message": "I encountered an error processing your request. Please try again.",
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
