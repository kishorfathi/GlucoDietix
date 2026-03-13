-- GlucoDietix SQL Schema
-- Run this in your Supabase SQL Editor

-- 1. Create foods table (Enhanced for Sri Lankan Food Composition Database)
CREATE TABLE IF NOT EXISTS foods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Basic Information
  name TEXT NOT NULL,
  name_sinhala TEXT,
  name_tamil TEXT,
  category TEXT NOT NULL,
  sub_category TEXT,
  
  -- Macronutrients per 100g
  carbs_100g NUMERIC NOT NULL,
  protein_100g NUMERIC NOT NULL,
  fat_100g NUMERIC NOT NULL,
  fiber_100g NUMERIC DEFAULT 0,
  energy_kcal NUMERIC NOT NULL,
  
  -- Additional Macros
  sugar_100g NUMERIC,
  
  -- Micronutrients (mg unless specified)
  calcium_mg NUMERIC,
  iron_mg NUMERIC,
  vitamin_a_mcg NUMERIC,
  vitamin_c_mg NUMERIC,
  thiamin_mg NUMERIC,
  riboflavin_mg NUMERIC,
  niacin_mg NUMERIC,
  
  -- Health Markers
  glycemic_index NUMERIC,
  glycemic_load NUMERIC,
  cholesterol_mg NUMERIC,
  sodium_mg NUMERIC,
  potassium_mg NUMERIC,
  
  -- Additional Information
  edible_portion_percent NUMERIC DEFAULT 100,
  water_content_percent NUMERIC DEFAULT 0,
  serving_size_g NUMERIC DEFAULT 100,
  is_local BOOLEAN DEFAULT true,
  source TEXT DEFAULT 'foodcompositiondb.lk',
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
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
  username TEXT,
  diabetes BOOLEAN NOT NULL DEFAULT FALSE,
  glucose_range TEXT NOT NULL DEFAULT 'normal',
  cholesterol_concern BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT glucose_range_check CHECK (glucose_range IN ('low', 'normal', 'high'))
);

-- Optional extended clinical fields used by the profile form
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS username TEXT;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS glucose_unit TEXT DEFAULT 'mg/dL';
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS target_glucose_min NUMERIC DEFAULT 70;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS target_glucose_max NUMERIC DEFAULT 95;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS weight_kg NUMERIC DEFAULT 70;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS height_cm NUMERIC DEFAULT 170;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS diabetes_type TEXT DEFAULT 'Type 2';
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS treatment TEXT DEFAULT 'Diet';
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS update_frequency TEXT DEFAULT 'weekly';
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS dietary_preference TEXT DEFAULT 'none';
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS low_gi_preference BOOLEAN DEFAULT FALSE;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS low_sodium_preference BOOLEAN DEFAULT FALSE;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS last_updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 4. Enable Row Level Security (RLS)
ALTER TABLE foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE portions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for foods (public read)
DROP POLICY IF EXISTS "Foods are viewable by everyone" ON foods;
CREATE POLICY "Foods are viewable by everyone"
  ON foods FOR SELECT
  USING (true);

-- 6. RLS Policies for portions (public read)
DROP POLICY IF EXISTS "Portions are viewable by everyone" ON portions;
CREATE POLICY "Portions are viewable by everyone"
  ON portions FOR SELECT
  USING (true);

-- 7. RLS Policies for user_profiles (users can only see/edit their own)
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id);

-- 8. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_foods_name ON foods(name);
CREATE INDEX IF NOT EXISTS idx_foods_name_sinhala ON foods(name_sinhala);
CREATE INDEX IF NOT EXISTS idx_foods_name_tamil ON foods(name_tamil);
CREATE INDEX IF NOT EXISTS idx_foods_category ON foods(category);
CREATE INDEX IF NOT EXISTS idx_foods_sub_category ON foods(sub_category);
CREATE INDEX IF NOT EXISTS idx_foods_is_local ON foods(is_local);
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
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
BEFORE UPDATE ON user_profiles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 11. Create trigger for foods
DROP TRIGGER IF EXISTS update_foods_updated_at ON foods;
CREATE TRIGGER update_foods_updated_at
BEFORE UPDATE ON foods
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
