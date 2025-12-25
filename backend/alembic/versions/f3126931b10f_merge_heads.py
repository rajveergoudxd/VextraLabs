"""merge_heads

Revision ID: f3126931b10f
Revises: 20241224_add_draft_fields, 20241225_add_likes_comments
Create Date: 2025-12-25 15:27:03.756267

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f3126931b10f'
down_revision: Union[str, None] = ('20241224_add_draft_fields', '20241225_add_likes_comments')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
