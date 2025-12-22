from typing import Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.models.user import User as UserModel
from app.models.settings import UserSettings as SettingsModel
from app.schemas.settings import UserSettings, UserSettingsUpdate

router = APIRouter()


@router.get("/me", response_model=UserSettings)
def get_user_settings(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """
    Get current user settings. Creates default settings if none exist.
    """
    settings = db.query(SettingsModel).filter(
        SettingsModel.user_id == current_user.id
    ).first()
    
    if not settings:
        # Create default settings for user
        settings = SettingsModel(user_id=current_user.id)
        db.add(settings)
        db.commit()
        db.refresh(settings)
    
    return settings


@router.put("/me", response_model=UserSettings)
def update_user_settings(
    *,
    db: Session = Depends(deps.get_db),
    settings_in: UserSettingsUpdate,
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """
    Update user settings.
    """
    settings = db.query(SettingsModel).filter(
        SettingsModel.user_id == current_user.id
    ).first()
    
    if not settings:
        # Create settings if they don't exist
        settings = SettingsModel(user_id=current_user.id)
        db.add(settings)
        db.commit()
        db.refresh(settings)
    
    settings_data = settings_in.model_dump(exclude_unset=True)
    for field, value in settings_data.items():
        setattr(settings, field, value)
    
    db.add(settings)
    db.commit()
    db.refresh(settings)
    return settings


@router.delete("/me")
def delete_user_account(
    db: Session = Depends(deps.get_db),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """
    Delete the current user's account and all associated data.
    """
    # Delete user settings first
    db.query(SettingsModel).filter(
        SettingsModel.user_id == current_user.id
    ).delete()
    
    # Delete the user
    db.delete(current_user)
    db.commit()
    
    return {"message": "Account deleted successfully"}
