# Sri Lankan Food Composition Database Integration Guide

## Overview
This guide explains how to integrate the Sri Lankan Food Composition Database (from [foodcompositiondb.lk](https://www.foodcompositiondb.lk)) into your GlucoDietix application.

The database contains **243 ready-to-eat Sri Lankan food items** with comprehensive nutritional information.

## Database Source
- **Website**: https://www.foodcompositiondb.lk
- **Research**: Published in Journal of Food Composition and Analysis (Elsevier), 2025
- **Coverage**: 243 frequently consumed Sri Lankan foods
- **Language Support**: English, Sinhala (සිංහල), Tamil (தமிழ்)

---

## Quick Start

### Step 1: Update Your Supabase Schema

1. Log in to your Supabase project at https://supabase.com
2. Navigate to **SQL Editor**
3. Run the schema file: `database/schema.sql`
   - This creates the enhanced `foods` table with all nutritional fields
   - Creates the `portions` table
   - Sets up indexes and Row Level Security (RLS)

### Step 2: Import Food Data

1. In the Supabase SQL Editor, run: `database/seed_data.sql`
2. This will populate your database with:
   - **70+ Sri Lankan food items** (expandable to 243)
   - **100+ portion sizes**
   - Complete nutritional information
   - Sinhala and Tamil translations

### Step 3: Verify Import

Run this query in Supabase SQL Editor:
```sql
SELECT 
  'Total Foods' as metric, 
  COUNT(*) as count 
FROM foods
UNION ALL
SELECT 
  'Total Portions' as metric, 
  COUNT(*) as count 
FROM portions;
```

---

## Database Schema

### Foods Table Structure

```sql
CREATE TABLE foods (
  -- Identifiers
  id UUID PRIMARY KEY,
  
  -- Names (Multilingual)
  name TEXT NOT NULL,              -- English name
  name_sinhala TEXT,                -- සිංහල නම
  name_tamil TEXT,                  -- தமிழ் பெயர்
  
  -- Classification
  category TEXT NOT NULL,           -- Staples, Curries, Snacks, etc.
  sub_category TEXT,                -- Rice, Hoppers, Fried, etc.
  
  -- Macronutrients (per 100g)
  carbs_100g NUMERIC NOT NULL,
  protein_100g NUMERIC NOT NULL,
  fat_100g NUMERIC NOT NULL,
  fiber_100g NUMERIC DEFAULT 0,
  energy_kcal NUMERIC NOT NULL,
  sugar_100g NUMERIC,
  
  -- Micronutrients (mg unless specified)
  calcium_mg NUMERIC,
  iron_mg NUMERIC,
  vitamin_a_mcg NUMERIC,           -- in micrograms (μg)
  vitamin_c_mg NUMERIC,
  thiamin_mg NUMERIC,
  riboflavin_mg NUMERIC,
  niacin_mg NUMERIC,
  
  -- Health Markers
  glycemic_index NUMERIC,          -- GI value (0-100)
  glycemic_load NUMERIC,           -- GL value
  cholesterol_mg NUMERIC,
  sodium_mg NUMERIC,
  potassium_mg NUMERIC,
  
  -- Additional Info
  edible_portion_percent NUMERIC DEFAULT 100,
  water_content_percent NUMERIC DEFAULT 0,
  serving_size_g NUMERIC DEFAULT 100,
  is_local BOOLEAN DEFAULT true,
  source TEXT DEFAULT 'foodcompositiondb.lk',
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## Food Categories Available

### 1. Staples & Cereals
- **Rice**: White Rice, Red Rice, Kiri Bath (Milk Rice)
- **Hoppers**: String Hoppers, Plain Hopper, Egg Hopper
- **Roti**: Pol Roti, Gotukola Roti, Plain Roti
- **Pittu**: Plain Pittu, Kurakkan Pittu (Finger Millet)
- **Bread**: White Bread, Brown Bread

### 2. Curries
**Vegetable Curries:**
- Dhal (Parippu), Potato, Pumpkin (Watakka)
- Jackfruit (Polos), Brinjal (Wambatu), Green Beans (Bonchi)
- Cabbage (Gova), Carrot, Beetroot, Leeks

**Meat & Fish Curries:**
- Chicken, Fish (Malu), Egg
- Dried Fish (Karawala), Beef, Pork
- Prawn (Isso), Crab (Kakuluwo)

### 3. Condiments & Sambols
- Pol Sambol (Coconut), Seeni Sambol
- Lunumiris (Chili Paste), Katta Sambol
- Gotukola Sambol

### 4. Mallums (Stir-fried Greens)
- Gotukola, Mukunuwenna, Pol Mallum
- Hathawariya, Kohila

### 5. Snacks & Short Eats
- Wade (Uludu Wade), Samosa, Cutlet
- Rolls, Parippu Wade, Isso Wade
- Kokis, Aluwa (Halva)

### 6. Fruits
- Banana (Ambul), Papaya (Papol), Mango (Amba)
- Pineapple (Annasi), Watermelon (Komadu)
- Guava (Pera), Wood Apple (Divul)
- King Coconut (Thambili)

### 7. Desserts
- Watalappan, Kiri Peni (Curd)
- Pani Pol (Treacle), Kavum
- Kiribath with Hakuru

### 8. Beverages
- Plain Tea, Milk Tea
- Faluda, Rambutan Juice
- King Coconut Water

---

## Using the Database in Your App

### 1. Search Foods
```dart
// Example: Search for foods by name
final response = await supabase
  .from('foods')
  .select()
  .ilike('name', '%rice%')
  .limit(10);
```

### 2. Search in Sinhala or Tamil
```dart
// Search in Sinhala
final response = await supabase
  .from('foods')
  .select()
  .ilike('name_sinhala', '%බත්%')
  .limit(10);

// Search in Tamil
final response = await supabase
  .from('foods')
  .select()
  .ilike('name_tamil', '%சாதம்%')
  .limit(10);
```

### 3. Filter by Category
```dart
final response = await supabase
  .from('foods')
  .select()
  .eq('category', 'Curries')
  .order('name');
```

### 4. Get Foods with Portions
```dart
final response = await supabase
  .from('foods')
  .select('*, portions(*)')
  .eq('name', 'White Rice (Cooked)')
  .single();
```

### 5. Find Low-GI Foods
```dart
final response = await supabase
  .from('foods')
  .select()
  .not('glycemic_index', 'is', null)
  .lte('glycemic_index', 55)  // Low GI
  .order('glycemic_index');
```

---

## Adding More Foods

### Method 1: Direct SQL Insert
Use the provided Python script to generate SQL inserts:

```python
from import_fooddb import ManualFoodEntry

food = ManualFoodEntry.create_food_dict(
    name='Kottu Roti',
    name_sinhala='කොත්තු රොටි',
    name_tamil='கொத்து ரொட்டி',
    category='Main Dishes',
    sub_category='Street Food',
    carbs_100g=22.5,
    protein_100g=8.5,
    fat_100g=12.0,
    fiber_100g=2.5,
    energy_kcal=245,
    is_local=True
)

sql = ManualFoodEntry.generate_sql_insert(food)
print(sql)
```

### Method 2: Through Supabase Dashboard
1. Go to Table Editor → foods
2. Click "Insert row"
3. Fill in the required fields
4. Save

### Method 3: From Your App
```dart
final response = await supabase.from('foods').insert({
  'name': 'New Food',
  'name_sinhala': 'නව ආහාර',
  'name_tamil': 'புதிய உணவு',
  'category': 'Category',
  'carbs_100g': 25.0,
  'protein_100g': 5.0,
  'fat_100g': 3.0,
  'fiber_100g': 2.0,
  'energy_kcal': 150,
});
```

---

## Common Portion Sizes

The database includes common Sri Lankan portion sizes:

- **Rice**: 1 cup (195g), 1/2 cup (97.5g), 1 plate (300g)
- **String Hoppers**: 2 hoppers (70g), 3 hoppers (105g)
- **Plain Hopper**: 1 hopper (60g), 2 hoppers (120g)
- **Pol Roti**: 1 roti (100g), 2 rotis (200g)
- **Curry**: 1/2 cup (120g), 1 cup (240g), 1 ladle (80g)
- **Sambol**: 1 tablespoon (15g), 2 tablespoons (30g)

---

## Nutritional Information Sources

All data is based on:
1. **Primary Source**: foodcompositiondb.lk (243 foods)
2. **Research Paper**: "Development of a country-specific food composition database for Sri Lanka"
   - Published in: Journal of Food Composition and Analysis (2025)
   - By: CoTaSS 3 Project, funded by Medical Research Council UK

---

## Support for Diabetes Management

The database includes key fields for diabetes management:

- **Glycemic Index (GI)**: How quickly food raises blood sugar
  - Low GI: < 55 (Good for diabetes)
  - Medium GI: 56-69
  - High GI: > 70

- **Glycemic Load (GL)**: GI × Carbs / 100
  - Low GL: < 10
  - Medium GL: 11-19
  - High GL: > 20

- **Fiber**: Helps slow sugar absorption
- **Complex Carbs**: Better for blood sugar control

---

## Expanding the Database

To expand to all 243 foods from foodcompositiondb.lk:

1. **Manual Entry**: Use the Python script to create SQL inserts
2. **Web Scraping**: Research paper or website may provide downloadable data
3. **API Access**: Contact the database maintainers for API access
4. **CSV Import**: Create a CSV file and import via Supabase

---

## Tips for Best Results

1. **Always specify portion sizes** for accurate calculations
2. **Use local foods** when possible (is_local = true)
3. **Consider GI values** for diabetes management
4. **Check fiber content** for better blood sugar control
5. **Use Sinhala/Tamil names** for better user experience

---

## Need Help?

- **Website**: https://www.foodcompositiondb.lk
- **Research Paper**: https://www.sciencedirect.com/science/article/pii/S0889157525000444
- **Database Issues**: Check Supabase logs
- **App Issues**: See main README.md

---

## License & Attribution

When using this database, please cite:
- **Source**: Sri Lankan Food Composition Database (foodcompositiondb.lk)
- **Created By**: CoTaSS 3 Project
- **Funded By**: Medical Research Council UK
- **Copyright**: © 2023 IRD. All rights reserved

---

## Next Steps

1. ✅ Run `schema.sql` in Supabase
2. ✅ Run `seed_data.sql` in Supabase
3. ✅ Verify data import
4. ✅ Test search functionality
5. ✅ Start using in your app!

**Happy Coding! 🍛🥗🍚**
