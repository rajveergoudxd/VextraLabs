from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.api import deps
from app.models.user import User as UserModel
from app.models.follow import Follow
from app.schemas.social import (
    FollowStatus,
    FollowerInfo,
    FollowingInfo,
    FollowersResponse,
    FollowingResponse,
    UserSearchResult,
    UserSearchResponse,
    PublicProfile,
)

from app.models.notification import Notification, NotificationType

router = APIRouter()


# ============== Follow System ==============

@router.post("/follow/{user_id}", status_code=status.HTTP_201_CREATED)
def follow_user(
    user_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> dict:
    """Follow a user."""
    # Can't follow yourself
    if user_id == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot follow yourself"
        )
    
    # Check if target user exists
    target_user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not target_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Check if already following
    existing_follow = db.query(Follow).filter(
        Follow.follower_id == current_user.id,
        Follow.following_id == user_id
    ).first()
    
    if existing_follow:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You are already following this user"
        )
    
    # Create follow relationship
    follow = Follow(follower_id=current_user.id, following_id=user_id)
    db.add(follow)
    
    # Create notification
    notification = Notification(
        user_id=user_id,
        actor_id=current_user.id,
        type=NotificationType.FOLLOW,
        title="New Follower",
        message=f"{current_user.username} started following you",
        related_id=current_user.id,
        related_type="user"
    )
    db.add(notification)
    
    # Update counts
    current_user.following_count = (current_user.following_count or 0) + 1
    target_user.followers_count = (target_user.followers_count or 0) + 1
    
    db.commit()
    
    return {"message": "Successfully followed user", "following_id": user_id}


@router.delete("/unfollow/{user_id}")
def unfollow_user(
    user_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> dict:
    """Unfollow a user."""
    # Find existing follow
    follow = db.query(Follow).filter(
        Follow.follower_id == current_user.id,
        Follow.following_id == user_id
    ).first()
    
    if not follow:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="You are not following this user"
        )
    
    # Get target user for count update
    target_user = db.query(UserModel).filter(UserModel.id == user_id).first()
    
    # Delete follow relationship
    db.delete(follow)
    
    # Update counts
    current_user.following_count = max((current_user.following_count or 1) - 1, 0)
    if target_user:
        target_user.followers_count = max((target_user.followers_count or 1) - 1, 0)
    
    db.commit()
    
    return {"message": "Successfully unfollowed user", "unfollowed_id": user_id}


@router.get("/follow-status/{user_id}", response_model=FollowStatus)
def get_follow_status(
    user_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> FollowStatus:
    """Get follow status between current user and target user."""
    # Check if current user follows target
    is_following = db.query(Follow).filter(
        Follow.follower_id == current_user.id,
        Follow.following_id == user_id
    ).first() is not None
    
    # Check if target follows current user
    is_followed_by = db.query(Follow).filter(
        Follow.follower_id == user_id,
        Follow.following_id == current_user.id
    ).first() is not None
    
    return FollowStatus(is_following=is_following, is_followed_by=is_followed_by)


@router.get("/followers/{user_id}", response_model=FollowersResponse)
def get_followers(
    user_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
    skip: int = 0,
    limit: int = 50,
) -> FollowersResponse:
    """Get list of users following the specified user."""
    # Get all follower relationships
    follows = db.query(Follow).filter(
        Follow.following_id == user_id
    ).offset(skip).limit(limit).all()
    
    total = db.query(Follow).filter(Follow.following_id == user_id).count()
    
    # Get current user's following list for "follow back" status
    current_user_following = set(
        f.following_id for f in db.query(Follow).filter(
            Follow.follower_id == current_user.id
        ).all()
    )
    
    followers = []
    for follow in follows:
        user = db.query(UserModel).filter(UserModel.id == follow.follower_id).first()
        if user:
            followers.append(FollowerInfo(
                id=user.id,
                username=user.username,
                full_name=user.full_name,
                profile_picture=user.profile_picture,
                is_following=user.id in current_user_following
            ))
    
    return FollowersResponse(followers=followers, total=total)


@router.get("/following/{user_id}", response_model=FollowingResponse)
def get_following(
    user_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
    skip: int = 0,
    limit: int = 50,
) -> FollowingResponse:
    """Get list of users the specified user is following."""
    # Get all following relationships
    follows = db.query(Follow).filter(
        Follow.follower_id == user_id
    ).offset(skip).limit(limit).all()
    
    total = db.query(Follow).filter(Follow.follower_id == user_id).count()
    
    # Get who follows current user for "follows you" status
    current_user_followers = set(
        f.follower_id for f in db.query(Follow).filter(
            Follow.following_id == current_user.id
        ).all()
    )
    
    following = []
    for follow in follows:
        user = db.query(UserModel).filter(UserModel.id == follow.following_id).first()
        if user:
            following.append(FollowingInfo(
                id=user.id,
                username=user.username,
                full_name=user.full_name,
                profile_picture=user.profile_picture,
                is_followed_by=user.id in current_user_followers
            ))
    
    return FollowingResponse(following=following, total=total)


# ============== User Search ==============

@router.get("/search", response_model=UserSearchResponse)
def search_users(
    q: str,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
    skip: int = 0,
    limit: int = 20,
) -> UserSearchResponse:
    """Search users by username or full name."""
    if len(q) < 2:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Search query must be at least 2 characters"
        )
    
    search_pattern = f"%{q.lower()}%"
    
    # Search by username or full name (case-insensitive)
    users = db.query(UserModel).filter(
        UserModel.id != current_user.id,  # Exclude current user
        UserModel.is_active == True,
        or_(
            UserModel.username.ilike(search_pattern),
            UserModel.full_name.ilike(search_pattern)
        )
    ).offset(skip).limit(limit).all()
    
    total = db.query(UserModel).filter(
        UserModel.id != current_user.id,
        UserModel.is_active == True,
        or_(
            UserModel.username.ilike(search_pattern),
            UserModel.full_name.ilike(search_pattern)
        )
    ).count()
    
    # Get current user's following list
    current_user_following = set(
        f.following_id for f in db.query(Follow).filter(
            Follow.follower_id == current_user.id
        ).all()
    )
    
    results = [
        UserSearchResult(
            id=user.id,
            username=user.username,
            full_name=user.full_name,
            bio=user.bio,
            profile_picture=user.profile_picture,
            followers_count=user.followers_count or 0,
            is_following=user.id in current_user_following
        )
        for user in users
    ]
    
    return UserSearchResponse(results=results, total=total, query=q)


@router.get("/profile/{username}", response_model=PublicProfile)
def get_public_profile(
    username: str,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> PublicProfile:
    """Get public profile of a user by username."""
    user = db.query(UserModel).filter(
        UserModel.username == username,
        UserModel.is_active == True
    ).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Check follow status
    is_following = db.query(Follow).filter(
        Follow.follower_id == current_user.id,
        Follow.following_id == user.id
    ).first() is not None
    
    is_followed_by = db.query(Follow).filter(
        Follow.follower_id == user.id,
        Follow.following_id == current_user.id
    ).first() is not None
    
    return PublicProfile(
        id=user.id,
        username=user.username,
        full_name=user.full_name,
        bio=user.bio,
        profile_picture=user.profile_picture,
        posts_count=user.posts_count or 0,
        followers_count=user.followers_count or 0,
        following_count=user.following_count or 0,
        is_following=is_following,
        is_followed_by=is_followed_by
    )
