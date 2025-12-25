#!/bin/bash
set -e

echo "Waiting for database connection..."
python -m app.backend_pre_start || {
    echo "WARNING: Pre-start script failed, but continuing..."
}

echo "Running database migrations..."
# Run migrations but don't fail deployment if they fail (e.g. connectivity issues)
alembic upgrade head || {
    echo "WARNING: Migrations failed, but continuing with server startup..."
}

echo "Starting FastAPI server..."
exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080}

