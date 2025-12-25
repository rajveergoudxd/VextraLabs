"""
Base class for social platform services.
Defines common interface for OAuth and publishing.
"""
from abc import ABC, abstractmethod
from typing import Optional, Dict, Any, List
from datetime import datetime


class BaseSocialService(ABC):
    """Abstract base class for social platform integrations"""
    
    @property
    @abstractmethod
    def platform_name(self) -> str:
        """Return the platform name (e.g., 'instagram', 'twitter')"""
        pass

    @abstractmethod
    async def get_authorization_url(self, state: str) -> Dict[str, Any]:
        """
        Generate the OAuth authorization URL for user consent.
        
        Args:
            state: Random state parameter for CSRF protection
            
        Returns:
            The full authorization URL to redirect the user to
        """
        pass

    @abstractmethod
    async def exchange_code_for_token(
        self, 
        code: str, 
        state: str
    ) -> Dict[str, Any]:
        """
        Exchange authorization code for access tokens.
        
        Args:
            code: The authorization code from OAuth callback
            state: The state parameter for verification
            
        Returns:
            Dict containing access_token, refresh_token (if available),
            expires_at, user_id, username, etc.
        """
        pass

    @abstractmethod
    async def refresh_access_token(
        self, 
        refresh_token: str
    ) -> Dict[str, Any]:
        """
        Refresh an expired access token.
        
        Args:
            refresh_token: The refresh token
            
        Returns:
            Dict containing new access_token, expires_at, etc.
        """
        pass

    @abstractmethod
    async def get_user_info(
        self, 
        access_token: str
    ) -> Dict[str, Any]:
        """
        Get the authenticated user's profile info.
        
        Args:
            access_token: Valid access token
            
        Returns:
            Dict containing user_id, username, display_name, profile_picture, etc.
        """
        pass

    @abstractmethod
    async def publish_post(
        self,
        access_token: str,
        content: str,
        media_urls: Optional[List[str]] = None,
        **kwargs
    ) -> Dict[str, Any]:
        """
        Publish a post to the platform.
        
        Args:
            access_token: Valid access token
            content: The text content of the post
            media_urls: Optional list of media URLs to attach
            **kwargs: Platform-specific options
            
        Returns:
            Dict containing post_id, url, etc.
        """
        pass

    @abstractmethod
    async def revoke_access(self, access_token: str) -> bool:
        """
        Revoke the access token (disconnect).
        
        Args:
            access_token: The access token to revoke
            
        Returns:
            True if successful
        """
        pass

    def is_token_expired(self, expires_at: Optional[datetime]) -> bool:
        """Check if a token has expired"""
        if expires_at is None:
            return False
        return datetime.utcnow() >= expires_at
