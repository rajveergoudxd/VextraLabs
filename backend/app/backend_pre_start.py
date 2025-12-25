import logging
from tenacity import after_log, before_log, retry, stop_after_attempt, wait_fixed
from app.db.session import SessionLocal, engine
from app.db.base import Base
from sqlalchemy import text

# Import all models so Base.metadata has them registered
from app.models.user import User
from app.models.otp import OTP
from app.models.settings import UserSettings
from app.models.social_connection import SocialConnection
from app.models.follow import Follow
from app.models.conversation import Conversation, ConversationParticipant
from app.models.message import Message
from app.models.post import Post
from app.models.notification import Notification
from app.models.like import Like
from app.models.comment import Comment
from app.models.saved_post import SavedPost

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

max_tries = 60 * 5  # 5 minutes
wait_seconds = 1

@retry(
    stop=stop_after_attempt(max_tries),
    wait=wait_fixed(wait_seconds),
    before=before_log(logger, logging.INFO),
    after=after_log(logger, logging.WARN),
)
def init() -> None:
    try:
        db = SessionLocal()
        # Try to create session to check if DB is awake
        db.execute(text("SELECT 1"))
        db.close()
    except Exception as e:
        logger.error(e)
        raise e

def create_tables() -> None:
    """Create all database tables if they don't exist.
    This is a failsafe in case migrations fail or haven't run.
    """
    logger.info("Ensuring all database tables exist...")
    try:
        Base.metadata.create_all(bind=engine)
        logger.info("All database tables verified/created successfully")
    except Exception as e:
        logger.error(f"Error creating tables: {e}")
        # Don't raise - let migrations try to handle it

def main() -> None:
    logger.info("Initializing service")
    init()
    logger.info("Database connection established")
    
    # Create tables as failsafe before migrations
    create_tables()
    
    logger.info("Service finished initializing")

if __name__ == "__main__":
    main()

