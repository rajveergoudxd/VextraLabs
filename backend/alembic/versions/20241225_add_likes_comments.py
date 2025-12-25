"""Add likes, comments tables and share_token to posts

Revision ID: 20241225_add_likes_comments
Revises: add_missing_tables_20241224
Create Date: 2025-12-25

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '20241225_add_likes_comments'
down_revision = 'add_missing_tables_20241224'
branch_labels = None
depends_on = None


def upgrade():
    # Create likes table
    op.create_table(
        'likes',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('post_id', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['post_id'], ['posts.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'post_id', name='uq_user_post_like')
    )
    op.create_index('idx_like_user_id', 'likes', ['user_id'])
    op.create_index('idx_like_post_id', 'likes', ['post_id'])
    
    # Create comments table
    op.create_table(
        'comments',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('post_id', sa.Integer(), nullable=False),
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['post_id'], ['posts.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('idx_comment_post_id', 'comments', ['post_id'])
    op.create_index('idx_comment_user_id', 'comments', ['user_id'])
    op.create_index('idx_comment_created_at', 'comments', ['created_at'])
    
    # Add share_token column to posts table
    op.add_column('posts', sa.Column('share_token', sa.String(32), nullable=True))
    op.create_index('ix_posts_share_token', 'posts', ['share_token'], unique=True)
    
    # Add shared_post_id column to messages table
    op.add_column('messages', sa.Column('shared_post_id', sa.Integer(), nullable=True))
    op.create_foreign_key(
        'fk_messages_shared_post_id',
        'messages', 'posts',
        ['shared_post_id'], ['id'],
        ondelete='SET NULL'
    )


def downgrade():
    # Remove shared_post_id from messages
    op.drop_constraint('fk_messages_shared_post_id', 'messages', type_='foreignkey')
    op.drop_column('messages', 'shared_post_id')
    
    # Remove share_token from posts
    op.drop_index('ix_posts_share_token', 'posts')
    op.drop_column('posts', 'share_token')
    
    # Drop comments table
    op.drop_index('idx_comment_created_at', 'comments')
    op.drop_index('idx_comment_user_id', 'comments')
    op.drop_index('idx_comment_post_id', 'comments')
    op.drop_table('comments')
    
    # Drop likes table
    op.drop_index('idx_like_post_id', 'likes')
    op.drop_index('idx_like_user_id', 'likes')
    op.drop_table('likes')
