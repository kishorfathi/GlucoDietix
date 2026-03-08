-- Clean Up Script for GlucoDietix Database
-- Run this ONLY if you want to completely reset the database
-- WARNING: This will DELETE ALL DATA!

-- Drop triggers
DROP TRIGGER IF EXISTS update_foods_updated_at ON foods;
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;

-- Drop function
DROP FUNCTION IF EXISTS update_updated_at_column();

-- Drop indexes
DROP INDEX IF EXISTS idx_portions_food_id;
DROP INDEX IF EXISTS idx_foods_is_local;
DROP INDEX IF EXISTS idx_foods_sub_category;
DROP INDEX IF EXISTS idx_foods_category;
DROP INDEX IF EXISTS idx_foods_name_tamil;
DROP INDEX IF EXISTS idx_foods_name_sinhala;
DROP INDEX IF EXISTS idx_foods_name;

-- Drop policies
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Portions are viewable by everyone" ON portions;
DROP POLICY IF EXISTS "Foods are viewable by everyone" ON foods;

-- Drop tables (CASCADE will also drop portions table)
DROP TABLE IF EXISTS portions CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;
DROP TABLE IF EXISTS foods CASCADE;

-- Verification
SELECT 'Database cleaned successfully!' as message;
SELECT 'Now run schema.sql to recreate the structure' as next_step;
