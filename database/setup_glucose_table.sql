-- Quick Setup: Create glucose_readings table
-- Run this in your Supabase SQL Editor

-- 1. Create glucose_readings table
CREATE TABLE IF NOT EXISTS glucose_readings (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  glucose_level DECIMAL(5,1) NOT NULL CHECK (glucose_level > 0 AND glucose_level < 600),
  timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reading_type TEXT NOT NULL CHECK (reading_type IN ('fasting', 'before_meal', 'after_meal', 'random')),
  meal_id TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_glucose_user_timestamp ON glucose_readings(user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_glucose_reading_type ON glucose_readings(reading_type);

-- 3. Enable Row Level Security
ALTER TABLE glucose_readings ENABLE ROW LEVEL SECURITY;

-- 4. Create RLS policies
DROP POLICY IF EXISTS "Users can view own glucose readings" ON glucose_readings;
CREATE POLICY "Users can view own glucose readings" ON glucose_readings
  FOR SELECT USING (auth.uid()::text = user_id);

DROP POLICY IF EXISTS "Users can insert own glucose readings" ON glucose_readings;
CREATE POLICY "Users can insert own glucose readings" ON glucose_readings
  FOR INSERT WITH CHECK (auth.uid()::text = user_id);

DROP POLICY IF EXISTS "Users can update own glucose readings" ON glucose_readings;
CREATE POLICY "Users can update own glucose readings" ON glucose_readings
  FOR UPDATE USING (auth.uid()::text = user_id);
