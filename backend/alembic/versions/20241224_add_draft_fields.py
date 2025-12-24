"""add draft fields to posts

Revision ID: 20241224_add_draft_fields
Revises: add_missing_tables_20241224
Create Date: 2024-12-24 20:30:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '20241224_add_draft_fields'
down_revision = 'add_missing_tables_20241224'
branch_labels = None
depends_on = None


def upgrade():
    # Add draft-related columns to posts table
    op.add_column('posts', sa.Column('is_draft', sa.Boolean(), nullable=True, server_default='false'))
    op.add_column('posts', sa.Column('title', sa.String(), nullable=True))
    op.add_column('posts', sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True))
    
    # Create index on is_draft for efficient filtering
    op.create_index('ix_posts_is_draft', 'posts', ['is_draft'])


def downgrade():
    op.drop_index('ix_posts_is_draft', table_name='posts')
    op.drop_column('posts', 'updated_at')
    op.drop_column('posts', 'title')
    op.drop_column('posts', 'is_draft')
