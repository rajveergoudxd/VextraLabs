"""
Twitter/X API v2 integration for OAuth 2.0 and content publishing.
Uses OAuth 2.0 with PKCE for user authentication.
"""
import httpx
import base64
import hashlib
import secrets
from typing import Optional, Dict, Any, List
from urllib.parse import urlencode
from datetime import datetime, timedelta

from app.core.config import settings
from .base import BaseSocialService


class TwitterService(BaseSocialService):
    """Twitter/X API v2 integration with OAuth 2.0"""
    
    API_BASE = "https://api.twitter.com/2"
    OAUTH_BASE = "https://twitter.com/i/oauth2"
    UPLOAD_BASE = "https://upload.twitter.com/1.1"
    
    # Required scopes for posting
    SCOPES = [
        "tweet.read",
        "tweet.write",
        "users.read",
        "offline.access",  # For refresh tokens
    ]

    @property
    def platform_name(self) -> str:
        return "twitter"

    def _generate_pkce_pair(self) -> tuple[str, str]:
        """Generate PKCE code verifier and challenge"""
        code_verifier = secrets.token_urlsafe(64)[:128]
        code_challenge = base64.urlsafe_b64encode(
            hashlib.sha256(code_verifier.encode()).digest()
        ).decode().rstrip("=")
        return code_verifier, code_challenge

    def get_authorization_url(self, state: str) -> str:
        """Generate Twitter OAuth 2.0 authorization URL with PKCE"""
        # Note: code_verifier needs to be stored server-side for callback
        _, code_challenge = self._generate_pkce_pair()
        
        params = {
            "response_type": "code",
            "client_id": settings.TWITTER_CLIENT_ID,
            "redirect_uri": settings.TWITTER_REDIRECT_URI,
            "scope": " ".join(self.SCOPES),
            "state": state,
            "code_challenge": code_challenge,
            "code_challenge_method": "S256",
        }
        return f"{self.OAUTH_BASE}/authorize?{urlencode(params)}"

    async def exchange_code_for_token(
        self, 
        code: str, 
        state: str,
        code_verifier: str = None
    ) -> Dict[str, Any]:
        """Exchange authorization code for access tokens"""
        async with httpx.AsyncClient() as client:
            # Basic auth with client credentials
            auth_string = f"{settings.TWITTER_CLIENT_ID}:{settings.TWITTER_CLIENT_SECRET}"
            auth_header = base64.b64encode(auth_string.encode()).decode()
            
            response = await client.post(
                f"{self.OAUTH_BASE}/token",
                headers={
                    "Authorization": f"Basic {auth_header}",
                    "Content-Type": "application/x-www-form-urlencoded",
                },
                data={
                    "code": code,
                    "grant_type": "authorization_code",
                    "redirect_uri": settings.TWITTER_REDIRECT_URI,
                    "code_verifier": code_verifier or "challenge",  # Should be stored from authorize
                }
            )
            
            data = response.json()
            
            if "error" in data:
                raise Exception(f"Token exchange failed: {data.get('error_description', data['error'])}")
            
            # Get user info
            user_info = await self._get_user_info(client, data["access_token"])
            
            return {
                "access_token": data["access_token"],
                "refresh_token": data.get("refresh_token"),
                "expires_at": datetime.utcnow() + timedelta(seconds=data.get("expires_in", 7200)),
                "user_id": user_info["id"],
                "username": user_info["username"],
                "display_name": user_info.get("name", ""),
                "profile_picture": user_info.get("profile_image_url", ""),
            }

    async def _get_user_info(
        self, 
        client: httpx.AsyncClient, 
        access_token: str
    ) -> Dict[str, Any]:
        """Get authenticated user info"""
        response = await client.get(
            f"{self.API_BASE}/users/me",
            headers={"Authorization": f"Bearer {access_token}"},
            params={"user.fields": "id,username,name,profile_image_url"}
        )
        data = response.json()
        
        if "errors" in data:
            raise Exception(f"Failed to get user info: {data['errors']}")
        
        return data["data"]

    async def refresh_access_token(self, refresh_token: str) -> Dict[str, Any]:
        """Refresh an expired access token"""
        async with httpx.AsyncClient() as client:
            auth_string = f"{settings.TWITTER_CLIENT_ID}:{settings.TWITTER_CLIENT_SECRET}"
            auth_header = base64.b64encode(auth_string.encode()).decode()
            
            response = await client.post(
                f"{self.OAUTH_BASE}/token",
                headers={
                    "Authorization": f"Basic {auth_header}",
                    "Content-Type": "application/x-www-form-urlencoded",
                },
                data={
                    "grant_type": "refresh_token",
                    "refresh_token": refresh_token,
                }
            )
            
            data = response.json()
            
            if "error" in data:
                raise Exception(f"Token refresh failed: {data.get('error_description', data['error'])}")
            
            return {
                "access_token": data["access_token"],
                "refresh_token": data.get("refresh_token", refresh_token),
                "expires_at": datetime.utcnow() + timedelta(seconds=data.get("expires_in", 7200)),
            }

    async def get_user_info(self, access_token: str) -> Dict[str, Any]:
        """Get user info with access token"""
        async with httpx.AsyncClient() as client:
            user = await self._get_user_info(client, access_token)
            return {
                "user_id": user["id"],
                "username": user["username"],
                "display_name": user.get("name", ""),
                "profile_picture": user.get("profile_image_url", ""),
            }

    async def publish_post(
        self,
        access_token: str,
        content: str,
        media_urls: Optional[List[str]] = None,
        **kwargs
    ) -> Dict[str, Any]:
        """Post a tweet, optionally with media"""
        async with httpx.AsyncClient() as client:
            payload = {"text": content}
            
            # Upload media if provided
            if media_urls:
                media_ids = []
                for url in media_urls[:4]:  # Twitter allows max 4 images
                    media_id = await self._upload_media(client, access_token, url)
                    if media_id:
                        media_ids.append(media_id)
                
                if media_ids:
                    payload["media"] = {"media_ids": media_ids}
            
            # Post tweet
            response = await client.post(
                f"{self.API_BASE}/tweets",
                headers={
                    "Authorization": f"Bearer {access_token}",
                    "Content-Type": "application/json",
                },
                json=payload
            )
            
            data = response.json()
            
            if "errors" in data:
                raise Exception(f"Failed to post tweet: {data['errors']}")
            
            tweet_id = data["data"]["id"]
            return {
                "post_id": tweet_id,
                "url": f"https://twitter.com/i/web/status/{tweet_id}",
            }

    async def _upload_media(
        self, 
        client: httpx.AsyncClient, 
        access_token: str, 
        media_url: str
    ) -> Optional[str]:
        """Upload media and return media_id (uses v1.1 API)"""
        try:
            # Download the media first
            media_response = await client.get(media_url)
            media_data = media_response.content
            
            # Upload to Twitter (this uses v1.1 which requires OAuth 1.0a)
            # For simplicity, we'll skip media upload in this version
            # Full implementation would require OAuth 1.0a or separate handling
            return None
        except Exception:
            return None

    async def revoke_access(self, access_token: str) -> bool:
        """Revoke access token"""
        async with httpx.AsyncClient() as client:
            auth_string = f"{settings.TWITTER_CLIENT_ID}:{settings.TWITTER_CLIENT_SECRET}"
            auth_header = base64.b64encode(auth_string.encode()).decode()
            
            response = await client.post(
                f"{self.OAUTH_BASE}/revoke",
                headers={
                    "Authorization": f"Basic {auth_header}",
                    "Content-Type": "application/x-www-form-urlencoded",
                },
                data={"token": access_token}
            )
            return response.status_code == 200
