#!/bin/bash
set -e

echo "Waiting for database connection..."
python -m app.backend_pre_start

echo "Running database migrations..."
# Run migrations but don't fail deployment if they fail (e.g. connectivity issues)
alembic upgrade head


echo "Starting FastAPI server..."
exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080}

