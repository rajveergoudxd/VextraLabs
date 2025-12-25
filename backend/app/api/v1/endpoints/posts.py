from typing import Any, List, Optional
import secrets
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.api import deps
from app.models.post import Post
from app.models.user import User
from app.models.like import Like
from app.models.follow import Follow
from app.models.comment import Comment
from app.models.saved_post import SavedPost
from app.schemas import post as post_schema
from app.schemas import like as like_schema
from app.schemas import comment as comment_schema
from app.crud.crud_saved_post import saved_post as saved_post_crud
from app.core import security
from app.core.encryption import decrypt_token
from app.models.social_connection import SocialConnection
from app.services.social.linkedin import LinkedInService

router = APIRouter()


def _build_post_response(
    post: Post, 
    current_user: Optional[User] = None, 
    db: Optional[Session] = None
) -> post_schema.Post:
    """Helper to build post response with user info, like status, and saved status."""
    result = post_schema.Post.from_orm(post)
    
    # Check if current user is following the post owner
    is_following = False
    if current_user and db and current_user.id != post.owner.id:
        follow_exists = db.query(Follow).filter(
            Follow.follower_id == current_user.id,
            Follow.following_id == post.owner.id
        ).first()
        is_following = follow_exists is not None

    result.user = {
        "id": post.owner.id,
        "username": post.owner.username,
        "full_name": post.owner.full_name,
        "profile_picture": post.owner.profile_picture,
        "is_verified": False,
        "is_following": is_following,
    }
    result.share_token = post.share_token
    
    # Check if current user has liked the post
    if current_user and db:
        like_exists = db.query(Like).filter(
            Like.user_id == current_user.id,
            Like.post_id == post.id
        ).first()
        result.is_liked = like_exists is not None
        
        # Check if current user has saved the post
        result.is_saved = saved_post_crud.is_post_saved(
            db, user_id=current_user.id, post_id=post.id
        )
    
    return result


@router.post("/", response_model=post_schema.Post)
def create_post(
    post_in: post_schema.PostCreate,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Create new post.
    """
    # Generate share token for the post
    share_token = secrets.token_urlsafe(16)
    
    post = Post(
        content=post_in.content,
        media_urls=post_in.media_urls,
        platforms=post_in.platforms,
        user_id=current_user.id,
        share_token=share_token,
    )
    db.add(post)
    
    # Update user post count
    current_user.posts_count += 1
    db.add(current_user)
    
    db.commit()
    db.refresh(post)
    
    return _build_post_response(post, current_user, db)


@router.get("/feed", response_model=post_schema.PostFeed)
def get_feed(
    db: Session = Depends(deps.get_db),
    page: int = 1,
    size: int = 20,
    current_user: Optional[User] = Depends(deps.get_current_active_user),
) -> Any:
    """
    Get posts feed.
    """
    skip = (page - 1) * size
    
    # Simple feed: all non-draft posts ordered by creation date desc
    total = db.query(Post).filter(Post.is_draft == False).count()
    posts = db.query(Post).filter(Post.is_draft == False).order_by(desc(Post.created_at)).offset(skip).limit(size).all()
    
    post_list = []
    for p in posts:
        post_list.append(_build_post_response(p, current_user, db))
    
    return {
        "items": post_list,
        "total": total,
        "page": page,
        "size": size,
        "has_more": (skip + size) < total
    }


@router.get("/user/{user_id}", response_model=post_schema.PostFeed)
async def get_user_posts(
    user_id: int,
    db: Session = Depends(deps.get_db),
    page: int = 1,
    size: int = 20,
    current_user: Optional[User] = Depends(deps.get_current_active_user),
    platform: Optional[str] = None,
) -> Any:
    """
    Get posts for a specific user.
    """
    skip = (page - 1) * size
    
    # Get non-draft posts by the specified user
    query = db.query(Post).filter(
        Post.user_id == user_id,
        Post.is_draft == False
    )
    
    # Filter by platform if provided
    if platform:
        # Cast JSON to string for simpler LIKE query
        from sqlalchemy import String, cast
        query = query.filter(cast(Post.platforms, String).like(f'%"{platform}"%'))
    
    # Execute query (sync blocking)
    total = query.count()
    posts = query.order_by(desc(Post.created_at)).offset(skip).limit(size).all()
    
    # If platform is LinkedIn, we need to verify post status
    valid_posts = []
    if platform == 'LinkedIn':
        # Get LinkedIn connection
        connection = db.query(SocialConnection).filter(
            SocialConnection.user_id == user_id,
            SocialConnection.platform == 'linkedin'
        ).first()

        linkedin_service = LinkedInService()
        
        for p in posts:
            is_valid = True
            # Check if we have an external ID for this platform
            # platforms can be a list (old data) or dict (new data)
            platform_data = p.platforms
            if isinstance(platform_data, dict) and 'linkedin' in platform_data:
                # New data format with metadata
                meta = platform_data['linkedin']
                if isinstance(meta, dict) and 'post_id' in meta:
                    post_urn = meta['post_id']
                    
                    # Verify existence if we have a valid token
                    if connection and connection.access_token:
                        try:
                            token = decrypt_token(connection.access_token)
                            exists = await linkedin_service.check_post_exists(token, post_urn)
                            
                            if not exists:
                                is_valid = False
                                # Update DB: remove linkedin from platforms
                                # If it's the only platform, maybe delete post? 
                                # For now, just remove key to hide from LinkedIn tab
                                del platform_data['linkedin']
                                p.platforms = platform_data
                                db.add(p)
                                # Don't commit inside loop optimally, but for user safety/simplicity:
                                db.commit() 
                        except Exception:
                            # If check fails (network/auth), assume valid to show user
                            pass
            
            if is_valid:
                valid_posts.append(p)
        
        # Update total count approximate
        posts = valid_posts
        
    post_list = [_build_post_response(p, current_user, db) for p in posts]
    
    return {
        "items": post_list,
        "total": total, # Note: Total might be slightly off if we filtered items, but acceptable
        "page": page,
        "size": size,
        "has_more": (skip + size) < total
    }


@router.get("/my", response_model=post_schema.PostFeed)
def get_my_posts(
    db: Session = Depends(deps.get_db),
    page: int = 1,
    size: int = 20,
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Get current user's published posts.
    """
    skip = (page - 1) * size
    
    # Get non-draft posts by current user
    total = db.query(Post).filter(
        Post.user_id == current_user.id,
        Post.is_draft == False
    ).count()
    
    posts = db.query(Post).filter(
        Post.user_id == current_user.id,
        Post.is_draft == False
    ).order_by(desc(Post.created_at)).offset(skip).limit(size).all()
    
    post_list = [_build_post_response(p, current_user, db) for p in posts]
    
    return {
        "items": post_list,
        "total": total,
        "page": page,
        "size": size,
        "has_more": (skip + size) < total
    }


# ============== Draft Endpoints ==============
# NOTE: These MUST come BEFORE /{post_id} routes to avoid path parameter conflicts

@router.post("/drafts", response_model=post_schema.Post)
def create_draft(
    draft_in: post_schema.DraftCreate,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Create a new draft.
    """
    share_token = secrets.token_urlsafe(16)
    
    draft = Post(
        content=draft_in.content,
        media_urls=draft_in.media_urls,
        platforms=draft_in.platforms,
        title=draft_in.title or "Untitled Draft",
        user_id=current_user.id,
        is_draft=True,
        share_token=share_token,
    )
    db.add(draft)
    db.commit()
    db.refresh(draft)
    
    return _build_post_response(draft, current_user, db)


@router.get("/drafts", response_model=post_schema.DraftList)
def get_drafts(
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Get all drafts for current user.
    """
    drafts = db.query(Post).filter(
        Post.user_id == current_user.id,
        Post.is_draft == True
    ).order_by(desc(Post.created_at)).all()
    
    draft_list = [_build_post_response(d, current_user, db) for d in drafts]
    
    return {"items": draft_list, "total": len(draft_list)}


@router.get("/drafts/{draft_id}", response_model=post_schema.Post)
def get_draft(
    draft_id: int,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Get a specific draft by ID.
    """
    draft = db.query(Post).filter(
        Post.id == draft_id,
        Post.user_id == current_user.id,
        Post.is_draft == True
    ).first()
    
    if not draft:
        raise HTTPException(status_code=404, detail="Draft not found")
    
    return _build_post_response(draft, current_user, db)


@router.put("/drafts/{draft_id}", response_model=post_schema.Post)
def update_draft(
    draft_id: int,
    draft_in: post_schema.DraftUpdate,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Update a draft.
    """
    draft = db.query(Post).filter(
        Post.id == draft_id,
        Post.user_id == current_user.id,
        Post.is_draft == True
    ).first()
    
    if not draft:
        raise HTTPException(status_code=404, detail="Draft not found")
    
    # Update fields if provided
    if draft_in.content is not None:
        draft.content = draft_in.content
    if draft_in.media_urls is not None:
        draft.media_urls = draft_in.media_urls
    if draft_in.platforms is not None:
        draft.platforms = draft_in.platforms
    if draft_in.title is not None:
        draft.title = draft_in.title
    
    db.commit()
    db.refresh(draft)
    
    return _build_post_response(draft, current_user, db)


@router.delete("/drafts/{draft_id}")
def delete_draft(
    draft_id: int,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> dict:
    """
    Delete a draft.
    """
    draft = db.query(Post).filter(
        Post.id == draft_id,
        Post.user_id == current_user.id,
        Post.is_draft == True
    ).first()
    
    if not draft:
        raise HTTPException(status_code=404, detail="Draft not found")
    
    db.delete(draft)
    db.commit()
    
    return {"message": "Draft deleted successfully", "id": draft_id}


@router.post("/drafts/{draft_id}/publish", response_model=post_schema.Post)
def publish_draft(
    draft_id: int,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Publish a draft (convert to published post).
    """
    from datetime import datetime
    
    draft = db.query(Post).filter(
        Post.id == draft_id,
        Post.user_id == current_user.id,
        Post.is_draft == True
    ).first()
    
    if not draft:
        raise HTTPException(status_code=404, detail="Draft not found")
    
    # Convert to published post
    draft.is_draft = False
    draft.published_at = datetime.utcnow()
    
    # Update user post count
    current_user.posts_count = (current_user.posts_count or 0) + 1
    
    db.commit()
    db.refresh(draft)
    
    return _build_post_response(draft, current_user, db)


# ============== Saved Posts Endpoints ==============
# NOTE: These MUST come BEFORE /{post_id} routes to avoid path parameter conflicts

@router.get("/saved", response_model=post_schema.PostFeed)
def get_saved_posts(
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
    page: int = 1,
    size: int = 20,
) -> Any:
    """
    Get all saved posts for current user with pagination.
    """
    skip = (page - 1) * size
    
    total = saved_post_crud.count_saved_posts(db, user_id=current_user.id)
    posts = saved_post_crud.get_saved_posts(
        db, user_id=current_user.id, skip=skip, limit=size
    )
    
    post_list = [_build_post_response(p, current_user, db) for p in posts]
    
    return {
        "items": post_list,
        "total": total,
        "page": page,
        "size": size,
        "has_more": (skip + size) < total
    }


@router.post("/saved/{post_id}")
def save_post(
    post_id: int,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> dict:
    """
    Save a post to user's saved collection.
    """
    post = db.query(Post).filter(Post.id == post_id, Post.is_draft == False).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    saved_post_crud.save_post(db, user_id=current_user.id, post_id=post_id)
    
    return {
        "message": "Post saved successfully",
        "post_id": post_id,
        "is_saved": True
    }


@router.delete("/saved/{post_id}")
def unsave_post(
    post_id: int,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> dict:
    """
    Remove a post from user's saved collection.
    """
    removed = saved_post_crud.unsave_post(db, user_id=current_user.id, post_id=post_id)
    
    if not removed:
        raise HTTPException(status_code=404, detail="Saved post not found")
    
    return {
        "message": "Post unsaved successfully",
        "post_id": post_id,
        "is_saved": False
    }


# ============== Shared Post Endpoint ==============

@router.get("/shared/{share_token}", response_model=post_schema.Post)
def get_shared_post(
    share_token: str,
    db: Session = Depends(deps.get_db),
) -> Any:
    """
    Get a post by share token (public endpoint for deep links).
    """
    post = db.query(Post).filter(
        Post.share_token == share_token,
        Post.is_draft == False
    ).first()
    
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    return _build_post_response(post)


# ============== Comments Endpoints ==============

@router.get("/comments/{comment_id}")
def delete_comment(
    comment_id: int,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> comment_schema.CommentDeleteResponse:
    """
    Delete a comment (only by the comment owner or post owner).
    """
    comment = db.query(Comment).filter(Comment.id == comment_id).first()
    
    if not comment:
        raise HTTPException(status_code=404, detail="Comment not found")
    
    # Check permission: comment owner or post owner can delete
    post = db.query(Post).filter(Post.id == comment.post_id).first()
    if comment.user_id != current_user.id and (post and post.user_id != current_user.id):
        raise HTTPException(status_code=403, detail="Not authorized to delete this comment")
    
    # Update comment count on post
    if post:
        post.comments_count = max(0, post.comments_count - 1)
    
    db.delete(comment)
    db.commit()
    
    return {"message": "Comment deleted successfully", "id": comment_id}


# ============== Individual Post Endpoints ==============
# NOTE: These MUST come AFTER /drafts and /shared routes

@router.get("/{post_id}", response_model=post_schema.Post)
def get_post(
    post_id: int,
    db: Session = Depends(deps.get_db),
    current_user: Optional[User] = Depends(deps.get_current_active_user),
) -> Any:
    """
    Get post by ID.
    """
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    return _build_post_response(post, current_user, db)


@router.post("/{post_id}/like", response_model=like_schema.LikeToggleResponse)
def toggle_like(
    post_id: int,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Toggle like on a post. If already liked, unlike it. If not liked, like it.
    """
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    # Check if user already liked this post
    existing_like = db.query(Like).filter(
        Like.user_id == current_user.id,
        Like.post_id == post_id
    ).first()
    
    if existing_like:
        # Unlike: remove the like
        db.delete(existing_like)
        post.likes_count = max(0, post.likes_count - 1)
        db.commit()
        
        return {
            "is_liked": False,
            "likes_count": post.likes_count,
            "message": "Post unliked"
        }
    else:
        # Like: add a new like
        new_like = Like(user_id=current_user.id, post_id=post_id)
        db.add(new_like)
        post.likes_count += 1
        
        # Create notification if not own post
        if post.user_id != current_user.id:
            from app.models.notification import Notification, NotificationType
            notification = Notification(
                user_id=post.user_id,
                actor_id=current_user.id,
                type=NotificationType.LIKE,
                title="New Like",
                message=f"{current_user.username} liked your post",
                related_id=post.id,
                related_type="post"
            )
            db.add(notification)
            
        db.commit()
        
        return {
            "is_liked": True,
            "likes_count": post.likes_count,
            "message": "Post liked"
        }


@router.get("/{post_id}/likes", response_model=like_schema.LikeListResponse)
def get_post_likes(
    post_id: int,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
    skip: int = 0,
    limit: int = 50,
) -> Any:
    """
    Get list of users who liked a post.
    """
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    total = db.query(Like).filter(Like.post_id == post_id).count()
    likes = db.query(Like).filter(Like.post_id == post_id).order_by(desc(Like.created_at)).offset(skip).limit(limit).all()
    
    like_items = []
    for like in likes:
        like_items.append({
            "id": like.id,
            "user": {
                "id": like.user.id,
                "username": like.user.username,
                "full_name": like.user.full_name,
                "profile_picture": like.user.profile_picture,
            },
            "created_at": like.created_at,
        })
    
    return {"items": like_items, "total": total}


@router.post("/{post_id}/comments", response_model=comment_schema.CommentResponse)
def create_comment(
    post_id: int,
    comment_in: comment_schema.CommentCreate,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Add a comment to a post.
    """
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    comment = Comment(
        user_id=current_user.id,
        post_id=post_id,
        content=comment_in.content,
    )
    db.add(comment)
    
    # Update comment count on post
    post.comments_count += 1
    
    # Create notification if not own post
    if post.user_id != current_user.id:
        from app.models.notification import Notification, NotificationType
        notification = Notification(
            user_id=post.user_id,
            actor_id=current_user.id,
            type=NotificationType.COMMENT,
            title="New Comment",
            message=f"{current_user.username} commented on your post",
            related_id=post.id,
            related_type="post"
        )
        db.add(notification)
    
    db.commit()
    db.refresh(comment)
    
    return {
        "id": comment.id,
        "post_id": comment.post_id,
        "content": comment.content,
        "created_at": comment.created_at,
        "updated_at": comment.updated_at,
        "user": {
            "id": current_user.id,
            "username": current_user.username,
            "full_name": current_user.full_name,
            "profile_picture": current_user.profile_picture,
        }
    }


@router.get("/{post_id}/comments", response_model=comment_schema.CommentListResponse)
def get_post_comments(
    post_id: int,
    db: Session = Depends(deps.get_db),
    current_user: Optional[User] = Depends(deps.get_current_active_user),
    skip: int = 0,
    limit: int = 50,
) -> Any:
    """
    Get comments for a post with pagination.
    """
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    total = db.query(Comment).filter(Comment.post_id == post_id).count()
    comments = db.query(Comment).filter(Comment.post_id == post_id).order_by(desc(Comment.created_at)).offset(skip).limit(limit).all()
    
    comment_items = []
    for c in comments:
        comment_items.append({
            "id": c.id,
            "post_id": c.post_id,
            "content": c.content,
            "created_at": c.created_at,
            "updated_at": c.updated_at,
            "user": {
                "id": c.user.id,
                "username": c.user.username,
                "full_name": c.user.full_name,
                "profile_picture": c.user.profile_picture,
            }
        })
    
    return {
        "items": comment_items,
        "total": total,
        "has_more": (skip + limit) < total
    }


@router.get("/{post_id}/share-link")
def get_share_link(
    post_id: int,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> dict:
    """
    Get or generate a shareable link for a post.
    """
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    # Generate share token if not exists
    if not post.share_token:
        post.share_token = secrets.token_urlsafe(16)
        db.commit()
        db.refresh(post)
    

    
    return {
        "share_token": post.share_token,
        "share_url": f"vextra://post/{post.share_token}",
        "web_url": f"https://vextra.app/post/{post.share_token}"  # For web fallback
    }


@router.delete("/{post_id}")
def delete_post(
    post_id: int,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> dict:
    """
    Delete a published post (only by post owner).
    """
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    # Check permission
    if post.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this post")
    
    # Decrement user post count
    if hasattr(post, 'is_draft') and post.is_draft is False:
        # Re-fetch user to ensure we have the latest state if needed, 
        # but post.owner should be loaded if lazy='joined' or similar. 
        # Using current_user directly is safer since post.user_id == current_user.id
        current_user.posts_count = max(0, (current_user.posts_count or 0) - 1)
        db.add(current_user)
    
    db.delete(post)
    db.commit()
    
    return {"message": "Post deleted successfully", "id": post_id}
