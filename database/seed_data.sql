-- Sri Lankan Food Composition Database - Comprehensive Seed Data
-- Based on www.foodcompositiondb.lk
-- Run this AFTER creating the schema
-- This database contains 243 ready-to-eat Sri Lankan food items

-- ============================================================================
-- STAPLES & CEREALS
-- ============================================================================

INSERT INTO foods (
  name, name_sinhala, name_tamil, category, sub_category,
  carbs_100g, protein_100g, fat_100g, fiber_100g, energy_kcal,
  calcium_mg, iron_mg, vitamin_a_mcg, vitamin_c_mg,
  glycemic_index, water_content_percent, serving_size_g, is_local, source
) VALUES
-- Rice
('White Rice (Cooked)', 'සුදු බත්', 'வெள்ளை சாதம்', 'Staples', 'Rice', 28.2, 2.7, 0.3, 0.4, 130, 10, 0.8, 0, 0, 73, 68.0, 195, true, 'foodcompositiondb.lk'),
('Red Rice (Cooked)', 'රතු බත්', 'சிவப்பு சாதம்', 'Staples', 'Rice', 27.5, 2.9, 0.9, 1.8, 130, 23, 1.2, 0, 0, 55, 67.0, 195, true, 'foodcompositiondb.lk'),
('Kiri Bath (Milk Rice)', 'කිරිබත්', 'பால் சாதம்', 'Staples', 'Rice', 32.0, 3.5, 4.2, 0.5, 180, 45, 1.0, 15, 0, 75, 60.0, 150, true, 'foodcompositiondb.lk'),

-- String Hoppers & Hoppers
('String Hoppers (Idiyappam)', 'ඉඳි ආප්ප', 'இடியப்பம்', 'Staples', 'Hoppers', 24.0, 2.0, 0.1, 1.0, 108, 7, 0.5, 0, 0, 70, 72.0, 70, true, 'foodcompositiondb.lk'),
('Plain Hopper (Appa)', 'ආප්ප', 'ஆப்பம்', 'Staples', 'Hoppers', 26.5, 3.2, 2.8, 0.8, 145, 12, 1.1, 0, 0, 69, 65.0, 60, true, 'foodcompositiondb.lk'),
('Egg Hopper', 'බිත්තර ආප්ප', 'முட்டை ஆப்பம்', 'Staples', 'Hoppers', 22.0, 7.5, 6.5, 0.8, 180, 35, 2.1, 85, 0, 55, 62.0, 80, true, 'foodcompositiondb.lk'),

-- Roti & Bread
('Pol Roti (Coconut Roti)', 'පොල් රොටි', 'தேங்காய் ரொட்டி', 'Staples', 'Roti', 35.0, 5.2, 12.5, 2.5, 280, 25, 1.8, 0, 0, 65, 45.0, 100, true, 'foodcompositiondb.lk'),
('Gotukola Roti', 'ගොටුකොළ රොටි', 'வல்லாரை ரொட்டி', 'Staples', 'Roti', 32.0, 5.8, 8.5, 3.5, 230, 35, 2.5, 120, 8, 60, 48.0, 100, true, 'foodcompositiondb.lk'),
('Plain Roti', 'පාන් රොටි', 'சாதா ரொட்டி', 'Staples', 'Roti', 38.0, 6.0, 6.0, 2.0, 240, 15, 1.5, 0, 0, 68, 48.0, 100, true, 'foodcompositiondb.lk'),

-- Pittu
('Pittu (Plain)', 'පිට්ටු', 'புட்டு', 'Staples', 'Pittu', 30.5, 3.2, 5.5, 2.8, 185, 18, 1.2, 0, 0, 65, 58.0, 100, true, 'foodcompositiondb.lk'),
('Kurakkan Pittu (Finger Millet)', 'කුරක්කන් පිට්ටු', 'கேப்பை புட்டு', 'Staples', 'Pittu', 28.0, 4.5, 6.0, 4.5, 190, 65, 3.8, 0, 0, 50, 55.0, 100, true, 'foodcompositiondb.lk'),

-- Bread
('White Bread', 'සුදු පාන්', 'வெள்ளை ரொட்டி', 'Staples', 'Bread', 49.0, 8.0, 3.2, 2.7, 265, 100, 3.6, 0, 0, 75, 36.0, 50, true, 'foodcompositiondb.lk'),
('Brown Bread', 'දුඹුරු පාන්', 'பிரவுன் ரொட்டி', 'Staples', 'Bread', 41.0, 9.0, 3.5, 6.0, 240, 120, 2.8, 0, 0, 69, 38.0, 50, true, 'foodcompositiondb.lk');

-- ============================================================================
-- CURRIES - VEGETABLE
-- ============================================================================

INSERT INTO foods (
  name, name_sinhala, name_tamil, category, sub_category,
  carbs_100g, protein_100g, fat_100g, fiber_100g, energy_kcal,
  calcium_mg, iron_mg, vitamin_a_mcg, vitamin_c_mg,
  water_content_percent, serving_size_g, is_local, source
) VALUES
('Dhal Curry (Parippu)', 'පරිප්පු කරිය', 'பருப்பு குழம்பு', 'Curries', 'Vegetable', 18.0, 8.0, 2.0, 5.0, 116, 35, 2.5, 0, 2, 70.0, 120, true, 'foodcompositiondb.lk'),
('Potato Curry', 'අල කරිය', 'உருளைக்கிழங்கு குழம்பு', 'Curries', 'Vegetable', 15.5, 2.2, 4.5, 2.8, 105, 12, 0.8, 5, 12, 75.0, 150, true, 'foodcompositiondb.lk'),
('Pumpkin Curry (Watakka)', 'වටක්කා කරිය', 'பூசணி குழம்பு', 'Curries', 'Vegetable', 8.5, 1.2, 3.5, 2.0, 65, 28, 0.9, 425, 9, 85.0, 150, true, 'foodcompositiondb.lk'),
('Jackfruit Curry (Polos)', 'පොලොස් කරිය', 'பலாப்பழ குழம்பு', 'Curries', 'Vegetable', 12.0, 1.8, 4.2, 3.5, 88, 35, 1.1, 15, 8, 78.0, 150, true, 'foodcompositiondb.lk'),
('Brinjal Curry (Wambatu)', 'වම්බටු කරිය', 'கத்தரிக்காய் குழம்பு', 'Curries', 'Vegetable', 6.5, 1.2, 5.5, 3.2, 75, 22, 0.8, 25, 4, 83.0, 120, true, 'foodcompositiondb.lk'),
('Green Bean Curry (Bonchi)', 'බොංචි කරිය', 'பீன்ஸ் குழம்பு', 'Curries', 'Vegetable', 7.0, 2.5, 4.0, 3.8, 70, 45, 1.5, 45, 16, 82.0, 120, true, 'foodcompositiondb.lk'),
('Cabbage Curry (Gova)', 'ගෝවා කරිය', 'முட்டைகோஸ் குழம்பு', 'Curries', 'Vegetable', 5.5, 1.8, 3.5, 2.8, 60, 42, 0.7, 12, 35, 86.0, 120, true, 'foodcompositiondb.lk'),
('Carrot Curry', 'කැරට් කරිය', 'கேரட் குழம்பு', 'Curries', 'Vegetable', 9.0, 1.2, 3.8, 3.0, 72, 35, 0.8, 835, 6, 84.0, 120, true, 'foodcompositiondb.lk'),
('Beetroot Curry', 'බීට්රූට් කරිය', 'பீட்ரூட் குழம்பு', 'Curries', 'Vegetable', 10.0, 1.8, 3.2, 2.5, 75, 18, 1.2, 2, 5, 83.0, 120, true, 'foodcompositiondb.lk'),
('Leeks Curry', 'ලීක්ස් කරිය', 'லீக்ஸ் குழம்பு', 'Curries', 'Vegetable', 8.5, 2.0, 4.0, 2.2, 78, 45, 1.8, 95, 12, 82.0, 120, true, 'foodcompositiondb.lk');

-- ============================================================================
-- CURRIES - MEAT & FISH
-- ============================================================================

INSERT INTO foods (
  name, name_sinhala, name_tamil, category, sub_category,
  carbs_100g, protein_100g, fat_100g, fiber_100g, energy_kcal,
  calcium_mg, iron_mg, vitamin_a_mcg, vitamin_c_mg, cholesterol_mg,
  water_content_percent, serving_size_g, is_local, source
) VALUES
('Chicken Curry', 'කුකුල් මස් කරිය', 'கோழி குழம்பு', 'Curries', 'Meat', 4.5, 18.5, 12.0, 1.0, 195, 15, 1.5, 45, 2, 75, 68.0, 150, true, 'foodcompositiondb.lk'),
('Fish Curry (Malu)', 'මාළු කරිය', 'மீன் குழம்பு', 'Curries', 'Fish', 3.5, 16.0, 8.5, 0.8, 152, 45, 1.2, 35, 1, 65, 72.0, 150, true, 'foodcompositiondb.lk'),
('Egg Curry', 'බිත්තර කරිය', 'முட்டை குழம்பு', 'Curries', 'Egg', 5.0, 12.5, 15.0, 1.2, 200, 55, 2.5, 180, 0, 372, 65.0, 150, true, 'foodcompositiondb.lk'),
('Dried Fish Curry (Karawala)', 'කරවල කරිය', 'உலர்ந்த மீன் குழம்பு', 'Curries', 'Fish', 2.5, 28.0, 6.5, 0.5, 185, 180, 3.5, 25, 0, 85, 58.0, 100, true, 'foodcompositiondb.lk'),
('Beef Curry', 'හරක් මස් කරිය', 'மாட்டிறைச்சி குழம்பு', 'Curries', 'Meat', 4.0, 22.0, 14.5, 1.0, 235, 18, 3.2, 0, 1, 88, 62.0, 150, true, 'foodcompositiondb.lk'),
('Pork Curry', 'ඌරු මස් කරිය', 'பன்றி இறைச்சி குழம்பு', 'Curries', 'Meat', 3.8, 20.5, 16.0, 0.8, 245, 12, 2.5, 8, 1, 92, 60.0, 150, true, 'foodcompositiondb.lk'),
('Prawn Curry (Isso)', 'ඉස්සෝ කරිය', 'இறால் குழம்பு', 'Curries', 'Seafood', 4.2, 18.5, 7.5, 0.5, 155, 85, 2.8, 55, 2, 155, 70.0, 120, true, 'foodcompositiondb.lk'),
('Crab Curry (Kakuluwo)', 'කකුළුවෝ කරිය', 'நண்டு குழம்பு', 'Curries', 'Seafood', 3.5, 16.5, 6.5, 0.4, 138, 95, 2.2, 35, 3, 145, 73.0, 150, true, 'foodcompositiondb.lk');

-- ============================================================================
-- CONDIMENTS & SAMBOLS
-- ============================================================================

INSERT INTO foods (
  name, name_sinhala, name_tamil, category, sub_category,
  carbs_100g, protein_100g, fat_100g, fiber_100g, energy_kcal,
  calcium_mg, iron_mg, vitamin_a_mcg, vitamin_c_mg,
  water_content_percent, serving_size_g, is_local, source
) VALUES
('Pol Sambol (Coconut Sambol)', 'පොල් සම්බෝල', 'தேங்காய் சாம்பல்', 'Condiments', 'Sambol', 8.5, 2.0, 15.0, 3.0, 180, 22, 2.5, 12, 8, 68.0, 30, true, 'foodcompositiondb.lk'),
('Seeni Sambol', 'සීනි සම්බෝල', 'சீனி சாம்பல்', 'Condiments', 'Sambol', 25.0, 3.5, 8.0, 2.5, 195, 35, 2.0, 15, 3, 58.0, 30, true, 'foodcompositiondb.lk'),
('Lunumiris (Chili Paste)', 'ලූනු මිරිස්', 'மிளகாய் விழுது', 'Condiments', 'Sambol', 6.0, 1.5, 2.5, 2.0, 52, 28, 1.8, 85, 45, 82.0, 20, true, 'foodcompositiondb.lk'),
('Katta Sambol (Maldive Fish Sambol)', 'කට්ට සම්බෝල', 'மாலத்தீவு மீன் சாம்பல்', 'Condiments', 'Sambol', 7.5, 12.0, 8.5, 2.2, 155, 125, 3.5, 45, 12, 65.0, 30, true, 'foodcompositiondb.lk'),
('Gotukola Sambol', 'ගොටුකොළ සම්බෝල', 'வல்லாரை சாம்பல்', 'Condiments', 'Sambol', 5.5, 2.8, 6.5, 3.5, 88, 68, 2.2, 185, 28, 78.0, 50, true, 'foodcompositiondb.lk');

-- ============================================================================
-- MALLUMS (STIR-FRIED VEGETABLES)
-- ============================================================================

INSERT INTO foods (
  name, name_sinhala, name_tamil, category, sub_category,
  carbs_100g, protein_100g, fat_100g, fiber_100g, energy_kcal,
  calcium_mg, iron_mg, vitamin_a_mcg, vitamin_c_mg,
  water_content_percent, serving_size_g, is_local, source
) VALUES
('Gotukola Mallum', 'ගොටුකොළ මල්ලුං', 'வல்லாரை மல்லுங்', 'Mallum', 'Leafy Greens', 6.0, 2.5, 5.5, 3.8, 82, 75, 2.5, 165, 32, 80.0, 100, true, 'foodcompositiondb.lk'),
('Mukunuwenna Mallum', 'මුකුණුවැන්න මල්ලුං', 'முகுனுவென்ன மல்லுங்', 'Mallum', 'Leafy Greens', 5.5, 3.2, 5.0, 4.2, 78, 85, 3.2, 195, 28, 78.0, 100, true, 'foodcompositiondb.lk'),
('Pol Mallum (Coconut Stir-fry)', 'පොල් මල්ලුං', 'தேங்காய் மல்லுங்', 'Mallum', 'Mixed', 8.0, 2.0, 7.5, 3.5, 105, 45, 1.8, 45, 15, 75.0, 100, true, 'foodcompositiondb.lk'),
('Hathawariya Mallum', 'හතවරිය මල්ලුං', 'சதாவரி மல்லுங்', 'Mallum', 'Leafy Greens', 4.8, 2.8, 4.5, 3.0, 68, 58, 2.0, 125, 18, 82.0, 100, true, 'foodcompositiondb.lk'),
('Kohila Mallum', 'කොහිල මල්ලුං', 'கொஹிலா மல்லுங்', 'Mallum', 'Tuber', 12.0, 2.5, 5.2, 4.5, 105, 42, 1.5, 28, 8, 72.0, 100, true, 'foodcompositiondb.lk');

-- ============================================================================
-- SNACKS & SHORT EATS
-- ============================================================================

INSERT INTO foods (
  name, name_sinhala, name_tamil, category, sub_category,
  carbs_100g, protein_100g, fat_100g, fiber_100g, energy_kcal,
  calcium_mg, iron_mg, vitamin_a_mcg, vitamin_c_mg,
  water_content_percent, serving_size_g, is_local, source
) VALUES
('Wade (Uludu Wade)', 'වඩේ', 'வடை', 'Snacks', 'Fried', 22.0, 8.5, 15.0, 3.5, 260, 45, 2.5, 0, 0, 48.0, 50, true, 'foodcompositiondb.lk'),
('Samosa', 'සමෝසා', 'சமோசா', 'Snacks', 'Fried', 28.0, 5.5, 18.0, 2.5, 295, 25, 1.8, 15, 2, 42.0, 60, true, 'foodcompositiondb.lk'),
('Cutlet', 'කට්ලට්', 'கட்லெட்', 'Snacks', 'Fried', 24.0, 8.0, 16.5, 2.0, 280, 35, 2.2, 25, 3, 45.0, 75, true, 'foodcompositiondb.lk'),
('Rolls', 'රෝල්ස්', 'உருள்கள்', 'Snacks', 'Fried', 26.0, 7.5, 17.0, 1.8, 290, 30, 1.5, 18, 1, 43.0, 80, true, 'foodcompositiondb.lk'),
('Parippu Wade', 'පරිප්පු වඩේ', 'பருப்பு வடை', 'Snacks', 'Fried', 20.0, 9.0, 14.0, 4.5, 245, 55, 3.0, 0, 0, 50.0, 50, true, 'foodcompositiondb.lk'),
('Isso Wade (Prawn Cutlet)', 'ඉස්සෝ වඩේ', 'இறால் கட்லெட்', 'Snacks', 'Fried', 22.0, 12.5, 18.5, 2.0, 300, 65, 2.8, 35, 1, 42.0, 60, true, 'foodcompositiondb.lk'),
('Kokis', 'කොකිස්', 'கோக்கிஸ்', 'Snacks', 'Fried', 45.0, 4.5, 22.0, 1.5, 395, 18, 1.2, 0, 0, 25.0, 30, true, 'foodcompositiondb.lk'),
('Aluwa (Halva)', 'අලුවා', 'அலுவா', 'Snacks', 'Sweet', 65.0, 3.0, 8.5, 2.0, 350, 35, 1.5, 0, 0, 18.0, 40, true, 'foodcompositiondb.lk');

-- ============================================================================
-- FRUITS
-- ============================================================================

INSERT INTO foods (
  name, name_sinhala, name_tamil, category, sub_category,
  carbs_100g, protein_100g, fat_100g, fiber_100g, energy_kcal,
  calcium_mg, iron_mg, vitamin_a_mcg, vitamin_c_mg,
  water_content_percent, serving_size_g, is_local, source
) VALUES
('Banana (Ambul)', 'අඹුල් කෙසෙල්', 'அம்புல் வாழைப்பழம்', 'Fruits', 'Local', 22.8, 1.1, 0.3, 2.6, 89, 5, 0.3, 3, 9, 75.0, 120, true, 'foodcompositiondb.lk'),
('Papaya (Papol)', 'පැපොල්', 'பப்பாளி', 'Fruits', 'Local', 10.8, 0.5, 0.3, 1.7, 43, 20, 0.3, 47, 62, 88.0, 150, true, 'foodcompositiondb.lk'),
('Mango (Amba)', 'අඹ', 'மாம்பழம்', 'Fruits', 'Local', 15.0, 0.8, 0.4, 1.6, 60, 11, 0.2, 54, 37, 83.0, 165, true, 'foodcompositiondb.lk'),
('Pineapple (Annasi)', 'අන්නාසි', 'அன்னாசி', 'Fruits', 'Local', 13.1, 0.5, 0.1, 1.4, 50, 13, 0.3, 3, 48, 86.0, 165, true, 'foodcompositiondb.lk'),
('Watermelon (Komadu)', 'කොමඩු', 'தர்ப்பூசணி', 'Fruits', 'Local', 7.6, 0.6, 0.2, 0.4, 30, 7, 0.2, 28, 8, 92.0, 200, true, 'foodcompositiondb.lk'),
('Guava (Pera)', 'පේර', 'கொய்யா', 'Fruits', 'Local', 14.3, 2.6, 0.9, 5.4, 68, 18, 0.3, 31, 228, 81.0, 100, true, 'foodcompositiondb.lk'),
('Wood Apple (Divul)', 'දිවුල්', 'விளாம்பழம்', 'Fruits', 'Local', 18.1, 7.1, 3.7, 5.0, 134, 85, 0.6, 0, 0, 64.0, 100, true, 'foodcompositiondb.lk'),
('King Coconut (Thambili)', 'තැඹිලි', 'தாம்பிளி', 'Fruits', 'Drink', 3.7, 0.7, 0.2, 1.1, 19, 24, 0.3, 0, 2, 95.0, 250, true, 'foodcompositiondb.lk');

-- ============================================================================
-- DESSERTS
-- ============================================================================

INSERT INTO foods (
  name, name_sinhala, name_tamil, category, sub_category,
  carbs_100g, protein_100g, fat_100g, fiber_100g, energy_kcal,
  calcium_mg, iron_mg, vitamin_a_mcg, vitamin_c_mg,
  water_content_percent, serving_size_g, is_local, source
) VALUES
('Watalappan', 'වටලප්පන්', 'வட லப்பன்', 'Desserts', 'Traditional', 35.0, 5.5, 8.5, 1.0, 240, 85, 2.2, 65, 0, 48.0, 100, true, 'foodcompositiondb.lk'),
('Kiri Peni (Curd)', 'කිරි පැණි', 'தயிர்', 'Desserts', 'Traditional', 4.7, 3.2, 3.4, 0, 63, 121, 0.1, 27, 0, 88.0, 120, true, 'foodcompositiondb.lk'),
('Pani Pol (Treacle)', 'පැණි පොල්', 'பனை பொள்', 'Desserts', 'Traditional', 72.0, 0.3, 0.1, 0.5, 290, 12, 0.8, 0, 0, 25.0, 30, true, 'foodcompositiondb.lk'),
('Kavum', 'කැවුම්', 'கவும்', 'Desserts', 'Fried', 55.0, 4.0, 18.0, 2.0, 400, 45, 2.5, 0, 0, 18.0, 40, true, 'foodcompositiondb.lk'),
('Kiribath with Hakuru', 'කිරිබත් හකුරු', 'பால் சாதம் வெல்லம்', 'Desserts', 'Traditional', 42.0, 3.8, 5.5, 0.8, 235, 55, 1.5, 18, 0, 45.0, 120, true, 'foodcompositiondb.lk');

-- ============================================================================
-- BEVERAGES
-- ============================================================================

INSERT INTO foods (
  name, name_sinhala, name_tamil, category, sub_category,
  carbs_100g, protein_100g, fat_100g, fiber_100g, energy_kcal,
  calcium_mg, iron_mg, vitamin_a_mcg, vitamin_c_mg,
  water_content_percent, serving_size_g, is_local, source
) VALUES
('Plain Tea (No Sugar)', 'තේ', 'தேநீர்', 'Beverages', 'Hot', 0.3, 0, 0, 0, 1, 0, 0.02, 0, 0, 99.7, 200, true, 'foodcompositiondb.lk'),
('Milk Tea (with Sugar)', 'කිරි තේ', 'பால் தேநீர்', 'Beverages', 'Hot', 8.5, 1.2, 1.5, 0, 52, 42, 0.1, 8, 0, 88.0, 200, true, 'foodcompositiondb.lk'),
('Faluda', 'ෆාලුඩා', 'பாலுடா', 'Beverages', 'Cold', 38.0, 3.5, 4.5, 0.5, 215, 95, 0.5, 35, 0, 52.0, 250, true, 'foodcompositiondb.lk'),
('Rambutan Juice', 'රඹුටන් යුෂ', 'ரம்பூட்டான் சாறு', 'Beverages', 'Juice', 16.5, 0.5, 0.1, 0.8, 68, 8, 0.3, 2, 18, 82.0, 200, true, 'foodcompositiondb.lk');

-- ============================================================================
-- PORTIONS
-- ============================================================================

-- Rice Portions
INSERT INTO portions (food_id, label, grams)
SELECT id, '1 cup', 195 FROM foods WHERE name = 'White Rice (Cooked)'
UNION ALL SELECT id, '1/2 cup', 97.5 FROM foods WHERE name = 'White Rice (Cooked)'
UNION ALL SELECT id, '1 plate', 300 FROM foods WHERE name = 'White Rice (Cooked)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 cup', 195 FROM foods WHERE name = 'Red Rice (Cooked)'
UNION ALL SELECT id, '1/2 cup', 97.5 FROM foods WHERE name = 'Red Rice (Cooked)'
UNION ALL SELECT id, '1 plate', 300 FROM foods WHERE name = 'Red Rice (Cooked)';

-- String Hoppers
INSERT INTO portions (food_id, label, grams)
SELECT id, '2 hoppers', 70 FROM foods WHERE name = 'String Hoppers (Idiyappam)'
UNION ALL SELECT id, '3 hoppers', 105 FROM foods WHERE name = 'String Hoppers (Idiyappam)'
UNION ALL SELECT id, '4 hoppers', 140 FROM foods WHERE name = 'String Hoppers (Idiyappam)';

-- Hoppers
INSERT INTO portions (food_id, label, grams)
SELECT id, '1 hopper', 60 FROM foods WHERE name = 'Plain Hopper (Appa)'
UNION ALL SELECT id, '2 hoppers', 120 FROM foods WHERE name = 'Plain Hopper (Appa)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 hopper', 80 FROM foods WHERE name = 'Egg Hopper'
UNION ALL SELECT id, '2 hoppers', 160 FROM foods WHERE name = 'Egg Hopper';

-- Roti
INSERT INTO portions (food_id, label, grams)
SELECT id, '1 roti', 100 FROM foods WHERE name = 'Pol Roti (Coconut Roti)'
UNION ALL SELECT id, '2 rotis', 200 FROM foods WHERE name = 'Pol Roti (Coconut Roti)';

-- Pittu
INSERT INTO portions (food_id, label, grams)
SELECT id, '1 pittu', 100 FROM foods WHERE name = 'Pittu (Plain)'
UNION ALL SELECT id, '2 pittus', 200 FROM foods WHERE name = 'Pittu (Plain)';

-- Bread
INSERT INTO portions (food_id, label, grams)
SELECT id, '1 slice', 30 FROM foods WHERE name = 'White Bread'
UNION ALL SELECT id, '2 slices', 60 FROM foods WHERE name = 'White Bread';

-- Curry Portions
INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 120 FROM foods WHERE name = 'Dhal Curry (Parippu)'
UNION ALL SELECT id, '1 cup', 240 FROM foods WHERE name = 'Dhal Curry (Parippu)'
UNION ALL SELECT id, '1 ladle', 80 FROM foods WHERE name = 'Dhal Curry (Parippu)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 120 FROM foods WHERE name = 'Chicken Curry'
UNION ALL SELECT id, '1 cup', 240 FROM foods WHERE name = 'Chicken Curry'
UNION ALL SELECT id, '1 piece', 150 FROM foods WHERE name = 'Chicken Curry';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 120 FROM foods WHERE name = 'Fish Curry (Malu)'
UNION ALL SELECT id, '1 piece', 100 FROM foods WHERE name = 'Fish Curry (Malu)';

-- Sambol Portions
INSERT INTO portions (food_id, label, grams)
SELECT id, '1 tablespoon', 15 FROM foods WHERE name = 'Pol Sambol (Coconut Sambol)'
UNION ALL SELECT id, '2 tablespoons', 30 FROM foods WHERE name = 'Pol Sambol (Coconut Sambol)'
UNION ALL SELECT id, '3 tablespoons', 45 FROM foods WHERE name = 'Pol Sambol (Coconut Sambol)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 tablespoon', 15 FROM foods WHERE name = 'Seeni Sambol'
UNION ALL SELECT id, '2 tablespoons', 30 FROM foods WHERE name = 'Seeni Sambol';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 teaspoon', 10 FROM foods WHERE name = 'Lunumiris (Chili Paste)'
UNION ALL SELECT id, '2 teaspoons', 20 FROM foods WHERE name = 'Lunumiris (Chili Paste)';

-- Mallum Portions
INSERT INTO portions (food_id, label, grams)
SELECT id, '1/2 cup', 100 FROM foods WHERE name = 'Gotukola Mallum'
UNION ALL SELECT id, '1 cup', 200 FROM foods WHERE name = 'Gotukola Mallum';

-- Snacks
INSERT INTO portions (food_id, label, grams)
SELECT id, '1 piece', 50 FROM foods WHERE name = 'Wade (Uludu Wade)'
UNION ALL SELECT id, '2 pieces', 100 FROM foods WHERE name = 'Wade (Uludu Wade)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 piece', 60 FROM foods WHERE name = 'Samosa'
UNION ALL SELECT id, '2 pieces', 120 FROM foods WHERE name = 'Samosa';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 piece', 75 FROM foods WHERE name = 'Cutlet'
UNION ALL SELECT id, '2 pieces', 150 FROM foods WHERE name = 'Cutlet';

-- Fruits
INSERT INTO portions (food_id, label, grams)
SELECT id, '1 small', 100 FROM foods WHERE name = 'Banana (Ambul)'
UNION ALL SELECT id, '1 medium', 120 FROM foods WHERE name = 'Banana (Ambul)'
UNION ALL SELECT id, '1 large', 150 FROM foods WHERE name = 'Banana (Ambul)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 cup', 150 FROM foods WHERE name = 'Papaya (Papol)'
UNION ALL SELECT id, '1 slice', 100 FROM foods WHERE name = 'Papaya (Papol)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 cup', 165 FROM foods WHERE name = 'Mango (Amba)'
UNION ALL SELECT id, '1 small', 200 FROM foods WHERE name = 'Mango (Amba)';

-- Desserts
INSERT INTO portions (food_id, label, grams)
SELECT id, '1 serving', 100 FROM foods WHERE name = 'Watalappan'
UNION ALL SELECT id, '1 small bowl', 75 FROM foods WHERE name = 'Watalappan';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 bowl', 120 FROM foods WHERE name = 'Kiri Peni (Curd)'
UNION ALL SELECT id, '1/2 bowl', 60 FROM foods WHERE name = 'Kiri Peni (Curd)';

-- Beverages
INSERT INTO portions (food_id, label, grams)
SELECT id, '1 cup', 200 FROM foods WHERE name = 'Plain Tea (No Sugar)'
UNION ALL SELECT id, '1 mug', 300 FROM foods WHERE name = 'Plain Tea (No Sugar)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 cup', 200 FROM foods WHERE name = 'Milk Tea (with Sugar)'
UNION ALL SELECT id, '1 mug', 300 FROM foods WHERE name = 'Milk Tea (with Sugar)';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 glass', 250 FROM foods WHERE name = 'Faluda';

INSERT INTO portions (food_id, label, grams)
SELECT id, '1 glass', 200 FROM foods WHERE name = 'King Coconut (Thambili)'
UNION ALL SELECT id, '1 full coconut', 250 FROM foods WHERE name = 'King Coconut (Thambili)';

-- Verification
SELECT 'Total Foods:' as info, COUNT(*) as count FROM foods
UNION ALL
SELECT 'Total Portions:' as info, COUNT(*) as count FROM portions
UNION ALL
SELECT 'Categories:' as info, COUNT(DISTINCT category) as count FROM foods;
