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
    """Twitter/X API integration using OAuth 1.0a (User Context)"""
    
    API_BASE = "https://api.twitter.com/2"
    UPLOAD_BASE = "https://upload.twitter.com/1.1"
    OAUTH_BASE = "https://api.twitter.com/oauth"
    
    @property
    def platform_name(self) -> str:
        return "twitter"

    def _get_oauth_header(
        self, 
        method: str, 
        url: str, 
        params: Dict[str, str],
        access_token: Optional[str] = None,
        access_token_secret: Optional[str] = None
    ) -> str:
        """Generate OAuth 1.0a Authorization header"""
        import hmac, hashlib, time, uuid
        from urllib.parse import quote
        
        # Helper for strict RFC 3986 encoding
        def percent_encode(s: str) -> str:
            return quote(str(s), safe='~')
            
        oauth_params = {
            "oauth_consumer_key": settings.TWITTER_API_KEY,
            "oauth_nonce": uuid.uuid4().hex,
            "oauth_signature_method": "HMAC-SHA1",
            "oauth_timestamp": str(int(time.time())),
            "oauth_version": "1.0",
        }
        
        if access_token:
            oauth_params["oauth_token"] = access_token
            
        # Merge extra params for signature
        all_params = {**oauth_params, **params}
        
        # Sort and encode
        encoded_params = []
        for k, v in sorted(all_params.items()):
            encoded_params.append(f"{percent_encode(k)}={percent_encode(v)}")
            
        param_string = "&".join(encoded_params)
        
        # Base string
        base_string = f"{method.upper()}&{percent_encode(url)}&{percent_encode(param_string)}"
        
        # Signing key
        signing_key = f"{percent_encode(settings.TWITTER_API_KEY_SECRET)}&"
        if access_token_secret:
            signing_key += percent_encode(access_token_secret)
            
        # Calculate signature
        signature = hmac.new(
            signing_key.encode(),
            base_string.encode(),
            hashlib.sha1
        ).digest()
        
        oauth_params["oauth_signature"] = base64.b64encode(signature).decode()
        
        # Header - Only include oauth_ params (plus realm if needed, but usually not)
        # Note: If params contained 'oauth_callback', it SHOULD be in the header usually.
        # So we merge params into header dict if they start with oauth_
        header_params = oauth_params.copy()
        for k, v in params.items():
            if k.startswith("oauth_"):
                header_params[k] = v
        
        header_parts = [f'{percent_encode(k)}="{percent_encode(v)}"' for k, v in sorted(header_params.items())]
        return "OAuth " + ", ".join(header_parts)

    async def get_authorization_url(self, state: str) -> Dict[str, Any]:
        """Get Request Token and return Authorize URL"""
        url = f"{self.OAUTH_BASE}/request_token"
        
        # Callback URL (from config)
        callback = settings.TWITTER_REDIRECT_URI
        params = {"oauth_callback": callback}
        
        header = self._get_oauth_header("POST", url, params)
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                url, 
                headers={
                    "Authorization": header,
                    "Content-Type": "application/x-www-form-urlencoded"
                }
                # Do not pass params=params, as oauth_callback is already in the header
            )
            
            if response.status_code != 200:
                raise Exception(f"Failed to get request token: {response.text}")
                
            data = dict(x.split("=") for x in response.text.split("&"))
            oauth_token = data["oauth_token"]
            oauth_token_secret = data["oauth_token_secret"]
            
            return {
                "url": f"{self.OAUTH_BASE}/authorize?oauth_token={oauth_token}",
                "oauth_token": oauth_token,
                "oauth_token_secret": oauth_token_secret
            }

    async def exchange_code_for_token(
        self, 
        code: str, 
        state: str,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Exchange verifier for Access Token.
        In OAuth 1.0a:
        code -> oauth_verifier
        state -> we expect 'oauth_token' and 'oauth_token_secret' inside state (handled by oauth.py)
        But wait, OAUTH_STATES in oauth.py stores metadata. I need to store secret there.
        """
        oauth_verifier = kwargs.get("oauth_verifier") or code
        oauth_token = kwargs.get("oauth_token")
        
        # We need the temp secret. It should be passed in via kwargs or state logic?
        # oauth.py doesn't pass secret. I need to modify oauth.py to store/retrieve it.
        # For now let's assume I modify oauth.py to pass 'oauth_token_secret' if it's there.
        request_token_secret = kwargs.get("request_secret")
        
        if not oauth_verifier or not request_token_secret:
             raise Exception("Missing verifier or secret for OAuth 1.0a")

        url = f"{self.OAUTH_BASE}/access_token"
        params = {"oauth_verifier": oauth_verifier}
        
        # Sign with Request Token Secret
        header = self._get_oauth_header(
            "POST", url, params, 
            access_token=oauth_token, 
            access_token_secret=request_token_secret
        )
        
        async with httpx.AsyncClient() as client:
            response = await client.post(url, headers={"Authorization": header}, params=params)
            
            if response.status_code != 200:
                raise Exception(f"Failed to get access token: {response.text}")
                
            data = dict(x.split("=") for x in response.text.split("&"))
            
            return {
                "access_token": f"{data['oauth_token']}:{data['oauth_token_secret']}",
                "refresh_token": data["oauth_token_secret"], # Backup
                "expires_at": None, # Never expires
                "user_id": data["user_id"],
                "username": data["screen_name"],
                "display_name": data["screen_name"],
                "profile_picture": "", # Need separate call to verify_credentials to get this
            }
            
    async def get_user_info(self, access_token: str) -> Dict[str, Any]:
        """Get user info with access token"""
        if ":" in access_token:
            token, secret = access_token.split(":", 1)
        else:
            # Fallback if somehow we have legacy token, though new impl forces combined
            raise Exception("Invalid OAuth 1.0a token format. Expected 'token:secret'.")
            
        async with httpx.AsyncClient() as client:
            user = await self._get_user_info(client, token, secret)
            return {
                "user_id": user["id"],
                "username": user["username"],
                "display_name": user.get("name", ""),
                "profile_picture": user.get("profile_image_url", ""),
            }

    async def _get_user_info(
        self, 
        client: httpx.AsyncClient, 
        access_token: str,
        access_token_secret: str
    ) -> Dict[str, Any]:
        """Internal get user info"""
        url = f"{self.API_BASE}/users/me"
        params = {"user.fields": "id,username,name,profile_image_url"}
        
        header = self._get_oauth_header("GET", url, params, 
                                        access_token=access_token, 
                                        access_token_secret=access_token_secret)
        
        response = await client.get(url, headers={"Authorization": header}, params=params)
        data = response.json()
        
        if "data" not in data:
            raise Exception(f"Failed to get user info: {data}")
            
        return data["data"]

    async def refresh_access_token(self, refresh_token: str) -> Dict[str, Any]:
        """OAuth 1.0a tokens don't expire"""
        return {
            "access_token": "token_placeholder", # We don't refresh
            "expires_at": None
        }

    async def publish_post(
        self,
        access_token: str,
        content: str,
        media_urls: Optional[List[str]] = None,
        **kwargs
    ) -> Dict[str, Any]:
        """Publish post with OAuth 1.0a"""
        # Untangle token:secret
        if ":" in access_token:
            token, secret = access_token.split(":", 1)
        else:
            raise Exception("Invalid OAuth 1.0a token format. Expected 'token:secret'.")

        async with httpx.AsyncClient() as client:
            media_ids = []
            if media_urls:
                for url in media_urls[:4]:
                    media_id = await self._upload_media(client, token, secret, url)
                    if media_id:
                        media_ids.append(media_id)
            
            # Post tweet (v2)
            url = f"{self.API_BASE}/tweets"
            payload = {"text": content}
            if media_ids:
                payload["media"] = {"media_ids": media_ids}
            
            # For v2 POST with JSON, signature is tricky. 
            # OAuth 1.0a spec says body parameters are NOT included in signature if Content-Type is not form-urlencoded.
            # v2 uses JSON. So we sign only the URL/query params.
            # The body is NOT signed.
            
            header = self._get_oauth_header("POST", url, {}, token, secret)
            
            response = await client.post(
                url, 
                headers={
                    "Authorization": header,
                    "Content-Type": "application/json"
                },
                json=payload
            )
            
            data = response.json()
            
            if "errors" in data:
                raise Exception(f"Failed to post: {data['errors']}")
                
            return {
                "post_id": data["data"]["id"],
                "url": f"https://twitter.com/i/web/status/{data['data']['id']}"
            }

    async def _upload_media(
        self, 
        client: httpx.AsyncClient, 
        access_token: str, 
        access_token_secret: str,
        media_url: str
    ) -> Optional[str]:
        """Upload media (v1.1)"""
        # Download media
        media_resp = await client.get(media_url)
        media_data = media_resp.content
        
        url = f"{self.UPLOAD_BASE}/media/upload.json"
        
        # INIT
        params = {
            "command": "INIT",
            "total_bytes": str(len(media_data)),
            "media_type": media_resp.headers.get("content-type", "image/jpeg")
        }
        header = self._get_oauth_header("POST", url, params, access_token, access_token_secret)
        
        resp = await client.post(url, headers={"Authorization": header}, data=params)
        media_id = resp.json()["media_id_string"]
        
        # APPEND
        # Uploading binary data is complex with OAuth 1.0a + multipart/form-data.
        # But Twitter allows raw body or multipart.
        # The signature only includes oauth params + query params.
        # Multipart body is not signed.
        
        url = f"{self.UPLOAD_BASE}/media/upload.json"
        params = {
            "command": "APPEND",
            "media_id": media_id,
            "segment_index": "0"
        }
        # For APPEND, the media is in body 'media' field.
        # Signature covers command, media_id, segment_index.
        header = self._get_oauth_header("POST", url, params, access_token, access_token_secret)
        
        files = {"media": media_data}
        resp = await client.post(
            url, 
            headers={"Authorization": header}, 
            data=params, 
            files=files
        )
        
        if resp.status_code not in (200, 204):
            return None
            
        # FINALIZE
        params = {"command": "FINALIZE", "media_id": media_id}
        header = self._get_oauth_header("POST", url, params, access_token, access_token_secret)
        resp = await client.post(url, headers={"Authorization": header}, data=params)
        
        return media_id

    async def revoke_access(self, access_token: str) -> bool:
        """Revoke not supported via API for 1.0a easily, assume success"""
        return True

