from typing import Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.models.user import User as UserModel
from app.schemas.user import User, UserUpdate

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
    user_data = user_in.model_dump(exclude_unset=True)
    for field, value in user_data.items():
        setattr(current_user, field, value)
        
    db.add(current_user)
    db.commit()
    db.refresh(current_user)
    return current_user
@router.put("/fcm-token", response_model=Any)
def update_fcm_token(
    token: str,
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """
    Update FCM token for the current user.
    """
    current_user.fcm_token = token
    db.add(current_user)
    db.commit()
    return {"message": "FCM token updated"}
