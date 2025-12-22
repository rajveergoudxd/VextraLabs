"""
Instagram Graph API integration for OAuth and content publishing.
Works with Business and Creator accounts only via Meta's Graph API.
"""
import httpx
from typing import Optional, Dict, Any, List
from urllib.parse import urlencode
from datetime import datetime, timedelta

from app.core.config import settings
from .base import BaseSocialService


class InstagramService(BaseSocialService):
    """Instagram/Meta Graph API integration"""
    
    GRAPH_API_BASE = "https://graph.facebook.com/v18.0"
    OAUTH_BASE = "https://www.facebook.com/v18.0/dialog/oauth"
    
    # Required scopes for Instagram posting
    SCOPES = [
        "instagram_basic",
        "instagram_content_publish",
        "pages_show_list",
        "pages_read_engagement",
    ]

    @property
    def platform_name(self) -> str:
        return "instagram"

    def get_authorization_url(self, state: str) -> str:
        """Generate Meta OAuth authorization URL"""
        params = {
            "client_id": settings.META_APP_ID,
            "redirect_uri": settings.META_REDIRECT_URI,
            "scope": ",".join(self.SCOPES),
            "response_type": "code",
            "state": state,
        }
        return f"{self.OAUTH_BASE}?{urlencode(params)}"

    async def exchange_code_for_token(
        self, 
        code: str, 
        state: str
    ) -> Dict[str, Any]:
        """Exchange code for access token and get Instagram account info"""
        async with httpx.AsyncClient() as client:
            # Step 1: Exchange code for short-lived token
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
            
            short_lived_token = token_data["access_token"]
            
            # Step 2: Exchange for long-lived token
            long_token_response = await client.get(
                f"{self.GRAPH_API_BASE}/oauth/access_token",
                params={
                    "grant_type": "fb_exchange_token",
                    "client_id": settings.META_APP_ID,
                    "client_secret": settings.META_APP_SECRET,
                    "fb_exchange_token": short_lived_token,
                }
            )
            long_token_data = long_token_response.json()
            access_token = long_token_data.get("access_token", short_lived_token)
            expires_in = long_token_data.get("expires_in", 5184000)  # Default 60 days
            
            # Step 3: Get user's Instagram Business Account
            ig_account = await self._get_instagram_account(client, access_token)
            
            return {
                "access_token": access_token,
                "refresh_token": None,  # Meta doesn't provide refresh tokens
                "expires_at": datetime.utcnow() + timedelta(seconds=expires_in),
                "user_id": ig_account["id"],
                "username": ig_account.get("username", ""),
                "display_name": ig_account.get("name", ""),
                "profile_picture": ig_account.get("profile_picture_url", ""),
            }

    async def _get_instagram_account(
        self, 
        client: httpx.AsyncClient, 
        access_token: str
    ) -> Dict[str, Any]:
        """Get the user's Instagram Business/Creator account"""
        # Get user's pages
        pages_response = await client.get(
            f"{self.GRAPH_API_BASE}/me/accounts",
            params={"access_token": access_token}
        )
        pages_data = pages_response.json()
        
        if not pages_data.get("data"):
            raise Exception("No Facebook Pages found. Instagram Business account requires a linked Facebook Page.")
        
        # Get Instagram account connected to the first page
        page = pages_data["data"][0]
        page_token = page["access_token"]
        
        ig_response = await client.get(
            f"{self.GRAPH_API_BASE}/{page['id']}",
            params={
                "fields": "instagram_business_account{id,username,name,profile_picture_url}",
                "access_token": page_token,
            }
        )
        ig_data = ig_response.json()
        
        if "instagram_business_account" not in ig_data:
            raise Exception("No Instagram Business/Creator account linked to this Facebook Page.")
        
        return ig_data["instagram_business_account"]

    async def refresh_access_token(self, refresh_token: str) -> Dict[str, Any]:
        """Meta tokens can be refreshed by exchanging the current token"""
        # Meta doesn't use refresh tokens - you exchange the current access token
        # This should be called before the token expires
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.GRAPH_API_BASE}/oauth/access_token",
                params={
                    "grant_type": "fb_exchange_token",
                    "client_id": settings.META_APP_ID,
                    "client_secret": settings.META_APP_SECRET,
                    "fb_exchange_token": refresh_token,  # Current access token
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
        """Get Instagram account info"""
        async with httpx.AsyncClient() as client:
            ig_account = await self._get_instagram_account(client, access_token)
            return {
                "user_id": ig_account["id"],
                "username": ig_account.get("username", ""),
                "display_name": ig_account.get("name", ""),
                "profile_picture": ig_account.get("profile_picture_url", ""),
            }

    async def publish_post(
        self,
        access_token: str,
        content: str,
        media_urls: Optional[List[str]] = None,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Publish to Instagram (requires at least one image).
        Instagram doesn't support text-only posts.
        """
        if not media_urls:
            raise Exception("Instagram requires at least one image to post.")
        
        async with httpx.AsyncClient() as client:
            # Get Instagram account ID
            ig_account = await self._get_instagram_account(client, access_token)
            ig_user_id = ig_account["id"]
            
            if len(media_urls) == 1:
                # Single image post
                return await self._publish_single_media(
                    client, ig_user_id, access_token, media_urls[0], content
                )
            else:
                # Carousel post
                return await self._publish_carousel(
                    client, ig_user_id, access_token, media_urls, content
                )

    async def _publish_single_media(
        self,
        client: httpx.AsyncClient,
        ig_user_id: str,
        access_token: str,
        image_url: str,
        caption: str
    ) -> Dict[str, Any]:
        """Publish a single image post"""
        # Step 1: Create media container
        container_response = await client.post(
            f"{self.GRAPH_API_BASE}/{ig_user_id}/media",
            params={
                "image_url": image_url,
                "caption": caption,
                "access_token": access_token,
            }
        )
        container_data = container_response.json()
        
        if "error" in container_data:
            raise Exception(f"Failed to create media container: {container_data['error']['message']}")
        
        creation_id = container_data["id"]
        
        # Step 2: Publish the container
        publish_response = await client.post(
            f"{self.GRAPH_API_BASE}/{ig_user_id}/media_publish",
            params={
                "creation_id": creation_id,
                "access_token": access_token,
            }
        )
        publish_data = publish_response.json()
        
        if "error" in publish_data:
            raise Exception(f"Failed to publish: {publish_data['error']['message']}")
        
        return {
            "post_id": publish_data["id"],
            "url": f"https://www.instagram.com/p/{publish_data['id']}/",
        }

    async def _publish_carousel(
        self,
        client: httpx.AsyncClient,
        ig_user_id: str,
        access_token: str,
        image_urls: List[str],
        caption: str
    ) -> Dict[str, Any]:
        """Publish a carousel post with multiple images"""
        # Create containers for each image
        container_ids = []
        for image_url in image_urls[:10]:  # Max 10 items in carousel
            container_response = await client.post(
                f"{self.GRAPH_API_BASE}/{ig_user_id}/media",
                params={
                    "image_url": image_url,
                    "is_carousel_item": "true",
                    "access_token": access_token,
                }
            )
            container_data = container_response.json()
            if "error" in container_data:
                raise Exception(f"Failed to create carousel item: {container_data['error']['message']}")
            container_ids.append(container_data["id"])
        
        # Create carousel container
        carousel_response = await client.post(
            f"{self.GRAPH_API_BASE}/{ig_user_id}/media",
            params={
                "media_type": "CAROUSEL",
                "children": ",".join(container_ids),
                "caption": caption,
                "access_token": access_token,
            }
        )
        carousel_data = carousel_response.json()
        
        if "error" in carousel_data:
            raise Exception(f"Failed to create carousel: {carousel_data['error']['message']}")
        
        # Publish
        publish_response = await client.post(
            f"{self.GRAPH_API_BASE}/{ig_user_id}/media_publish",
            params={
                "creation_id": carousel_data["id"],
                "access_token": access_token,
            }
        )
        publish_data = publish_response.json()
        
        return {
            "post_id": publish_data["id"],
            "url": f"https://www.instagram.com/p/{publish_data['id']}/",
        }

    async def revoke_access(self, access_token: str) -> bool:
        """Revoke access token"""
        async with httpx.AsyncClient() as client:
            response = await client.delete(
                f"{self.GRAPH_API_BASE}/me/permissions",
                params={"access_token": access_token}
            )
            return response.status_code == 200
