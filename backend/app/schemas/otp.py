from pydantic import BaseModel, EmailStr
from datetime import datetime

class OTPRequest(BaseModel):
    email: EmailStr
    purpose: str = "signup"  # or 'reset_password'

class OTPVerify(BaseModel):
    email: EmailStr
    code: str
    purpose: str

class PasswordReset(BaseModel):
    email: EmailStr
    code: str
    new_password: str
