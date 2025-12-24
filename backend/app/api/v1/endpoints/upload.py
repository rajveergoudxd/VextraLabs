from fastapi import APIRouter, UploadFile, File, Depends, HTTPException, Form
from typing import Any, Optional
from app.api import deps
from app.models.user import User as UserModel
from app.core.storage import StorageService

router = APIRouter()

@router.post("/", response_model=dict)
async def upload_file(
    file: UploadFile = File(...),
    folder: Optional[str] = Form(default="posts"),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """
    Upload a file (e.g. profile picture, post media).
    """
    if not file.content_type.startswith("image/") and not file.content_type.startswith("video/"):
        raise HTTPException(status_code=400, detail="File must be an image or video")
        
    url = await StorageService.upload_file(file, folder=folder)
    return {"url": url}

