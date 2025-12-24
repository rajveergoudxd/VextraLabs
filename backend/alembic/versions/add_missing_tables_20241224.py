"""add_missing_tables

Revision ID: add_missing_tables_20241224
Revises: add_fcm_token_20241224
Create Date: 2024-12-24 11:45:00.000000

This migration adds all tables that were missing from previous migrations:
- posts table (for feed/inspire section)
- otps table (for OTP verification)
- notifications table (for push notifications)
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect


# revision identifiers, used by Alembic.
revision: str = 'add_missing_tables_20241224'
down_revision: Union[str, None] = 'add_fcm_token_20241224'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def table_exists(table_name: str) -> bool:
    """Check if a table exists in the database."""
    conn = op.get_bind()
    inspector = inspect(conn)
    return table_name in inspector.get_table_names()


def upgrade() -> None:
    # Create posts table if it doesn't exist
    if not table_exists('posts'):
        op.create_table('posts',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('user_id', sa.Integer(), nullable=True),
            sa.Column('content', sa.Text(), nullable=True),
            sa.Column('media_urls', sa.JSON(), nullable=True),
            sa.Column('platforms', sa.JSON(), nullable=True),
            sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
            sa.Column('published_at', sa.DateTime(timezone=True), nullable=True),
            sa.Column('likes_count', sa.Integer(), server_default='0', nullable=True),
            sa.Column('comments_count', sa.Integer(), server_default='0', nullable=True),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index(op.f('ix_posts_id'), 'posts', ['id'], unique=False)
        op.create_index('idx_posts_user_id', 'posts', ['user_id'], unique=False)
        op.create_index('idx_posts_created_at', 'posts', ['created_at'], unique=False)

    # Create otps table if it doesn't exist
    if not table_exists('otps'):
        op.create_table('otps',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('email', sa.String(), nullable=False),
            sa.Column('code', sa.String(), nullable=False),
            sa.Column('purpose', sa.String(), nullable=False),
            sa.Column('expires_at', sa.DateTime(timezone=True), nullable=False),
            sa.Column('is_verified', sa.Boolean(), server_default='false', nullable=True),
            sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index(op.f('ix_otps_id'), 'otps', ['id'], unique=False)
        op.create_index(op.f('ix_otps_email'), 'otps', ['email'], unique=False)

    # Create notifications table if it doesn't exist
    if not table_exists('notifications'):
        op.create_table('notifications',
            sa.Column('id', sa.Integer(), nullable=False),
            sa.Column('user_id', sa.Integer(), nullable=False),
            sa.Column('actor_id', sa.Integer(), nullable=True),
            sa.Column('type', sa.String(50), nullable=False, server_default='system'),
            sa.Column('title', sa.String(255), nullable=True),
            sa.Column('message', sa.String(500), nullable=False),
            sa.Column('related_id', sa.Integer(), nullable=True),
            sa.Column('related_type', sa.String(50), nullable=True),
            sa.Column('content_image_url', sa.String(500), nullable=True),
            sa.Column('is_read', sa.Boolean(), server_default='false', nullable=False),
            sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=True),
            sa.Column('read_at', sa.DateTime(timezone=True), nullable=True),
            sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
            sa.ForeignKeyConstraint(['actor_id'], ['users.id'], ondelete='CASCADE'),
            sa.PrimaryKeyConstraint('id')
        )
        op.create_index(op.f('ix_notifications_id'), 'notifications', ['id'], unique=False)
        op.create_index('idx_notification_user_created', 'notifications', ['user_id', 'created_at'], unique=False)
        op.create_index('idx_notification_user_unread', 'notifications', ['user_id', 'is_read'], unique=False)


def downgrade() -> None:
    # Drop notifications table
    op.drop_index('idx_notification_user_unread', table_name='notifications')
    op.drop_index('idx_notification_user_created', table_name='notifications')
    op.drop_index(op.f('ix_notifications_id'), table_name='notifications')
    op.drop_table('notifications')
    
    # Drop otps table
    op.drop_index(op.f('ix_otps_email'), table_name='otps')
    op.drop_index(op.f('ix_otps_id'), table_name='otps')
    op.drop_table('otps')
    
    # Drop posts table
    op.drop_index('idx_posts_created_at', table_name='posts')
    op.drop_index('idx_posts_user_id', table_name='posts')
    op.drop_index(op.f('ix_posts_id'), table_name='posts')
    op.drop_table('posts')
