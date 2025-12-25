"""initial_create_users_table

Revision ID: 00_initial_users
Revises: None
Create Date: 2024-12-19 00:00:00.000000

This migration creates the initial users table.
It must be the very first migration in the chain.
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect


# revision identifiers, used by Alembic.
revision: str = '00_initial_users'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def table_exists(table_name: str) -> bool:
    """Check if a table exists in the database."""
    try:
        conn = op.get_bind()
        inspector = inspect(conn)
        return table_name in inspector.get_table_names()
    except (sa.exc.NoInspectionAvailable, NameError):
        # In offline mode (generating SQL), inspection fails.
        # Assume table doesn't exist so we generate the CREATE statement.
        return False


def upgrade() -> None:
    # Create users table if it doesn't exist
    if not table_exists('users'):
        op.create_table('users',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('email', sa.String(), nullable=False),
            sa.Column('full_name', sa.String(), nullable=True),
            sa.Column('hashed_password', sa.String(), nullable=False),
            sa.Column('is_active', sa.Boolean(), server_default='true', nullable=True),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index(op.f('ix_users_id'), 'users', ['id'], unique=False)
        op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)
        op.create_index(op.f('ix_users_full_name'), 'users', ['full_name'], unique=False)


def downgrade() -> None:
    op.drop_index(op.f('ix_users_full_name'), table_name='users')
    op.drop_index(op.f('ix_users_email'), table_name='users')
    op.drop_index(op.f('ix_users_id'), table_name='users')
    op.drop_table('users')
