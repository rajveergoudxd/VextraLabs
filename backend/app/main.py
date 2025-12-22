from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.v1.api import api_router
from app.db.base import Base
from app.db.session import engine


# Create Tables (for anything not covered by migrations, though migrations should cover all)


app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# Set all CORS enabled origins
if settings.BACKEND_CORS_ORIGINS:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=[str(origin) for origin in settings.BACKEND_CORS_ORIGINS],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

app.include_router(api_router, prefix=settings.API_V1_STR)

# WebSocket routes for real-time features
from app.api.v1.endpoints import websocket as ws_router
app.include_router(ws_router.router, prefix=f"{settings.API_V1_STR}/ws", tags=["websocket"])

@app.get("/")
def root():
    return {"message": "Welcome to Vextra API", "status": "active"}
