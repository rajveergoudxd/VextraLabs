from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api.v1.api import api_router
from app.db.base import Base
from app.db.session import engine

from alembic.config import Config
from alembic import command
import logging

# Run Migrations
try:
    logging.info("Running database migrations...")
    alembic_cfg = Config("alembic.ini")
    command.upgrade(alembic_cfg, "head")
    logging.info("Database migrations completed successfully.")
except Exception as e:
    logging.error(f"Error running database migrations: {e}")
    # We don't raise here to allow the app to start and show logs, 
    # though it might fail later. Ideally, we should fix the DB.
    pass

# Create Tables (for anything not covered by migrations, though migrations should cover all)
Base.metadata.create_all(bind=engine)

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

@app.get("/")
def root():
    return {"message": "Welcome to Vextra API", "status": "active"}
