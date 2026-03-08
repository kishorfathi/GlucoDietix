-- Add Missing Portions for All Foods
-- This adds standard portions for all foods that don't have any

-- ============================================================================
-- VEGETABLE CURRIES (missing portions)
-- ============================================================================

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 120 FROM foods WHERE name = 'Potato Curry'
UNION ALL SELECT id, '1 cup', 240 FROM foods WHERE name = 'Potato Curry'
UNION ALL SELECT id, '1 ladle', 150 FROM foods WHERE name = 'Potato Curry';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 120 FROM foods WHERE name = 'Pumpkin Curry (Watakka)'
UNION ALL SELECT id, '1 cup', 240 FROM foods WHERE name = 'Pumpkin Curry (Watakka)'
UNION ALL SELECT id, '1 ladle', 150 FROM foods WHERE name = 'Pumpkin Curry (Watakka)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 120 FROM foods WHERE name = 'Jackfruit Curry (Polos)'
UNION ALL SELECT id, '1 cup', 240 FROM foods WHERE name = 'Jackfruit Curry (Polos)'
UNION ALL SELECT id, '1 ladle', 150 FROM foods WHERE name = 'Jackfruit Curry (Polos)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 120 FROM foods WHERE name = 'Brinjal Curry (Wambatu)'
UNION ALL SELECT id, '1 cup', 240 FROM foods WHERE name = 'Brinjal Curry (Wambatu)'
UNION ALL SELECT id, '1 ladle', 120 FROM foods WHERE name = 'Brinjal Curry (Wambatu)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 120 FROM foods WHERE name = 'Green Bean Curry (Bonchi)'
UNION ALL SELECT id, '1 cup', 240 FROM foods WHERE name = 'Green Bean Curry (Bonchi)'
UNION ALL SELECT id, '1 ladle', 120 FROM foods WHERE name = 'Green Bean Curry (Bonchi)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 120 FROM foods WHERE name = 'Cabbage Curry (Gova)'
UNION ALL SELECT id, '1 cup', 240 FROM foods WHERE name = 'Cabbage Curry (Gova)'
UNION ALL SELECT id, '1 ladle', 120 FROM foods WHERE name = 'Cabbage Curry (Gova)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 120 FROM foods WHERE name = 'Carrot Curry'
UNION ALL SELECT id, '1 cup', 240 FROM foods WHERE name = 'Carrot Curry'
UNION ALL SELECT id, '1 ladle', 120 FROM foods WHERE name = 'Carrot Curry';

-- BEETROOT CURRY (the one you're looking for!)
INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 120 FROM foods WHERE name = 'Beetroot Curry'
UNION ALL SELECT id, '1 cup', 240 FROM foods WHERE name = 'Beetroot Curry'
UNION ALL SELECT id, '1 ladle', 120 FROM foods WHERE name = 'Beetroot Curry';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 120 FROM foods WHERE name = 'Leeks Curry'
UNION ALL SELECT id, '1 cup', 240 FROM foods WHERE name = 'Leeks Curry'
UNION ALL SELECT id, '1 ladle', 120 FROM foods WHERE name = 'Leeks Curry';

-- ============================================================================
-- MEAT & SEAFOOD CURRIES (missing portions)
-- ============================================================================

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 120 FROM foods WHERE name = 'Egg Curry'
UNION ALL SELECT id, '1 cup', 240 FROM foods WHERE name = 'Egg Curry'
UNION ALL SELECT id, '1 egg', 100 FROM foods WHERE name = 'Egg Curry';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 100 FROM foods WHERE name = 'Dried Fish Curry (Karawala)'
UNION ALL SELECT id, '1 piece', 80 FROM foods WHERE name = 'Dried Fish Curry (Karawala)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 120 FROM foods WHERE name = 'Beef Curry'
UNION ALL SELECT id, '1 cup', 240 FROM foods WHERE name = 'Beef Curry'
UNION ALL SELECT id, '1 piece', 150 FROM foods WHERE name = 'Beef Curry';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 120 FROM foods WHERE name = 'Pork Curry'
UNION ALL SELECT id, '1 cup', 240 FROM foods WHERE name = 'Pork Curry'
UNION ALL SELECT id, '1 piece', 150 FROM foods WHERE name = 'Pork Curry';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 120 FROM foods WHERE name = 'Prawn Curry (Isso)'
UNION ALL SELECT id, '1 cup', 240 FROM foods WHERE name = 'Prawn Curry (Isso)'
UNION ALL SELECT id, '5 prawns', 100 FROM foods WHERE name = 'Prawn Curry (Isso)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 120 FROM foods WHERE name = 'Crab Curry (Kakuluwo)'
UNION ALL SELECT id, '1 cup', 240 FROM foods WHERE name = 'Crab Curry (Kakuluwo)'
UNION ALL SELECT id, '1 crab', 150 FROM foods WHERE name = 'Crab Curry (Kakuluwo)';

-- ============================================================================
-- SAMBOLS (missing portions)
-- ============================================================================

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 tablespoon', 15 FROM foods WHERE name = 'Katta Sambol (Maldive Fish Sambol)'
UNION ALL SELECT id, '2 tablespoons', 30 FROM foods WHERE name = 'Katta Sambol (Maldive Fish Sambol)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '2 tablespoons', 30 FROM foods WHERE name = 'Gotukola Sambol'
UNION ALL SELECT id, '1/4 cup', 50 FROM foods WHERE name = 'Gotukola Sambol';

-- ============================================================================
-- MALLUMS (missing portions)
-- ============================================================================

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 100 FROM foods WHERE name = 'Mukunuwenna Mallum'
UNION ALL SELECT id, '1 cup', 200 FROM foods WHERE name = 'Mukunuwenna Mallum';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 100 FROM foods WHERE name = 'Pol Mallum (Coconut Stir-fry)'
UNION ALL SELECT id, '1 cup', 200 FROM foods WHERE name = 'Pol Mallum (Coconut Stir-fry)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 100 FROM foods WHERE name = 'Hathawariya Mallum'
UNION ALL SELECT id, '1 cup', 200 FROM foods WHERE name = 'Hathawariya Mallum';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 100 FROM foods WHERE name = 'Kohila Mallum'
UNION ALL SELECT id, '1 cup', 200 FROM foods WHERE name = 'Kohila Mallum';

-- ============================================================================
-- ROTI & BREAD (missing portions)
-- ============================================================================

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 roti', 100 FROM foods WHERE name = 'Gotukola Roti'
UNION ALL SELECT id, '2 rotis', 200 FROM foods WHERE name = 'Gotukola Roti';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 roti', 100 FROM foods WHERE name = 'Plain Roti'
UNION ALL SELECT id, '2 rotis', 200 FROM foods WHERE name = 'Plain Roti';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 slice', 30 FROM foods WHERE name = 'Brown Bread'
UNION ALL SELECT id, '2 slices', 60 FROM foods WHERE name = 'Brown Bread';

-- ============================================================================
-- PITTU (missing portions)
-- ============================================================================

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 pittu', 100 FROM foods WHERE name = 'Kurakkan Pittu (Finger Millet)'
UNION ALL SELECT id, '2 pittus', 200 FROM foods WHERE name = 'Kurakkan Pittu (Finger Millet)';

-- ============================================================================
-- KIRI BATH (missing portions)
-- ============================================================================

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 piece', 150 FROM foods WHERE name = 'Kiri Bath (Milk Rice)'
UNION ALL SELECT id, '2 pieces', 300 FROM foods WHERE name = 'Kiri Bath (Milk Rice)';

-- ============================================================================
-- SNACKS (missing portions)
-- ============================================================================

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 roll', 80 FROM foods WHERE name = 'Rolls'
UNION ALL SELECT id, '2 rolls', 160 FROM foods WHERE name = 'Rolls';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 piece', 50 FROM foods WHERE name = 'Parippu Wade'
UNION ALL SELECT id, '2 pieces', 100 FROM foods WHERE name = 'Parippu Wade';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 piece', 60 FROM foods WHERE name = 'Isso Wade (Prawn Cutlet)'
UNION ALL SELECT id, '2 pieces', 120 FROM foods WHERE name = 'Isso Wade (Prawn Cutlet)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 piece', 30 FROM foods WHERE name = 'Kokis'
UNION ALL SELECT id, '2 pieces', 60 FROM foods WHERE name = 'Kokis'
UNION ALL SELECT id, '3 pieces', 90 FROM foods WHERE name = 'Kokis';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 piece', 40 FROM foods WHERE name = 'Aluwa (Halva)'
UNION ALL SELECT id, '2 pieces', 80 FROM foods WHERE name = 'Aluwa (Halva)';

-- ============================================================================
-- FRUITS (missing portions)
-- ============================================================================

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 cup', 165 FROM foods WHERE name = 'Pineapple (Annasi)'
UNION ALL SELECT id, '1 slice', 100 FROM foods WHERE name = 'Pineapple (Annasi)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 cup', 200 FROM foods WHERE name = 'Watermelon (Komadu)'
UNION ALL SELECT id, '1 slice', 150 FROM foods WHERE name = 'Watermelon (Komadu)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 medium', 100 FROM foods WHERE name = 'Guava (Pera)'
UNION ALL SELECT id, '1 large', 150 FROM foods WHERE name = 'Guava (Pera)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 fruit', 100 FROM foods WHERE name = 'Wood Apple (Divul)'
UNION ALL SELECT id, '1 fruit', 200 FROM foods WHERE name = 'Wood Apple (Divul)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 glass', 250 FROM foods WHERE name = 'King Coconut (Thambili)'
UNION ALL SELECT id, '1 full coconut', 350 FROM foods WHERE name = 'King Coconut (Thambili)';

-- ============================================================================
-- DESSERTS (missing portions)
-- ============================================================================

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 tablespoon', 30 FROM foods WHERE name = 'Pani Pol (Treacle)'
UNION ALL SELECT id, '2 tablespoons', 60 FROM foods WHERE name = 'Pani Pol (Treacle)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 piece', 40 FROM foods WHERE name = 'Kavum'
UNION ALL SELECT id, '2 pieces', 80 FROM foods WHERE name = 'Kavum';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 piece', 120 FROM foods WHERE name = 'Kiribath with Hakuru'
UNION ALL SELECT id, '2 pieces', 240 FROM foods WHERE name = 'Kiribath with Hakuru';

-- ============================================================================
-- BEVERAGES (missing portions)
-- ============================================================================

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 glass', 250 FROM foods WHERE name = 'Rambutan Juice'
UNION ALL SELECT id, '1 cup', 200 FROM foods WHERE name = 'Rambutan Juice';

-- Verification Query
SELECT 
    'Foods without portions:' as status,
    COUNT(DISTINCT f.id) as count
FROM foods f
LEFT JOIN portions p ON f.id = p.food_id
WHERE p.id IS NULL;

SELECT 
    'Total portions now:' as status,
    COUNT(*) as count
FROM portions;
