from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import desc
from datetime import datetime, timezone

from app.api import deps
from app.models.user import User as UserModel
from app.models.notification import Notification, NotificationType as NotificationTypeModel
from app.schemas.notification import (
    NotificationType,
    NotificationResponse,
    NotificationsListResponse,
    UnreadCountResponse,
    ActorInfo,
)

router = APIRouter()


def get_time_ago(dt: datetime) -> str:
    """Convert datetime to human-readable 'time ago' string."""
    if dt is None:
        return ""
    
    now = datetime.now(timezone.utc)
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    
    diff = now - dt
    seconds = diff.total_seconds()
    
    if seconds < 60:
        return "now"
    elif seconds < 3600:
        minutes = int(seconds / 60)
        return f"{minutes}m"
    elif seconds < 86400:
        hours = int(seconds / 3600)
        return f"{hours}h"
    elif seconds < 604800:
        days = int(seconds / 86400)
        return f"{days}d"
    elif seconds < 2592000:
        weeks = int(seconds / 604800)
        return f"{weeks}w"
    else:
        months = int(seconds / 2592000)
        return f"{months}mo"


def build_notification_response(notification: Notification, actor: Optional[UserModel]) -> NotificationResponse:
    """Build NotificationResponse from database model."""
    actor_info = None
    if actor:
        actor_info = ActorInfo(
            id=actor.id,
            username=actor.username,
            full_name=actor.full_name,
            profile_picture=actor.profile_picture
        )
    
    return NotificationResponse(
        id=notification.id,
        type=NotificationType(notification.type.value),
        title=notification.title,
        message=notification.message,
        related_id=notification.related_id,
        related_type=notification.related_type,
        content_image_url=notification.content_image_url,
        is_read=notification.is_read,
        created_at=notification.created_at,
        read_at=notification.read_at,
        actor=actor_info,
        time_ago=get_time_ago(notification.created_at)
    )


@router.get("", response_model=NotificationsListResponse)
def get_notifications(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    type_filter: Optional[str] = Query(None, alias="type"),
) -> NotificationsListResponse:
    """
    Get paginated list of notifications for the current user.
    Optionally filter by notification type.
    """
    query = db.query(Notification).filter(Notification.user_id == current_user.id)
    
    # Apply type filter if provided
    if type_filter:
        if type_filter == "mentions":
            query = query.filter(Notification.type == NotificationTypeModel.MENTION)
        elif type_filter == "system":
            query = query.filter(
                Notification.type.in_([NotificationTypeModel.SYSTEM, NotificationTypeModel.AI])
            )
        # "all" or invalid filter returns all notifications
    
    # Get total count
    total = query.count()
    
    # Get unread count
    unread_count = db.query(Notification).filter(
        Notification.user_id == current_user.id,
        Notification.is_read == False
    ).count()
    
    # Get paginated notifications ordered by created_at desc
    notifications = query.order_by(desc(Notification.created_at)).offset(skip).limit(limit).all()
    
    # Build response with actor info
    notification_responses = []
    for n in notifications:
        actor = None
        if n.actor_id:
            actor = db.query(UserModel).filter(UserModel.id == n.actor_id).first()
        notification_responses.append(build_notification_response(n, actor))
    
    has_more = (skip + limit) < total
    
    return NotificationsListResponse(
        notifications=notification_responses,
        total=total,
        unread_count=unread_count,
        has_more=has_more
    )


@router.get("/unread-count", response_model=UnreadCountResponse)
def get_unread_count(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> UnreadCountResponse:
    """Get count of unread notifications for the current user."""
    count = db.query(Notification).filter(
        Notification.user_id == current_user.id,
        Notification.is_read == False
    ).count()
    
    return UnreadCountResponse(count=count)


@router.put("/{notification_id}/read")
def mark_notification_read(
    notification_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> dict:
    """Mark a single notification as read."""
    notification = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()
    
    if not notification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found"
        )
    
    notification.is_read = True
    notification.read_at = datetime.now(timezone.utc)
    db.commit()
    
    return {"message": "Notification marked as read", "id": notification_id}


@router.put("/mark-all-read")
def mark_all_notifications_read(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> dict:
    """Mark all notifications as read for the current user."""
    now = datetime.now(timezone.utc)
    
    updated_count = db.query(Notification).filter(
        Notification.user_id == current_user.id,
        Notification.is_read == False
    ).update({
        Notification.is_read: True,
        Notification.read_at: now
    })
    
    db.commit()
    
    return {"message": "All notifications marked as read", "updated_count": updated_count}


@router.delete("/{notification_id}")
def delete_notification(
    notification_id: int,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> dict:
    """Delete a notification."""
    notification = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.id
    ).first()
    
    if not notification:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Notification not found"
        )
    
    db.delete(notification)
    db.commit()
    
    return {"message": "Notification deleted", "id": notification_id}


# ============== Helper: Create Notification ==============
# This is used by other parts of the app to create notifications

from app.services.fcm import send_push_notification

def create_notification(
    db: Session,
    user_id: int,
    notification_type: NotificationTypeModel,
    message: str,
    actor_id: Optional[int] = None,
    title: Optional[str] = None,
    related_id: Optional[int] = None,
    related_type: Optional[str] = None,
    content_image_url: Optional[str] = None,
) -> Notification:
    """
    Create a new notification.
    This helper function can be used by other endpoints (e.g., follow, like) to create notifications.
    """
    notification = Notification(
        user_id=user_id,
        actor_id=actor_id,
        type=notification_type,
        title=title,
        message=message,
        related_id=related_id,
        related_type=related_type,
        content_image_url=content_image_url,
    )
    
    db.add(notification)
    db.commit()
    db.refresh(notification)
    
    # Send Push Notification
    try:
        user = db.query(UserModel).filter(UserModel.id == user_id).first()
        if user and user.fcm_token:
            push_title = title or "Vextra"
            send_push_notification(
                token=user.fcm_token,
                title=push_title,
                body=message,
                data={
                    "type": str(notification_type.value),
                    "related_id": str(related_id) if related_id else "",
                    "notification_id": str(notification.id)
                }
            )
    except Exception as e:
        # Don't fail the request if push fails
        print(f"Failed to send push notification: {e}")
    
    return notification
