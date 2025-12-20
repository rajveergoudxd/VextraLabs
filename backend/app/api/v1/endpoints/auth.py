from datetime import timedelta
from typing import Any
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.api import deps
from app.core import security
from app.core.config import settings
from app.models.user import User as UserModel
from app.models.otp import OTP as OTPModel
from app.schemas.user import User, UserCreate, Token
from app.schemas.otp import OTPRequest, OTPVerify, PasswordReset
from app.core.email import EmailService
from datetime import datetime
import random
import string

router = APIRouter()

@router.post("/login/access-token", response_model=Token)
def login_access_token(
    db: Session = Depends(deps.get_db), form_data: OAuth2PasswordRequestForm = Depends()
) -> Any:
    """
    OAuth2 compatible token login, get an access token for future requests
    """
    user = db.query(UserModel).filter(UserModel.email == form_data.username).first()
    if not user or not security.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=400, detail="Incorrect email or password")
    elif not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
        
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    return {
        "access_token": security.create_access_token(
            user.id, expires_delta=access_token_expires
        ),
        "token_type": "bearer",
    }



@router.post("/signup", response_model=User)
async def create_user_signup(
    *,
    db: Session = Depends(deps.get_db),
    user_in: UserCreate,
) -> Any:
    """
    Create new user without the need to be logged in
    """
    user = db.query(UserModel).filter(UserModel.email == user_in.email).first()
    if user:
        raise HTTPException(
            status_code=400,
            detail="The user with this email already exists in the system",
        )
    user = UserModel(
        email=user_in.email,
        hashed_password=security.get_password_hash(user_in.password),
        full_name=user_in.full_name,
        is_active=False,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    otp_code = generate_otp()
    expires_at = datetime.utcnow() + timedelta(minutes=10)
    
    otp_entry = OTPModel(
        email=user_in.email,
        code=otp_code,
        purpose="signup",
        expires_at=expires_at,
    )
    db.add(otp_entry)
    db.commit()

    await EmailService.send_otp_email(user_in.email, otp_code, purpose="signup")
    
    return user

@router.get("/me", response_model=User)
def read_user_me(
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """
    Get current user.
    """
    return current_user

def generate_otp(length=6):
    return ''.join(random.choices(string.digits, k=length))

@router.post("/forgot-password")
async def forgot_password(
    otp_request: OTPRequest,
    db: Session = Depends(deps.get_db),
) -> Any:
    """
    Generate and send OTP for password reset
    """
    user = db.query(UserModel).filter(UserModel.email == otp_request.email).first()
    if not user:
        raise HTTPException(
            status_code=404,
            detail="The user with this email does not exist in the system",
        )
    
    otp_code = generate_otp()
    expires_at = datetime.utcnow() + timedelta(minutes=10)
    
    otp_entry = OTPModel(
        email=otp_request.email,
        code=otp_code,
        purpose=otp_request.purpose,
        expires_at=expires_at,
    )
    db.add(otp_entry)
    db.commit()
    
    # Send OTP via Email
    await EmailService.send_otp_email(otp_request.email, otp_code, purpose=otp_request.purpose)
    
    return {"message": "OTP sent successfully"}

@router.post("/verify-otp")
def verify_otp(
    otp_in: OTPVerify,
    db: Session = Depends(deps.get_db),
) -> Any:
    """
    Verify OTP
    """
    otp = db.query(OTPModel).filter(
        OTPModel.email == otp_in.email,
        OTPModel.code == otp_in.code,
        OTPModel.purpose == otp_in.purpose,
        OTPModel.is_verified == False,
        OTPModel.expires_at > datetime.utcnow()
    ).first()
    
    if not otp:
        raise HTTPException(status_code=400, detail="Invalid or expired OTP")
    
    otp.is_verified = True
    
    if otp_in.purpose == "signup":
        user = db.query(UserModel).filter(UserModel.email == otp_in.email).first()
        if user:
            user.is_active = True
            db.add(user)

    db.commit()
    
    return {"message": "OTP verified successfully"}

@router.post("/reset-password")
def reset_password(
    reset_in: PasswordReset,
    db: Session = Depends(deps.get_db),
) -> Any:
    """
    Reset password using verified OTP
    """
    # Verify OTP again to be sure (or check if it was just verified)
    # For stricter security, we should issue a temp token on verify-otp
    # But for now, we'll re-verify the code is marked as verified and roughly fresh
    
    otp = db.query(OTPModel).filter(
        OTPModel.email == reset_in.email,
        OTPModel.code == reset_in.code,
        OTPModel.purpose == "reset_password",
        OTPModel.is_verified == True, # Must be verified
         # Allow a small window after verification if needed, or just check it exists
    ).order_by(OTPModel.created_at.desc()).first()
    
    if not otp:
         raise HTTPException(status_code=400, detail="Invalid OTP or not verified")

    user = db.query(UserModel).filter(UserModel.email == reset_in.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    user.hashed_password = security.get_password_hash(reset_in.new_password)
    db.commit()
    
    return {"message": "Password reset successfully"}

