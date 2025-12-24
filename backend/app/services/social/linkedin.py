"""
LinkedIn API integration for OAuth and content publishing.
Uses the Posts API for sharing content.
"""
import httpx
from typing import Optional, Dict, Any, List
from urllib.parse import urlencode
from datetime import datetime, timedelta

from app.core.config import settings
from .base import BaseSocialService


class LinkedInService(BaseSocialService):
    """LinkedIn API integration"""
    
    API_BASE = "https://api.linkedin.com/v2"
    OAUTH_BASE = "https://www.linkedin.com/oauth/v2"
    API_VERSION = "202401"  # LinkedIn API version header
    
    # Required scopes for posting to profile
    SCOPES = [
        "openid",
        "profile",
        "email",
        "w_member_social",
    ]

    @property
    def platform_name(self) -> str:
        return "linkedin"

    def get_authorization_url(self, state: str) -> str:
        """Generate LinkedIn OAuth authorization URL"""
        params = {
            "response_type": "code",
            "client_id": settings.LINKEDIN_CLIENT_ID,
            "redirect_uri": settings.LINKEDIN_REDIRECT_URI,
            "scope": " ".join(self.SCOPES),
            "state": state,
        }
        return f"{self.OAUTH_BASE}/authorization?{urlencode(params)}"

    async def exchange_code_for_token(
        self, 
        code: str, 
        state: str
    ) -> Dict[str, Any]:
        """Exchange authorization code for access token"""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{self.OAUTH_BASE}/accessToken",
                headers={"Content-Type": "application/x-www-form-urlencoded"},
                data={
                    "grant_type": "authorization_code",
                    "code": code,
                    "redirect_uri": settings.LINKEDIN_REDIRECT_URI,
                    "client_id": settings.LINKEDIN_CLIENT_ID,
                    "client_secret": settings.LINKEDIN_CLIENT_SECRET,
                }
            )
            
            data = response.json()
            
            if "error" in data:
                raise Exception(f"Token exchange failed: {data.get('error_description', data['error'])}")
            
            access_token = data["access_token"]
            expires_in = data.get("expires_in", 5184000)  # Default 60 days
            
            # Get user info
            user_info = await self._get_user_info(client, access_token)
            
            return {
                "access_token": access_token,
                "refresh_token": data.get("refresh_token"),  # Usually not provided
                "expires_at": datetime.utcnow() + timedelta(seconds=expires_in),
                "user_id": user_info["sub"],
                "username": user_info.get("name", user_info.get("email", "")),  # Prefer name over email
                "display_name": user_info.get("name", ""),
                "profile_picture": user_info.get("picture", ""),
            }

    async def _get_user_info(
        self, 
        client: httpx.AsyncClient, 
        access_token: str
    ) -> Dict[str, Any]:
        """Get authenticated user info using OpenID Connect"""
        response = await client.get(
            "https://api.linkedin.com/v2/userinfo",
            headers={"Authorization": f"Bearer {access_token}"}
        )
        data = response.json()
        
        if "error" in data:
            raise Exception(f"Failed to get user info: {data.get('error_description', data['error'])}")
        
        return data

    async def refresh_access_token(self, refresh_token: str) -> Dict[str, Any]:
        """
        LinkedIn doesn't provide refresh tokens by default.
        Users must reauthorize when token expires (60 days).
        """
        raise Exception("LinkedIn does not support token refresh. User must reauthorize.")

    async def get_user_info(self, access_token: str) -> Dict[str, Any]:
        """Get user info"""
        async with httpx.AsyncClient() as client:
            user = await self._get_user_info(client, access_token)
            return {
                "user_id": user["sub"],
                "username": user.get("email", ""),
                "display_name": user.get("name", ""),
                "profile_picture": user.get("picture", ""),
            }

    async def publish_post(
        self,
        access_token: str,
        content: str,
        media_urls: Optional[List[str]] = None,
        **kwargs
    ) -> Dict[str, Any]:
        """Publish a post to LinkedIn using the REST API"""
        import logging
        
        async with httpx.AsyncClient() as client:
            # Get user's URN
            user_info = await self._get_user_info(client, access_token)
            author_urn = f"urn:li:person:{user_info['sub']}"
            
            logging.info(f"Publishing to LinkedIn for author: {author_urn}")
            
            # Build post payload for REST API
            payload = {
                "author": author_urn,
                "commentary": content,
                "visibility": "PUBLIC",
                "distribution": {
                    "feedDistribution": "MAIN_FEED",
                    "targetEntities": [],
                    "thirdPartyDistributionChannels": []
                },
                "lifecycleState": "PUBLISHED",
                "isReshareDisabledByAuthor": False,
            }
            
            # Add media if provided (images as external URLs)
            if media_urls and len(media_urls) > 0:
                # For now, share first image as article/link preview
                # Full image posting requires LinkedIn's image upload flow
                logging.info(f"Media URLs provided: {media_urls}")
            
            # Use the REST API endpoint (not v2)
            response = await client.post(
                "https://api.linkedin.com/rest/posts",
                headers={
                    "Authorization": f"Bearer {access_token}",
                    "Content-Type": "application/json",
                    "LinkedIn-Version": self.API_VERSION,
                    "X-Restli-Protocol-Version": "2.0.0",
                },
                json=payload
            )
            
            logging.info(f"LinkedIn API response status: {response.status_code}")
            
            if response.status_code not in (200, 201):
                error_text = response.text if response.content else "No response body"
                logging.error(f"LinkedIn post failed: {error_text}")
                try:
                    error_data = response.json()
                except:
                    error_data = {"message": error_text}
                raise Exception(f"LinkedIn API error: {error_data.get('message', error_text)}")
            
            # LinkedIn returns the post URN in the header
            post_urn = response.headers.get("x-restli-id", "")
            logging.info(f"LinkedIn post created successfully: {post_urn}")
            
            return {
                "post_id": post_urn,
                "url": f"https://www.linkedin.com/feed/update/{post_urn}/",
            }

    async def revoke_access(self, access_token: str) -> bool:
        """LinkedIn doesn't have a revocation endpoint - just delete from our DB"""
        return True
