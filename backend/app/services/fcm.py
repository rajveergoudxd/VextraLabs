import firebase_admin
from firebase_admin import credentials, messaging
import logging
from app.core.config import settings
import os
from pathlib import Path

logger = logging.getLogger(__name__)

# Initialize Firebase Admin
# We use a try/except block to allow the app to run even if firebase creds are missing
_firebase_initialized = False

def _get_credentials_path():
    """Find firebase_credentials.json in various locations."""
    # Get the directory where this module is located
    module_dir = Path(__file__).parent
    
    # Possible locations for firebase_credentials.json
    possible_paths = [
        # Cloud Run secret mount path (highest priority)
        Path("/backend/firebase_credentials.json"),
        # In the backend root directory (most common for local dev)
        module_dir.parent.parent.parent / "firebase_credentials.json",
        # In the current working directory
        Path("firebase_credentials.json"),
        # One level up from cwd
        Path("../firebase_credentials.json"),
        # In the app directory
        module_dir.parent / "firebase_credentials.json",
        # Docker container common path
        Path("/code/firebase_credentials.json"),
    ]
    
    for path in possible_paths:
        if path.exists():
            logger.info(f"Found firebase credentials at: {path.absolute()}")
            return str(path.absolute())
    
    return None

try:
    if not firebase_admin._apps:
        cred_path = _get_credentials_path()
        
        if cred_path:
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            _firebase_initialized = True
            logger.info(f"Firebase Admin initialized successfully with {cred_path}")
        else:
            # Try default credentials (env var or metadata server)
            try:
                firebase_admin.initialize_app()
                _firebase_initialized = True
                logger.info("Firebase Admin initialized with default credentials")
            except Exception as e:
                logger.warning(f"Could not initialize Firebase with default credentials: {e}")
    else:
        _firebase_initialized = True
        logger.info("Firebase Admin already initialized")
except Exception as e:
    logger.error(f"Failed to initialize Firebase Admin: {e}. Push notifications will not work.")


def send_push_notification(token: str, title: str, body: str, data: dict = None):
    """
    Send a push notification to a specific device token.
    """
    if not token:
        logger.warning("No FCM token provided, skipping push notification")
        return None
        
    # Check if firebase is initialized
    if not firebase_admin._apps:
        logger.error("Firebase not initialized. Cannot send push notification.")
        return None

    logger.info(f"Sending push notification to token: {token[:20]}... Title: {title}, Body: {body[:50]}...")
    
    try:
        # ensure data is all strings
        str_data = {k: str(v) for k, v in data.items()} if data else {}
        
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=str_data,
            token=token,
        )
        
        response = messaging.send(message)
        logger.info(f"Successfully sent push notification: {response}")
        return response
    except messaging.UnregisteredError:
        logger.warning(f"FCM token is invalid/unregistered: {token[:20]}...")
        return None
    except Exception as e:
        logger.error(f"Error sending push notification: {e}")
        return None

