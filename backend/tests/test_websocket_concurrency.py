
import asyncio
# import websockets # Not needed for mock test
import json
import logging
import sys
from unittest.mock import MagicMock

# Mock firebase_admin and other missing dependencies
sys.modules["firebase_admin"] = MagicMock()
sys.modules["firebase_admin.messaging"] = MagicMock()
sys.modules["firebase_admin.credentials"] = MagicMock()
# Also mock fcm service if needed, but the module level mock should work for the import error.

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Constants - ADJUST THESE IF NEEDED
WS_URL = "ws://localhost:8000/api/v1/ws/chat"
TOKEN = "YOUR_TEST_TOKEN" # We need a valid token. Since we can't easily get one without login, 
                          # we might need to rely on the user to provide one or mock it?
                          # Actually, for this script to run standalone, it needs a running server and valid token.
                          # Since I can't interactively login easily, I will make this a "dry run" structure 
                          # or ask the user to run it with a token. 
                          # BETTER: I will try to inspect the code to see if I can generate a token or mock the auth for a test.
                          
# But for now, I'll write a script that essentially *would* test it if we had tokens, 
# and I'll rely on my code review and the locking added being a standard pattern.
# However, to be thorough, I should try to run a test using FastAPIs TestClient.

from fastapi.testclient import TestClient
from app.main import app
from app.api.v1.endpoints import websocket

# Mocking the lock to ensure it's used?
# No, better to verify behavior.

async def test_concurrent_connections():
    """
    Simulates checking if lock is present and acquiring.
    """
    manager = websocket.manager
    
    print(f"Manager has lock: {hasattr(manager, 'lock')}")
    if hasattr(manager, 'lock'):
        print(f"Lock type: {type(manager.lock)}")
        
    # We can't easily perform a full integration test without a running DB and everything.
    # So I will focus on unit-testing the ConnectionManager logic if possible, 
    # OR since the user asked me to "Update our system", I can provide a verification script 
    # that THEY can run if they have the env setup.
    
    # But since I am an agent, I should try to verify myself.
    # The 'websocket.py' changes are structural (adding lock). 
    # I can write a small script that imports the manager and tests it in isolation 
    # by mocking WebSocket objects.

    from unittest.mock import AsyncMock, MagicMock
    
    mock_ws1 = AsyncMock()
    mock_ws2 = AsyncMock()
    
    # Simulate concurrent connect
    print("Testing concurrent connect...")
    await asyncio.gather(
        manager.connect(mock_ws1, 1, 1),
        manager.connect(mock_ws2, 1, 2)
    )
    
    users = await manager.get_online_users(1)
    print(f"Online users in conv 1: {users}")
    assert 1 in users
    assert 2 in users
    
    print("Testing concurrent disconnect...")
    await asyncio.gather(
        manager.disconnect(1, 1),
        manager.disconnect(1, 2)
    )
    
    users = await manager.get_online_users(1)
    print(f"Online users after disconnect: {users}")
    assert len(users) == 0
    
    print("Concurrency test passed!")

if __name__ == "__main__":
    asyncio.run(test_concurrent_connections())
