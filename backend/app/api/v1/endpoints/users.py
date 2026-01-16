from typing import Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app import crud
from app.api import deps
from app.models.user import User as UserModel
from app.schemas.user import User, UserUpdate
import logging

logger = logging.getLogger(__name__)

router = APIRouter()

@router.put("/me", response_model=User)
def update_user_me(
    *,
    db: Session = Depends(deps.get_db),
    user_in: UserUpdate,
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """
    Update own user.
    """
    user = crud.user.update(db, db_obj=current_user, obj_in=user_in)
    return user
@router.put("/fcm-token", response_model=Any)
def update_fcm_token(
    token: str,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """
    Update FCM token for the current user.
    """
    logger.info(f"Updating FCM token for user {current_user.id} ({current_user.username}): {token[:20]}...")
    current_user.fcm_token = token
    db.add(current_user)
    db.commit()
    logger.info(f"FCM token saved successfully for user {current_user.id}")
    return {"message": "FCM token updated"}
