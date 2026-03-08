-- Verification Script for Sri Lankan Food Database
-- Run this in Supabase SQL Editor after loading schema and seed data

-- ============================================================================
-- BASIC CHECKS
-- ============================================================================

SELECT '=== DATABASE VERIFICATION ===' as info;

-- Check total foods
SELECT 
  'Total Foods Loaded' as metric, 
  COUNT(*) as count,
  CASE 
    WHEN COUNT(*) >= 70 THEN '✓ PASS'
    ELSE '✗ FAIL - Expected 70+'
  END as status
FROM foods;

-- Check total portions
SELECT 
  'Total Portions Loaded' as metric, 
  COUNT(*) as count,
  CASE 
    WHEN COUNT(*) >= 100 THEN '✓ PASS'
    ELSE '✗ FAIL - Expected 100+'
  END as status
FROM portions;

-- ============================================================================
-- CATEGORY BREAKDOWN
-- ============================================================================

SELECT '=== FOODS BY CATEGORY ===' as info;

SELECT 
  category,
  COUNT(*) as food_count,
  COUNT(DISTINCT sub_category) as subcategories
FROM foods
GROUP BY category
ORDER BY food_count DESC;

-- ============================================================================
-- LANGUAGE SUPPORT CHECK
-- ============================================================================

SELECT '=== MULTILINGUAL SUPPORT ===' as info;

SELECT 
  'English Names' as language,
  COUNT(*) as count,
  CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM foods) THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM foods WHERE name IS NOT NULL
UNION ALL
SELECT 
  'Sinhala Names' as language,
  COUNT(*) as count,
  CASE WHEN COUNT(*) >= 60 THEN '✓ PASS' ELSE '⚠ WARNING' END as status
FROM foods WHERE name_sinhala IS NOT NULL
UNION ALL
SELECT 
  'Tamil Names' as language,
  COUNT(*) as count,
  CASE WHEN COUNT(*) >= 60 THEN '✓ PASS' ELSE '⚠ WARNING' END as status
FROM foods WHERE name_tamil IS NOT NULL;

-- ============================================================================
-- NUTRITIONAL DATA COMPLETENESS
-- ============================================================================

SELECT '=== NUTRITIONAL DATA COMPLETENESS ===' as info;

SELECT 
  'Required Macros' as check_type,
  COUNT(*) as complete_records,
  CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM foods) THEN '✓ PASS' ELSE '✗ FAIL' END as status
FROM foods 
WHERE carbs_100g IS NOT NULL 
  AND protein_100g IS NOT NULL 
  AND fat_100g IS NOT NULL 
  AND energy_kcal IS NOT NULL;

SELECT 
  'Fiber Data' as nutrient,
  COUNT(*) as records_with_data,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM foods), 1) as percentage
FROM foods WHERE fiber_100g IS NOT NULL AND fiber_100g > 0;

SELECT 
  'Glycemic Index' as nutrient,
  COUNT(*) as records_with_data,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM foods), 1) as percentage
FROM foods WHERE glycemic_index IS NOT NULL;

SELECT 
  'Calcium' as nutrient,
  COUNT(*) as records_with_data,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM foods), 1) as percentage
FROM foods WHERE calcium_mg IS NOT NULL;

SELECT 
  'Iron' as nutrient,
  COUNT(*) as records_with_data,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM foods), 1) as percentage
FROM foods WHERE iron_mg IS NOT NULL;

-- ============================================================================
-- SAMPLE FOODS CHECK
-- ============================================================================

SELECT '=== SAMPLE FOODS (verify names appear correctly) ===' as info;

SELECT 
  name as english_name,
  name_sinhala as sinhala_name,
  name_tamil as tamil_name,
  category,
  energy_kcal as kcal,
  glycemic_index as gi
FROM foods
WHERE name IN (
  'White Rice (Cooked)',
  'String Hoppers (Idiyappam)',
  'Pol Sambol (Coconut Sambol)',
  'Dhal Curry (Parippu)',
  'Chicken Curry'
)
ORDER BY name;

-- ============================================================================
-- PORTION SIZES CHECK
-- ============================================================================

SELECT '=== SAMPLE PORTIONS (verify traditional measurements) ===' as info;

SELECT 
  f.name as food_name,
  p.label as portion_label,
  p.grams as portion_grams
FROM portions p
JOIN foods f ON p.food_id = f.id
WHERE f.name = 'White Rice (Cooked)'
ORDER BY p.grams;

-- ============================================================================
-- GLYCEMIC INDEX DISTRIBUTION
-- ============================================================================

SELECT '=== GLYCEMIC INDEX DISTRIBUTION ===' as info;

SELECT 
  CASE 
    WHEN glycemic_index IS NULL THEN 'No GI Data'
    WHEN glycemic_index <= 55 THEN 'Low GI (≤55) - Diabetes Friendly'
    WHEN glycemic_index <= 69 THEN 'Medium GI (56-69)'
    ELSE 'High GI (≥70)'
  END as gi_category,
  COUNT(*) as food_count
FROM foods
GROUP BY 
  CASE 
    WHEN glycemic_index IS NULL THEN 'No GI Data'
    WHEN glycemic_index <= 55 THEN 'Low GI (≤55) - Diabetes Friendly'
    WHEN glycemic_index <= 69 THEN 'Medium GI (56-69)'
    ELSE 'High GI (≥70)'
  END
ORDER BY 
  CASE 
    WHEN glycemic_index IS NULL THEN 4
    WHEN glycemic_index <= 55 THEN 1
    WHEN glycemic_index <= 69 THEN 2
    ELSE 3
  END;

-- ============================================================================
-- TABLE INDEXES CHECK
-- ============================================================================

SELECT '=== DATABASE INDEXES ===' as info;

SELECT 
  schemaname,
  tablename,
  indexname
FROM pg_indexes
WHERE tablename IN ('foods', 'portions', 'user_profiles')
  AND schemaname = 'public'
ORDER BY tablename, indexname;

-- ============================================================================
-- ROW LEVEL SECURITY CHECK
-- ============================================================================

SELECT '=== ROW LEVEL SECURITY ===' as info;

SELECT 
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename IN ('foods', 'portions', 'user_profiles')
  AND schemaname = 'public';

-- ============================================================================
-- FINAL SUMMARY
-- ============================================================================

SELECT '=== FINAL SUMMARY ===' as info;

SELECT 
  'Database Status' as item,
  CASE 
    WHEN (SELECT COUNT(*) FROM foods) >= 70 
     AND (SELECT COUNT(*) FROM portions) >= 100
     AND (SELECT COUNT(*) FROM foods WHERE name IS NOT NULL) = (SELECT COUNT(*) FROM foods)
    THEN '✓ READY TO USE'
    ELSE '⚠ CHECK WARNINGS ABOVE'
  END as status;

-- ============================================================================
-- RECOMMENDATIONS
-- ============================================================================

SELECT '=== RECOMMENDATIONS ===' as info;

SELECT 
  '1. Test food search in app' as recommendation
UNION ALL
SELECT '2. Verify Sinhala/Tamil text displays correctly'
UNION ALL
SELECT '3. Check GI values for diabetes management'
UNION ALL
SELECT '4. Test portion selection with traditional units'
UNION ALL
SELECT '5. See FOODDB_GUIDE.md for usage examples';
