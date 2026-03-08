-- Add portions for any rice foods that don't have portions yet
-- Run this in Supabase SQL Editor

-- Add portions for "Rice (white, cooked)" if it exists
INSERT INTO portions (food_id, label, grams)
SELECT 
  id,
  portion_label,
  portion_grams
FROM foods
CROSS JOIN (
  VALUES 
    ('1 cup', 195),
    ('1/2 cup', 97.5),
    ('1 plate', 300),
    ('1 tablespoon', 15),
    ('1 small bowl', 150)
) AS portions(portion_label, portion_grams)
WHERE LOWER(name) LIKE '%rice%white%'
   OR LOWER(name) LIKE '%white%rice%'
   OR name = 'Rice (white, cooked)'
ON CONFLICT DO NOTHING;

-- Add portions for red rice if it exists
INSERT INTO portions (food_id, label, grams)
SELECT 
  id,
  portion_label,
  portion_grams
FROM foods
CROSS JOIN (
  VALUES 
    ('1 cup', 195),
    ('1/2 cup', 97.5),
    ('1 plate', 300),
    ('1 tablespoon', 15),
    ('1 small bowl', 150)
) AS portions(portion_label, portion_grams)
WHERE LOWER(name) LIKE '%rice%red%'
   OR LOWER(name) LIKE '%red%rice%'
ON CONFLICT DO NOTHING;

-- Add portions for all other rice foods
INSERT INTO portions (food_id, label, grams)
SELECT 
  id,
  portion_label,
  portion_grams
FROM foods
CROSS JOIN (
  VALUES 
    ('1 cup', 195),
    ('1/2 cup', 97.5),
    ('1 plate', 300),
    ('1 tablespoon', 15),
    ('1 small bowl', 150)
) AS portions(portion_label, portion_grams)
WHERE category = 'Staples' 
  AND LOWER(name) LIKE '%rice%'
  AND NOT EXISTS (
    SELECT 1 FROM portions p WHERE p.food_id = foods.id
  )
ON CONFLICT DO NOTHING;

-- Verify portions were added
SELECT 
  f.name,
  COUNT(p.id) as portion_count,
  STRING_AGG(p.label || ' (' || p.grams || 'g)', ', ' ORDER BY p.grams) as portions
FROM foods f
LEFT JOIN portions p ON f.id = p.food_id
WHERE LOWER(f.name) LIKE '%rice%'
GROUP BY f.name
ORDER BY f.name;
