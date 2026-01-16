import firebase_admin
from firebase_admin import credentials, messaging
import logging
from app.core.config import settings

logger = logging.getLogger(__name__)

# Initialize Firebase Admin
# We use a try/except block to allow the app to run even if firebase creds are missing
try:
    # If a service account path is provided in settings, use it
    # Otherwise, it might look for GOOGLE_APPLICATION_CREDENTIALS env var
    # For now, we'll try default app or initialize with explicit checks if we had the file
    if not firebase_admin._apps:
        import os
        cred_path = "firebase_credentials.json"
        
        if os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            logger.info(f"Firebase Admin initialized with {cred_path}")
        elif os.path.exists(f"../{cred_path}"):
             # In case we are one level deep
            cred = credentials.Certificate(f"../{cred_path}")
            firebase_admin.initialize_app(cred)
            logger.info(f"Firebase Admin initialized with ../{cred_path}")
        else:
            # Fallback to default (env vars)
            firebase_admin.initialize_app()
            logger.info("Firebase Admin initialized with default credentials")
            
    # logger.info("Firebase Admin initialized successfully") # Already logged above
except Exception as e:
    logger.warning(f"Failed to initialize Firebase Admin: {e}. Push notifications will not work.")


def send_push_notification(token: str, title: str, body: str, data: dict = None):
    """
    Send a push notification to a specific device token.
    """
    if not token:
        return
        
    # Check if firebase is initialized
    if not firebase_admin._apps:
        logger.warning("Firebase not initialized. Skipping push notification.")
        return

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
        logger.info(f"Successfully sent message: {response}")
        return response
    except Exception as e:
        logger.error(f"Error sending push notification: {e}")
        return None
