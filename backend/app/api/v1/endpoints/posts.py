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
    draft = Post(
        content=draft_in.content,
        media_urls=draft_in.media_urls,
        platforms=draft_in.platforms,
        title=draft_in.title or "Untitled Draft",
        user_id=current_user.id,
        is_draft=True,
    )
    db.add(draft)
    db.commit()
    db.refresh(draft)
    
    result = post_schema.Post.from_orm(draft)
    result.user = {
        "id": current_user.id,
        "username": current_user.username,
        "full_name": current_user.full_name,
        "profile_picture": current_user.profile_picture,
        "is_verified": False,
    }
    return result


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
    
    draft_list = []
    for d in drafts:
        d_schema = post_schema.Post.from_orm(d)
        d_schema.user = {
            "id": current_user.id,
            "username": current_user.username,
            "full_name": current_user.full_name,
            "profile_picture": current_user.profile_picture,
            "is_verified": False,
        }
        draft_list.append(d_schema)
    
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
    
    result = post_schema.Post.from_orm(draft)
    result.user = {
        "id": current_user.id,
        "username": current_user.username,
        "full_name": current_user.full_name,
        "profile_picture": current_user.profile_picture,
        "is_verified": False,
    }
    return result


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
    
    result = post_schema.Post.from_orm(draft)
    result.user = {
        "id": current_user.id,
        "username": current_user.username,
        "full_name": current_user.full_name,
        "profile_picture": current_user.profile_picture,
        "is_verified": False,
    }
    return result


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
    
    result = post_schema.Post.from_orm(draft)
    result.user = {
        "id": current_user.id,
        "username": current_user.username,
        "full_name": current_user.full_name,
        "profile_picture": current_user.profile_picture,
        "is_verified": False,
    }
    return result


# ============== Individual Post Endpoints ==============
# NOTE: These MUST come AFTER /drafts routes

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


