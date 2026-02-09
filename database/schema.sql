-- GlucoDietix SQL Schema
-- Run this in your Supabase SQL Editor

-- 1. Create foods table
CREATE TABLE IF NOT EXISTS foods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  kcal_100g NUMERIC NOT NULL,
  carbs_100g NUMERIC NOT NULL,
  protein_100g NUMERIC NOT NULL,
  fat_100g NUMERIC NOT NULL,
  fiber_100g NUMERIC NULL,
  sugar_100g NUMERIC NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create portions table
CREATE TABLE IF NOT EXISTS portions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  food_id UUID NOT NULL REFERENCES foods(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  grams NUMERIC NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  diabetes BOOLEAN NOT NULL DEFAULT FALSE,
  glucose_range TEXT NOT NULL DEFAULT 'normal',
  cholesterol_concern BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT glucose_range_check CHECK (glucose_range IN ('low', 'normal', 'high'))
);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE portions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for foods (public read)
CREATE POLICY "Foods are viewable by everyone"
  ON foods FOR SELECT
  USING (true);

-- 6. RLS Policies for portions (public read)
CREATE POLICY "Portions are viewable by everyone"
  ON portions FOR SELECT
  USING (true);

-- 7. RLS Policies for user_profiles (users can only see/edit their own)
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id);

-- 8. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_foods_name ON foods(name);
CREATE INDEX IF NOT EXISTS idx_foods_category ON foods(category);
CREATE INDEX IF NOT EXISTS idx_portions_food_id ON portions(food_id);

-- 9. Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 10. Create trigger for user_profiles
CREATE TRIGGER update_user_profiles_updated_at
BEFORE UPDATE ON user_profiles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
