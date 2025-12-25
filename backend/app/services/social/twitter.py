"""
Twitter/X API v2 integration using OAuth 2.0 with PKCE.
For Free tier access - supports text-only tweets via v2 API.
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
    """Twitter/X API v2 integration using OAuth 2.0 with PKCE (Free Tier)"""
    
    API_BASE = "https://api.twitter.com/2"
    OAUTH_AUTHORIZE = "https://twitter.com/i/oauth2/authorize"
    OAUTH_TOKEN = "https://api.twitter.com/2/oauth2/token"
    
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
        """Generate PKCE code_verifier and code_challenge"""
        # Generate a random code_verifier (43-128 characters)
        code_verifier = secrets.token_urlsafe(32)
        
        # Generate code_challenge using SHA256
        code_challenge = base64.urlsafe_b64encode(
            hashlib.sha256(code_verifier.encode()).digest()
        ).decode().rstrip("=")
        
        return code_verifier, code_challenge

    async def get_authorization_url(self, state: str) -> Dict[str, Any]:
        """Generate OAuth 2.0 authorization URL with PKCE"""
        code_verifier, code_challenge = self._generate_pkce_pair()
        
        # Get credentials
        client_id = str(settings.TWITTER_CLIENT_ID).strip().strip("'").strip('"')
        redirect_uri = str(settings.TWITTER_REDIRECT_URI).strip().strip("'").strip('"')
        
        params = {
            "response_type": "code",
            "client_id": client_id,
            "redirect_uri": redirect_uri,
            "scope": " ".join(self.SCOPES),
            "state": state,
            "code_challenge": code_challenge,
            "code_challenge_method": "S256",
        }
        
        authorization_url = f"{self.OAUTH_AUTHORIZE}?{urlencode(params)}"
        
        return {
            "url": authorization_url,
            "code_verifier": code_verifier,  # Must be stored for token exchange
        }

    async def exchange_code_for_token(
        self, 
        code: str, 
        state: str,
        **kwargs
    ) -> Dict[str, Any]:
        """Exchange authorization code for access token"""
        code_verifier = kwargs.get("code_verifier") or kwargs.get("request_secret")
        
        if not code_verifier:
            raise Exception("Missing code_verifier for PKCE flow")
        
        # Get credentials
        client_id = str(settings.TWITTER_CLIENT_ID).strip().strip("'").strip('"')
        client_secret = str(settings.TWITTER_CLIENT_SECRET).strip().strip("'").strip('"')
        redirect_uri = str(settings.TWITTER_REDIRECT_URI).strip().strip("'").strip('"')
        
        # Prepare token request
        data = {
            "code": code,
            "grant_type": "authorization_code",
            "client_id": client_id,
            "redirect_uri": redirect_uri,
            "code_verifier": code_verifier,
        }
        
        # Basic auth header
        credentials = f"{client_id}:{client_secret}"
        basic_auth = base64.b64encode(credentials.encode()).decode()
        
        headers = {
            "Content-Type": "application/x-www-form-urlencoded",
            "Authorization": f"Basic {basic_auth}",
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                self.OAUTH_TOKEN,
                data=data,
                headers=headers,
            )
            
            if response.status_code != 200:
                raise Exception(f"Token exchange failed: {response.text}")
            
            token_data = response.json()
            
            # Get user info
            user_info = await self._get_user_info(
                client, 
                token_data["access_token"]
            )
            
            # Calculate expiry
            expires_at = None
            if "expires_in" in token_data:
                expires_at = datetime.utcnow() + timedelta(seconds=token_data["expires_in"])
            
            return {
                "access_token": token_data["access_token"],
                "refresh_token": token_data.get("refresh_token", ""),
                "expires_at": expires_at,
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
        """Get user info from Twitter API"""
        url = f"{self.API_BASE}/users/me"
        params = {"user.fields": "id,username,name,profile_image_url"}
        
        headers = {"Authorization": f"Bearer {access_token}"}
        
        response = await client.get(url, headers=headers, params=params)
        data = response.json()
        
        if "data" not in data:
            raise Exception(f"Failed to get user info: {data}")
        
        return data["data"]

    async def get_user_info(self, access_token: str) -> Dict[str, Any]:
        """Get user info (public method)"""
        async with httpx.AsyncClient() as client:
            user = await self._get_user_info(client, access_token)
            return {
                "user_id": user["id"],
                "username": user["username"],
                "display_name": user.get("name", ""),
                "profile_picture": user.get("profile_image_url", ""),
            }

    async def refresh_access_token(self, refresh_token: str) -> Dict[str, Any]:
        """Refresh the access token"""
        client_id = str(settings.TWITTER_CLIENT_ID).strip().strip("'").strip('"')
        client_secret = str(settings.TWITTER_CLIENT_SECRET).strip().strip("'").strip('"')
        
        data = {
            "refresh_token": refresh_token,
            "grant_type": "refresh_token",
            "client_id": client_id,
        }
        
        credentials = f"{client_id}:{client_secret}"
        basic_auth = base64.b64encode(credentials.encode()).decode()
        
        headers = {
            "Content-Type": "application/x-www-form-urlencoded",
            "Authorization": f"Basic {basic_auth}",
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                self.OAUTH_TOKEN,
                data=data,
                headers=headers,
            )
            
            if response.status_code != 200:
                raise Exception(f"Token refresh failed: {response.text}")
            
            token_data = response.json()
            
            expires_at = None
            if "expires_in" in token_data:
                expires_at = datetime.utcnow() + timedelta(seconds=token_data["expires_in"])
            
            return {
                "access_token": token_data["access_token"],
                "refresh_token": token_data.get("refresh_token", refresh_token),
                "expires_at": expires_at,
            }

    async def publish_post(
        self,
        access_token: str,
        content: str,
        media_urls: Optional[List[str]] = None,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Publish a tweet using v2 API.
        
        Note: Free tier does NOT support media uploads via v2 API.
        Media requires Basic tier ($100/month) or higher.
        """
        url = f"{self.API_BASE}/tweets"
        
        # Text-only tweet (Free tier limitation)
        payload = {"text": content}
        
        # Note: Media uploads are NOT available on Free tier
        if media_urls:
            # Log warning but continue with text-only
            print("WARNING: Media uploads not supported on Twitter Free tier. Posting text only.")
        
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(url, json=payload, headers=headers)
            data = response.json()
            
            if response.status_code != 201:
                error_msg = data.get("detail", data.get("errors", str(data)))
                raise Exception(f"Failed to post tweet: {error_msg}")
            
            tweet_id = data["data"]["id"]
            
            return {
                "post_id": tweet_id,
                "url": f"https://twitter.com/i/web/status/{tweet_id}",
            }

    async def revoke_access(self, access_token: str) -> bool:
        """Revoke access token"""
        client_id = str(settings.TWITTER_CLIENT_ID).strip().strip("'").strip('"')
        client_secret = str(settings.TWITTER_CLIENT_SECRET).strip().strip("'").strip('"')
        
        credentials = f"{client_id}:{client_secret}"
        basic_auth = base64.b64encode(credentials.encode()).decode()
        
        headers = {
            "Content-Type": "application/x-www-form-urlencoded",
            "Authorization": f"Basic {basic_auth}",
        }
        
        data = {
            "token": access_token,
            "token_type_hint": "access_token",
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://api.twitter.com/2/oauth2/revoke",
                data=data,
                headers=headers,
            )
            
            return response.status_code == 200
