-- SQL Migration to add missing 'theme_color' column
-- Run this in your Cloud SQL instance query editor or via psql

-- Add the missing column
ALTER TABLE user_settings ADD COLUMN theme_color VARCHAR;
