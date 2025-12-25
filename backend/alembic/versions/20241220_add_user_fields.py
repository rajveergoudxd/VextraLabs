"""add user profile fields

Revision ID: 20241220_add_user_fields
Revises: 
Create Date: 2024-12-20 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '20241220_add_user_fields'
down_revision = '00_initial_users'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add new columns to users table
    # We use nullable=True for all to avoid issues with existing rows
    conn = op.get_bind()
    from sqlalchemy import inspect
    try:
        inspector = inspect(conn)
        columns = [c['name'] for c in inspector.get_columns('users')]
    except (sa.exc.NoInspectionAvailable, NameError):
        # Offline mode: assume no columns exist so we generate add_column statements
        columns = []
    
    if 'username' not in columns:
        op.add_column('users', sa.Column('username', sa.String(), nullable=True))
        op.create_index(op.f('ix_users_username'), 'users', ['username'], unique=True)
    
    if 'bio' not in columns:
        op.add_column('users', sa.Column('bio', sa.String(), nullable=True))
    
    if 'profile_picture' not in columns:
        op.add_column('users', sa.Column('profile_picture', sa.String(), nullable=True))
    
    if 'instagram' not in columns:
        op.add_column('users', sa.Column('instagram', sa.String(), nullable=True))
    if 'linkedin' not in columns:
        op.add_column('users', sa.Column('linkedin', sa.String(), nullable=True))
    if 'twitter' not in columns:
        op.add_column('users', sa.Column('twitter', sa.String(), nullable=True))
    if 'facebook' not in columns:
        op.add_column('users', sa.Column('facebook', sa.String(), nullable=True))
    
    # integer fields with default 0
    if 'posts_count' not in columns:
        op.add_column('users', sa.Column('posts_count', sa.Integer(), server_default='0', nullable=True))
    if 'followers_count' not in columns:
        op.add_column('users', sa.Column('followers_count', sa.Integer(), server_default='0', nullable=True))
    if 'following_count' not in columns:
        op.add_column('users', sa.Column('following_count', sa.Integer(), server_default='0', nullable=True))


def downgrade() -> None:
    op.drop_column('users', 'following_count')
    op.drop_column('users', 'followers_count')
    op.drop_column('users', 'posts_count')
    
    op.drop_column('users', 'facebook')
    op.drop_column('users', 'twitter')
    op.drop_column('users', 'linkedin')
    op.drop_column('users', 'instagram')
    
    op.drop_column('users', 'profile_picture')
    op.drop_column('users', 'bio')
    
    op.drop_index(op.f('ix_users_username'), table_name='users')
    op.drop_column('users', 'username')
