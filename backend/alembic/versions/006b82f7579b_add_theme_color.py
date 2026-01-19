"""Add theme_color

Revision ID: 006b82f7579b
Revises: 20260106_add_refresh_tokens
Create Date: 2026-01-19 23:55:25.271303

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '006b82f7579b'
down_revision: Union[str, None] = '20260106_add_refresh_tokens'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('user_settings', sa.Column('theme_color', sa.String(), nullable=True))


def downgrade() -> None:
    op.drop_column('user_settings', 'theme_color')
