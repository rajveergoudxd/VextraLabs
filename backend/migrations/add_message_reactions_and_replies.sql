-- Migration: Add reply, reactions, and edit support to messages
-- Run this against your database

-- Add reply support to messages
ALTER TABLE messages ADD COLUMN IF NOT EXISTS reply_to_id INTEGER REFERENCES messages(id) ON DELETE SET NULL;

-- Add edit tracking to messages  
ALTER TABLE messages ADD COLUMN IF NOT EXISTS edited_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS original_content TEXT;

-- Create index for reply lookups
CREATE INDEX IF NOT EXISTS idx_message_reply_to_id ON messages(reply_to_id);

-- Create reactions table
CREATE TABLE IF NOT EXISTS message_reactions (
    id SERIAL PRIMARY KEY,
    message_id INTEGER NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    emoji VARCHAR(10) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT uq_message_user_emoji UNIQUE(message_id, user_id, emoji)
);

-- Create indexes for reactions
CREATE INDEX IF NOT EXISTS idx_reaction_message_id ON message_reactions(message_id);
CREATE INDEX IF NOT EXISTS idx_reaction_user_id ON message_reactions(user_id);
