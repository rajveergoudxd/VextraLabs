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
        # Note: You need to set GOOGLE_APPLICATION_CREDENTIALS or provide cred object
        # cred = credentials.Certificate("path/to/serviceAccountKey.json")
        # firebase_admin.initialize_app(cred)
        firebase_admin.initialize_app()
    logger.info("Firebase Admin initialized successfully")
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
