from typing import Any, List
from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from app.api import deps

router = APIRouter()

@router.get("/db-status", response_model=List[str])
def check_db_tables(
    db: Session = Depends(deps.get_db),
) -> Any:
    """
    Fetch list of all tables in the current database.
    Useful for debugging migration issues.
    """
    try:
        # PostgreSQL specific query to get all table names in public schema
        result = db.execute(text(
            "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"
        ))
        tables = [row[0] for row in result.fetchall()]
        return tables
    except Exception as e:
        return [f"Error: {str(e)}"]
