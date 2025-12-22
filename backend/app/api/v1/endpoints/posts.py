from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.api import deps
from app.models.post import Post
from app.models.user import User
from app.schemas import post as post_schema
from app.core import security

router = APIRouter()

@router.post("/", response_model=post_schema.Post)
def create_post(
    post_in: post_schema.PostCreate,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Create new post.
    """
    post = Post(
        content=post_in.content,
        media_urls=post_in.media_urls,
        platforms=post_in.platforms,
        user_id=current_user.id,
        # In a real scenario, we might set published_at here or after confirmed publish
    )
    db.add(post)
    
    # Update user post count
    current_user.posts_count += 1
    db.add(current_user)
    
    db.commit()
    db.refresh(post)
    
    # Construct response with user info
    result = post_schema.Post.from_orm(post)
    result.user = {
        "id": current_user.id,
        "username": current_user.username,
        "full_name": current_user.full_name,
        "profile_picture": current_user.profile_picture,
        "is_verified": False # Placeholder
    }
    return result

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
    
    # Simple feed: all posts ordered by creation date desc
    total = db.query(Post).count()
    posts = db.query(Post).order_by(desc(Post.created_at)).offset(skip).limit(size).all()
    
    post_list = []
    for p in posts:
        p_schema = post_schema.Post.from_orm(p)
        # Fetch owner (optimization: use joinedload in query)
        p_schema.user = {
            "id": p.owner.id,
            "username": p.owner.username,
            "full_name": p.owner.full_name,
            "profile_picture": p.owner.profile_picture,
            "is_verified": False,
        }
        post_list.append(p_schema)
    
    return {
        "items": post_list,
        "total": total,
        "page": page,
        "size": size,
        "has_more": (skip + size) < total
    }

@router.get("/{post_id}", response_model=post_schema.Post)
def get_post(
    post_id: int,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Get post by ID.
    """
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
        
    result = post_schema.Post.from_orm(post)
    result.user = {
        "id": post.owner.id,
        "username": post.owner.username,
        "full_name": post.owner.full_name,
        "profile_picture": post.owner.profile_picture,
        "is_verified": False,
    }
    return result

@router.post("/{post_id}/like", response_model=post_schema.Post)
def like_post(
    post_id: int,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Like a post.
    """
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    # In a real app reduce redundant likes by checking a Like table
    # Here we just increment for simplicity as per request
    post.likes_count += 1
    db.commit()
    db.refresh(post)
    
    result = post_schema.Post.from_orm(post)
    result.user = {
        "id": post.owner.id,
        "username": post.owner.username,
        "full_name": post.owner.full_name,
        "profile_picture": post.owner.profile_picture,
        "is_verified": False,
    }
    return result
