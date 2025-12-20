from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from typing import Any
from app.api import deps
from app.models.user import User as UserModel
from app.core.storage import StorageService

router = APIRouter()

@router.post("/", response_model=dict)
async def upload_file(
    file: UploadFile = File(...),
    current_user: UserModel = Depends(deps.get_current_user),
) -> Any:
    """
    Upload a file (e.g. profile picture).
    """
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
        
    url = await StorageService.upload_file(file, folder="profile_pictures")
    return {"url": url}
