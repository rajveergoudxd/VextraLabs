import os
import json
import asyncio
import logging
from typing import Optional, Callable, Awaitable
from redis import asyncio as aioredis

logger = logging.getLogger(__name__)

class RedisManager:
    """
    Manages Redis connection and Pub/Sub for real-time chat.
    Singleton pattern recommended for usage.
    """
    def __init__(self, redis_url: str = None):
        # Default to localhost if not set, typical for docker-compose with service name 'redis'
        self.redis_url = redis_url or os.getenv("REDIS_URL", "redis://localhost:6379/0")
        self.redis: Optional[aioredis.Redis] = None
        self.pubsub = None

    async def connect(self):
        """Establish connection to Redis."""
        if not self.redis:
            try:
                self.redis = aioredis.from_url(
                    self.redis_url, 
                    encoding="utf-8", 
                    decode_responses=True
                )
                # Test connection
                await self.redis.ping()
                logger.info(f"Connected to Redis at {self.redis_url}")
            except Exception as e:
                logger.error(f"Failed to connect to Redis: {e}")
                raise

    async def close(self):
        """Close connection."""
        if self.redis:
            await self.redis.close()
            logger.info("Redis connection closed")

    async def publish(self, channel: str, message: dict):
        """Publish a message to a channel."""
        if not self.redis:
            await self.connect()
        try:
            await self.redis.publish(channel, json.dumps(message))
        except Exception as e:
            logger.error(f"Error publishing to {channel}: {e}")

    async def subscribe(self, channel: str, callback: Callable[[dict], Awaitable[None]]):
        """
        Subscribe to a channel and run callback for each message.
        NOTE: This blocks the consumer loop, so typically run this in a background task
        or use the reader pattern.
        """
        if not self.redis:
            await self.connect()
            
        pubsub = self.redis.pubsub()
        await pubsub.subscribe(channel)
        
        try:
            async for message in pubsub.listen():
                if message["type"] == "message":
                    data = json.loads(message["data"])
                    await callback(data)
        except Exception as e:
            logger.error(f"Error in subscription loop for {channel}: {e}")
        finally:
            await pubsub.unsubscribe(channel)

    def get_redis(self) -> aioredis.Redis:
        """Get raw redis client."""
        return self.redis

# Global instance
redis_manager = RedisManager()
