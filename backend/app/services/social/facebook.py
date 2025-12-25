"""
Facebook Graph API integration for OAuth and content publishing.
Posts to Facebook Pages (not personal profiles).
"""
import httpx
from typing import Optional, Dict, Any, List
from urllib.parse import urlencode
from datetime import datetime, timedelta

from app.core.config import settings
from .base import BaseSocialService


class FacebookService(BaseSocialService):
    """Facebook Graph API integration"""
    
    GRAPH_API_BASE = "https://graph.facebook.com/v18.0"
    OAUTH_BASE = "https://www.facebook.com/v18.0/dialog/oauth"
    
    # Required scopes for posting to pages
    SCOPES = [
        "pages_show_list",
        "pages_read_engagement",
        "pages_manage_posts",
        "pages_manage_engagement",
    ]

    @property
    def platform_name(self) -> str:
        return "facebook"

    async def get_authorization_url(self, state: str) -> Dict[str, Any]:
        """Generate Facebook OAuth authorization URL"""
        params = {
            "client_id": settings.META_APP_ID,  # Same app as Instagram
            "redirect_uri": settings.META_REDIRECT_URI,
            "scope": ",".join(self.SCOPES),
            "response_type": "code",
            "state": state,
        }
        return {"url": f"{self.OAUTH_BASE}?{urlencode(params)}"}

    async def exchange_code_for_token(
        self, 
        code: str, 
        state: str
    ) -> Dict[str, Any]:
        """Exchange code for access token and get page info"""
        async with httpx.AsyncClient() as client:
            # Exchange code for user token
            token_response = await client.get(
                f"{self.GRAPH_API_BASE}/oauth/access_token",
                params={
                    "client_id": settings.META_APP_ID,
                    "client_secret": settings.META_APP_SECRET,
                    "redirect_uri": settings.META_REDIRECT_URI,
                    "code": code,
                }
            )
            token_data = token_response.json()
            
            if "error" in token_data:
                raise Exception(f"Token exchange failed: {token_data['error']['message']}")
            
            user_token = token_data["access_token"]
            
            # Exchange for long-lived token
            long_token_response = await client.get(
                f"{self.GRAPH_API_BASE}/oauth/access_token",
                params={
                    "grant_type": "fb_exchange_token",
                    "client_id": settings.META_APP_ID,
                    "client_secret": settings.META_APP_SECRET,
                    "fb_exchange_token": user_token,
                }
            )
            long_token_data = long_token_response.json()
            access_token = long_token_data.get("access_token", user_token)
            expires_in = long_token_data.get("expires_in", 5184000)
            
            # Get user's pages
            page_info = await self._get_page_info(client, access_token)
            
            return {
                "access_token": page_info["access_token"],  # Page token, not user token
                "refresh_token": None,
                "expires_at": datetime.utcnow() + timedelta(seconds=expires_in),
                "user_id": page_info["id"],
                "username": page_info.get("name", ""),
                "display_name": page_info.get("name", ""),
                "profile_picture": page_info.get("picture", {}).get("data", {}).get("url", ""),
            }

    async def _get_page_info(
        self, 
        client: httpx.AsyncClient, 
        access_token: str
    ) -> Dict[str, Any]:
        """Get user's first Facebook Page with its token"""
        response = await client.get(
            f"{self.GRAPH_API_BASE}/me/accounts",
            params={
                "access_token": access_token,
                "fields": "id,name,access_token,picture",
            }
        )
        data = response.json()
        
        if "error" in data:
            raise Exception(f"Failed to get pages: {data['error']['message']}")
        
        if not data.get("data"):
            raise Exception("No Facebook Pages found. You need a Facebook Page to post content.")
        
        # Return the first page
        return data["data"][0]

    async def refresh_access_token(self, refresh_token: str) -> Dict[str, Any]:
        """Refresh (extend) a Facebook page token"""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.GRAPH_API_BASE}/oauth/access_token",
                params={
                    "grant_type": "fb_exchange_token",
                    "client_id": settings.META_APP_ID,
                    "client_secret": settings.META_APP_SECRET,
                    "fb_exchange_token": refresh_token,
                }
            )
            data = response.json()
            
            if "error" in data:
                raise Exception(f"Token refresh failed: {data['error']['message']}")
            
            return {
                "access_token": data["access_token"],
                "expires_at": datetime.utcnow() + timedelta(seconds=data.get("expires_in", 5184000)),
            }

    async def get_user_info(self, access_token: str) -> Dict[str, Any]:
        """Get page info"""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.GRAPH_API_BASE}/me",
                params={
                    "access_token": access_token,
                    "fields": "id,name,picture",
                }
            )
            data = response.json()
            
            if "error" in data:
                raise Exception(f"Failed to get page info: {data['error']['message']}")
            
            return {
                "user_id": data["id"],
                "username": data.get("name", ""),
                "display_name": data.get("name", ""),
                "profile_picture": data.get("picture", {}).get("data", {}).get("url", ""),
            }

    async def publish_post(
        self,
        access_token: str,
        content: str,
        media_urls: Optional[List[str]] = None,
        **kwargs
    ) -> Dict[str, Any]:
        """Publish a post to Facebook Page"""
        async with httpx.AsyncClient() as client:
            # Get page ID from the token
            page_info = await self.get_user_info(access_token)
            page_id = page_info["user_id"]
            
            if media_urls:
                # Post with photo
                return await self._publish_with_photo(
                    client, page_id, access_token, content, media_urls[0]
                )
            else:
                # Text-only post
                response = await client.post(
                    f"{self.GRAPH_API_BASE}/{page_id}/feed",
                    params={
                        "message": content,
                        "access_token": access_token,
                    }
                )
                data = response.json()
                
                if "error" in data:
                    raise Exception(f"Failed to post: {data['error']['message']}")
                
                return {
                    "post_id": data["id"],
                    "url": f"https://www.facebook.com/{data['id']}",
                }

    async def _publish_with_photo(
        self,
        client: httpx.AsyncClient,
        page_id: str,
        access_token: str,
        content: str,
        photo_url: str
    ) -> Dict[str, Any]:
        """Publish a post with photo"""
        response = await client.post(
            f"{self.GRAPH_API_BASE}/{page_id}/photos",
            params={
                "url": photo_url,
                "caption": content,
                "access_token": access_token,
            }
        )
        data = response.json()
        
        if "error" in data:
            raise Exception(f"Failed to post photo: {data['error']['message']}")
        
        return {
            "post_id": data["id"],
            "url": f"https://www.facebook.com/{page_id}/photos/{data['id']}",
        }

    async def revoke_access(self, access_token: str) -> bool:
        """Revoke access"""
        async with httpx.AsyncClient() as client:
            response = await client.delete(
                f"{self.GRAPH_API_BASE}/me/permissions",
                params={"access_token": access_token}
            )
            return response.status_code == 200
