from typing import Optional
from pydantic import BaseModel

class UserSettingsBase(BaseModel):
    push_notifications_enabled: bool = True
    email_notifications_enabled: bool = True
    theme_preference: str = "system"

class UserSettingsUpdate(BaseModel):
    push_notifications_enabled: Optional[bool] = None
    email_notifications_enabled: Optional[bool] = None
    theme_preference: Optional[str] = None

class UserSettings(UserSettingsBase):
    id: int
    user_id: int

    class Config:
        from_attributes = True

class ChangePassword(BaseModel):
    current_password: str
    new_password: str
