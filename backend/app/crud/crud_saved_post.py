from typing import List, Optional

from sqlalchemy.orm import Session
from sqlalchemy import and_

from app.models.saved_post import SavedPost
from app.models.post import Post


class CRUDSavedPost:
    def save_post(self, db: Session, *, user_id: int, post_id: int) -> SavedPost:
        """Save a post for a user. Returns existing if already saved."""
        existing = self.get_saved_post(db, user_id=user_id, post_id=post_id)
        if existing:
            return existing
        
        db_obj = SavedPost(user_id=user_id, post_id=post_id)
        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def unsave_post(self, db: Session, *, user_id: int, post_id: int) -> bool:
        """Remove a saved post. Returns True if deleted, False if not found."""
        saved = self.get_saved_post(db, user_id=user_id, post_id=post_id)
        if saved:
            db.delete(saved)
            db.commit()
            return True
        return False

    def get_saved_post(
        self, db: Session, *, user_id: int, post_id: int
    ) -> Optional[SavedPost]:
        """Get a specific saved post entry."""
        return (
            db.query(SavedPost)
            .filter(and_(SavedPost.user_id == user_id, SavedPost.post_id == post_id))
            .first()
        )

    def is_post_saved(self, db: Session, *, user_id: int, post_id: int) -> bool:
        """Check if a post is saved by user."""
        return self.get_saved_post(db, user_id=user_id, post_id=post_id) is not None

    def get_saved_posts(
        self, db: Session, *, user_id: int, skip: int = 0, limit: int = 20
    ) -> List[Post]:
        """Get all posts saved by a user with pagination."""
        saved_entries = (
            db.query(SavedPost)
            .filter(SavedPost.user_id == user_id)
            .order_by(SavedPost.saved_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )
        
        # Return the actual Post objects
        post_ids = [s.post_id for s in saved_entries]
        if not post_ids:
            return []
        
        posts = db.query(Post).filter(Post.id.in_(post_ids)).all()
        # Preserve order from saved_entries
        post_map = {p.id: p for p in posts}
        return [post_map[pid] for pid in post_ids if pid in post_map]

    def count_saved_posts(self, db: Session, *, user_id: int) -> int:
        """Count total saved posts for a user."""
        return db.query(SavedPost).filter(SavedPost.user_id == user_id).count()


saved_post = CRUDSavedPost()
