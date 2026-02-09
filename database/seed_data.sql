-- Sample Sri Lankan Food Data
-- Run this AFTER creating the schema
-- This provides 5 foods and 10 portions as examples

-- Insert Sample Foods
INSERT INTO foods (name, category, kcal_100g, carbs_100g, protein_100g, fat_100g, fiber_100g, sugar_100g) VALUES
('White Rice (Cooked)', 'Staples', 130, 28.2, 2.7, 0.3, 0.4, 0.1),
('String Hoppers (Idiyappam)', 'Staples', 108, 24.0, 2.0, 0.1, 1.0, 0.2),
('Pol Sambol', 'Condiments', 180, 8.5, 2.0, 15.0, 3.0, 3.5),
('Dhal Curry', 'Curries', 116, 18.0, 8.0, 2.0, 5.0, 1.5),
('Parippu (Red Lentils)', 'Curries', 116, 20.0, 9.0, 0.4, 8.0, 2.0);

-- Get the food IDs (you'll need to run the above first, then get IDs from Supabase)
-- For this example, we'll use the food names to create portions

-- Insert Sample Portions for White Rice
INSERT INTO portions (food_id, label, grams)
SELECT id, '1 cup', 195
FROM foods WHERE name = 'White Rice (Cooked)'
UNION ALL
SELECT id, '1/2 cup', 97.5
FROM foods WHERE name = 'White Rice (Cooked)';

-- Insert Sample Portions for String Hoppers
INSERT INTO portions (food_id, label, grams)
SELECT id, '2 hoppers', 70
FROM foods WHERE name = 'String Hoppers (Idiyappam)'
UNION ALL
SELECT id, '3 hoppers', 105
FROM foods WHERE name = 'String Hoppers (Idiyappam)';

-- Insert Sample Portions for Pol Sambol
INSERT INTO portions (food_id, label, grams)
SELECT id, '1 tablespoon', 20
FROM foods WHERE name = 'Pol Sambol'
UNION ALL
SELECT id, '2 tablespoons', 40
FROM foods WHERE name = 'Pol Sambol';

-- Insert Sample Portions for Dhal Curry
INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 120
FROM foods WHERE name = 'Dhal Curry'
UNION ALL
SELECT id, '1 cup', 240
FROM foods WHERE name = 'Dhal Curry';

-- Insert Sample Portions for Parippu
INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 100
FROM foods WHERE name = 'Parippu (Red Lentils)'
UNION ALL
SELECT id, '1 cup', 200
FROM foods WHERE name = 'Parippu (Red Lentils)';

-- Verify data
SELECT 'Foods Count:' as info, COUNT(*) as count FROM foods
UNION ALL
SELECT 'Portions Count:' as info, COUNT(*) as count FROM portions;
