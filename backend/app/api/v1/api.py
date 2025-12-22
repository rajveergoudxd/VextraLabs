from fastapi import APIRouter
from app.api.v1.endpoints import auth, users, upload, settings, oauth, publish, social, chat

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(upload.router, prefix="/upload", tags=["upload"])
api_router.include_router(settings.router, prefix="/settings", tags=["settings"])
api_router.include_router(oauth.router, prefix="/oauth", tags=["oauth"])
api_router.include_router(publish.router, prefix="/publish", tags=["publish"])
api_router.include_router(social.router, prefix="/social", tags=["social"])
api_router.include_router(chat.router, prefix="/chat", tags=["chat"])
