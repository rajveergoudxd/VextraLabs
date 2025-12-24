"""add_fcm_token_to_users

Revision ID: add_fcm_token_20241224
Revises: f2df874b7aec
Create Date: 2024-12-24 11:10:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'add_fcm_token_20241224'
down_revision: Union[str, None] = 'f2df874b7aec'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add fcm_token column to users table
    op.add_column('users', sa.Column('fcm_token', sa.String(), nullable=True))


def downgrade() -> None:
    # Remove fcm_token column from users table
    op.drop_column('users', 'fcm_token')
