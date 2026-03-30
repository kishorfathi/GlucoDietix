-- =====================================================
-- GlucoDietix Supabase Database Schema
-- =====================================================
--
-- Complete database schema for GlucoDietix nutrition app.
-- Includes foods table with comprehensive nutrition data
-- and sample Sri Lankan food entries.
--
-- SETUP INSTRUCTIONS:
-- 1. Go to your Supabase project dashboard
-- 2. Navigate to SQL Editor
-- 3. Paste this entire SQL file
-- 4. Click "Run" to execute
--
-- =====================================================

-- =====================================================
-- 1. FOODS TABLE - Main nutrition database
-- =====================================================

CREATE TABLE IF NOT EXISTS foods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_sinhala TEXT,
    name_tamil TEXT,
    category TEXT NOT NULL,
    sub_category TEXT,

    -- Macronutrients per 100g
    carbs_100g DECIMAL(10, 2) NOT NULL DEFAULT 0,
    protein_100g DECIMAL(10, 2) NOT NULL DEFAULT 0,
    fat_100g DECIMAL(10, 2) NOT NULL DEFAULT 0,
    fiber_100g DECIMAL(10, 2) NOT NULL DEFAULT 0,
    energy_kcal DECIMAL(10, 2) NOT NULL DEFAULT 0,

    -- Health markers (important for diabetics)
    glycemic_index DECIMAL(5, 1),
    glycemic_load DECIMAL(5, 1),
    cholesterol_mg DECIMAL(10, 2),
    sodium_mg DECIMAL(10, 2),
    potassium_mg DECIMAL(10, 2),

    -- Serving info
    serving_size_g DECIMAL(10, 2) DEFAULT 100,
    is_local BOOLEAN DEFAULT true,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 2. USER PROFILES TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    email TEXT,
    full_name TEXT,
    diabetes BOOLEAN DEFAULT false,
    cholesterol_concern BOOLEAN DEFAULT false,
    glucose_range TEXT DEFAULT 'Normal',
    weight_kg DECIMAL(5, 1),
    height_cm DECIMAL(5, 1),
    target_glucose_min DECIMAL(5, 1),
    target_glucose_max DECIMAL(5, 1),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 3. GLUCOSE READINGS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS glucose_readings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    glucose_level DECIMAL(5, 1) NOT NULL,
    reading_type TEXT DEFAULT 'random',
    notes TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 4. MEAL HISTORY TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS meal_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    meal_type TEXT,
    foods JSONB,
    total_calories DECIMAL(10, 2),
    total_carbs DECIMAL(10, 2),
    total_protein DECIMAL(10, 2),
    total_fat DECIMAL(10, 2),
    health_score INTEGER,
    warnings TEXT[],
    recommendations TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 5. INDEXES
-- =====================================================

CREATE INDEX IF NOT EXISTS idx_foods_name ON foods(name);
CREATE INDEX IF NOT EXISTS idx_foods_category ON foods(category);
CREATE INDEX IF NOT EXISTS idx_glucose_user ON glucose_readings(user_id);
CREATE INDEX IF NOT EXISTS idx_meal_user ON meal_history(user_id);

-- =====================================================
-- 6. ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE foods ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE glucose_readings ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_history ENABLE ROW LEVEL SECURITY;

-- Foods: Public read access
CREATE POLICY "Anyone can read foods" ON foods
    FOR SELECT USING (true);

-- User profiles: Users can read/write their own profile
CREATE POLICY "Users can view own profile" ON user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Glucose readings: Users can manage their own readings
CREATE POLICY "Users can manage own glucose readings" ON glucose_readings
    FOR ALL USING (auth.uid() = user_id);

-- Meal history: Users can manage their own meal history
CREATE POLICY "Users can manage own meals" ON meal_history
    FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- 7. SAMPLE DATA - Sri Lankan Foods
-- =====================================================

INSERT INTO foods (name, name_sinhala, category, carbs_100g, protein_100g, fat_100g, fiber_100g, energy_kcal, glycemic_index, serving_size_g)
VALUES
    -- Rice varieties
    ('White Rice Boiled', 'සුදු බත්', 'Staples', 28.0, 2.7, 0.3, 0.4, 130, 73, 150),
    ('Red Rice Boiled', 'රතු බත්', 'Staples', 25.5, 3.0, 0.8, 1.8, 125, 55, 150),
    ('Basmati Rice Boiled', 'බාස්මතී බත්', 'Staples', 25.0, 3.5, 0.5, 0.6, 120, 58, 150),

    -- Bread alternatives
    ('String Hoppers', 'ඉදිආප්ප', 'Staples', 24.0, 3.2, 0.8, 1.0, 110, 60, 100),
    ('Pittu', 'පිට්ටු', 'Staples', 25.0, 3.8, 1.5, 2.0, 125, 55, 120),
    ('Hoppers', 'ආප්ප', 'Staples', 22.0, 2.5, 2.0, 0.8, 115, 65, 80),
    ('Roti', 'රොටී', 'Staples', 42.0, 6.5, 8.5, 2.5, 265, 62, 100),

    -- Curries - Protein
    ('Chicken Curry', 'කුකුල් මස් කරි', 'Curries', 3.0, 14.0, 9.0, 0.5, 150, NULL, 200),
    ('Fish Curry', 'මාළු කරි', 'Curries', 2.5, 13.0, 6.0, 0.3, 115, NULL, 200),
    ('Dhal Curry Thick', 'පරිප්පු කරි', 'Curries', 16.0, 6.0, 3.0, 4.0, 115, 42, 150),
    ('Egg Curry', 'බිත්තර කරි', 'Curries', 2.0, 6.5, 5.5, 0.2, 85, NULL, 120),

    -- Vegetable curries
    ('Potato Curry', 'අල කරි', 'Curries', 17.0, 2.0, 3.5, 2.0, 100, 63, 150),
    ('Beans Curry', 'බෝංචි කරි', 'Curries', 11.0, 4.5, 3.0, 3.5, 85, 30, 150),
    ('Pumpkin Curry', 'වට්ටක්කා කරි', 'Curries', 8.0, 1.0, 2.0, 1.5, 50, 64, 150),
    ('Brinjal Curry', 'වම්බටු කරි', 'Curries', 8.0, 1.5, 3.5, 2.5, 65, 15, 150),

    -- Mallum and sambols
    ('Gotukola Mallum', 'ගොටුකොළ මැල්ලුම්', 'Vegetables', 5.0, 2.5, 3.0, 2.5, 55, NULL, 100),
    ('Pol Sambol', 'පොල් සම්බෝල්', 'Condiments', 12.0, 3.0, 24.0, 9.0, 270, NULL, 50),
    ('Papadam', 'පාපඩම්', 'Condiments', 18.0, 4.5, 8.5, 2.0, 165, NULL, 30),

    -- Fruits
    ('Banana Ripe', 'ඉදුණු කෙසෙල්', 'Fruits', 23.0, 1.1, 0.3, 2.6, 89, 51, 120),
    ('Papaya Ripe', 'ගස්ලබු', 'Fruits', 10.0, 0.5, 0.1, 1.7, 43, 59, 150),
    ('Mango Ripe', 'අඹ', 'Fruits', 15.0, 0.5, 0.3, 1.8, 65, 56, 150),

    -- Beverages
    ('Plain Tea', 'තේ', 'Beverages', 0.2, 0.1, 0.0, 0.0, 1, 0, 250),
    ('Milk Tea', 'කිරි තේ', 'Beverages', 4.5, 2.0, 1.5, 0.0, 40, NULL, 250)

ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 8. UPDATE TRIGGER
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_foods_updated_at
    BEFORE UPDATE ON foods
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- VERIFICATION (uncomment to test)
-- =====================================================

-- SELECT COUNT(*) as total_foods FROM foods;
-- SELECT name, glycemic_index, energy_kcal FROM foods ORDER BY name;
