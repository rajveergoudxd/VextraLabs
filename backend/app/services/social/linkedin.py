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
    API_VERSION = "202511"  # LinkedIn API version (YYYYMM) - Nov 2025
    
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

    async def get_authorization_url(self, state: str) -> Dict[str, Any]:
        """Generate LinkedIn OAuth authorization URL"""
        params = {
            "response_type": "code",
            "client_id": settings.LINKEDIN_CLIENT_ID,
            "redirect_uri": settings.LINKEDIN_REDIRECT_URI,
            "scope": " ".join(self.SCOPES),
            "state": state,
        }
        return {"url": f"{self.OAUTH_BASE}/authorization?{urlencode(params)}"}

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
        """Publish a post to LinkedIn using the REST API with image support"""
        import logging
        
        async with httpx.AsyncClient(timeout=60.0) as client:
            # Get user's URN
            user_info = await self._get_user_info(client, access_token)
            author_urn = f"urn:li:person:{user_info['sub']}"
            
            logging.info(f"Publishing to LinkedIn for author: {author_urn}")
            logging.info(f"Using LinkedIn API version: {self.API_VERSION}")
            
            # Upload images if provided
            image_urns = []
            if media_urls and len(media_urls) > 0:
                for media_url in media_urls[:1]:  # LinkedIn allows 1 image per post for basic API
                    try:
                        image_urn = await self._upload_image(client, access_token, author_urn, media_url)
                        if image_urn:
                            image_urns.append(image_urn)
                            logging.info(f"Uploaded image: {image_urn}")
                    except Exception as e:
                        logging.error(f"Failed to upload image {media_url}: {e}")
            
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
            
            # Add image content if we have uploaded images
            if image_urns:
                payload["content"] = {
                    "media": {
                        "id": image_urns[0]
                    }
                }
                logging.info(f"Post includes image: {image_urns[0]}")
            
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

    async def _upload_image(
        self, 
        client: httpx.AsyncClient, 
        access_token: str, 
        owner_urn: str, 
        image_url: str
    ) -> Optional[str]:
        """Upload an image to LinkedIn and return its URN"""
        import logging
        
        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json",
            "LinkedIn-Version": self.API_VERSION,
            "X-Restli-Protocol-Version": "2.0.0",
        }
        
        # Step 1: Initialize upload
        init_response = await client.post(
            "https://api.linkedin.com/rest/images?action=initializeUpload",
            headers=headers,
            json={
                "initializeUploadRequest": {
                    "owner": owner_urn
                }
            }
        )
        
        if init_response.status_code != 200:
            logging.error(f"LinkedIn image init failed: {init_response.text}")
            return None
        
        init_data = init_response.json()
        upload_url = init_data["value"]["uploadUrl"]
        image_urn = init_data["value"]["image"]
        
        logging.info(f"Got upload URL for image: {image_urn}")
        
        # Step 2: Download image from our GCS URL
        image_response = await client.get(image_url)
        if image_response.status_code != 200:
            logging.error(f"Failed to download image from {image_url}")
            return None
        
        image_bytes = image_response.content
        content_type = image_response.headers.get("content-type", "image/jpeg")
        
        # Step 3: Upload binary to LinkedIn
        upload_response = await client.put(
            upload_url,
            headers={
                "Authorization": f"Bearer {access_token}",
                "Content-Type": content_type,
            },
            content=image_bytes
        )
        
        if upload_response.status_code not in (200, 201):
            logging.error(f"LinkedIn image upload failed: {upload_response.status_code} - {upload_response.text}")
            return None
        
        logging.info(f"Image uploaded successfully: {image_urn}")
        return image_urn

    async def revoke_access(self, access_token: str) -> bool:
        """LinkedIn doesn't have a revocation endpoint - just delete from our DB"""
        return True

    async def check_post_exists(self, access_token: str, post_urn: str) -> bool:
        """
        Check if a post still exists on LinkedIn.
        GET https://api.linkedin.com/rest/posts/{urn}
        """
        import httpx
        from urllib.parse import quote
        
        encoded_urn = quote(post_urn)
        
        async with httpx.AsyncClient(timeout=10.0) as client:
            try:
                response = await client.get(
                    f"https://api.linkedin.com/rest/posts/{encoded_urn}",
                    headers={
                        "Authorization": f"Bearer {access_token}",
                        "LinkedIn-Version": self.API_VERSION,
                        "X-Restli-Protocol-Version": "2.0.0",
                    }
                )
                
                # If 200, it exists. If 404, it's deleted.
                if response.status_code == 200:
                    # Also check lifecycleState if available, but existence is usually enough
                    return True
                elif response.status_code == 404:
                    return False
                else:
                    # Other errors (auth, server), assume exists to avoid accidental hiding?
                    # Or act safe and assume exists.
                    # Logging would be good here.
                    return True
            except Exception:
                # Network error, assume exists
                return True
