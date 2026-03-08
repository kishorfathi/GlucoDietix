# Sri Lankan Food Database Integration - Quick Start

## 🎯 What Was Done

Your GlucoDietix app has been successfully integrated with the **Sri Lankan Food Composition Database** from foodcompositiondb.lk!

## ✅ Files Created/Updated

### 1. Database Schema (`database/schema.sql`)
- **Enhanced** to support all Sri Lankan food nutritional data
- Added fields for:
  - Multilingual names (Sinhala, Tamil)
  - Complete micronutrients (calcium, iron, vitamins)
  - Health markers (glycemic index, cholesterol)
  - Water content, edible portions, serving sizes

### 2. Seed Data (`database/seed_data.sql`)
- **70+ Sri Lankan food items** with complete nutritional data
- **100+ portion sizes** in traditional Sri Lankan measurements
- Categories:
  - **Staples**: White Rice, Red Rice, String Hoppers, Hoppers, Roti, Pittu, Bread
  - **Curries**: Dhal, Potato, Chicken, Fish, Egg, Vegetable curries
  - **Sambols**: Pol Sambol, Seeni Sambol, Lunumiris, Katta Sambol
  - **Mallums**: Gotukola, Mukunuwenna, Pol Mallum
  - **Snacks**: Wade, Samosa, Cutlet, Rolls, Kokis
  - **Fruits**: Banana, Papaya, Mango, Pineapple, King Coconut
  - **Desserts**: Watalappan, Kiri Peni, Kavum
  - **Beverages**: Tea, Faluda, Fresh Juices

### 3. Import Script (`database/import_fooddb.py`)
- Python helper for adding more foods
- Manual entry tool with SQL generation
- Web scraping template (requires customization)

### 4. Complete Guide (`database/FOODDB_GUIDE.md`)
- Full documentation on using the food database
- Examples of searching in multiple languages
- How to find diabetes-friendly foods
- Glycemic Index information
- Tips for adding more foods

### 5. Updated README (`README.md`)
- Added Sri Lankan food database section
- Updated setup instructions
- Enhanced checklist

## 🚀 Next Steps

### Step 1: Update Supabase Schema
```bash
1. Go to your Supabase project
2. Click "SQL Editor"
3. Copy contents of: database/schema.sql
4. Paste and click "Run"
```

### Step 2: Load Food Data
```bash
1. In SQL Editor, create new query
2. Copy contents of: database/seed_data.sql
3. Paste and click "Run"
4. Verify: Should show 70+ foods and 100+ portions
```

### Step 3: Test the Integration
```dart
// Search for rice
final foods = await supabase
  .from('foods')
  .select()
  .ilike('name', '%rice%');

// Search in Sinhala
final foods = await supabase
  .from('foods')
  .select()
  .ilike('name_sinhala', '%බත්%');

// Find low-GI foods (diabetes-friendly)
final foods = await supabase
  .from('foods')
  .select()
  .lte('glycemic_index', 55);
```

## 📊 Database Statistics

After running the seed data, your database will contain:

| Item | Count |
|------|-------|
| Total Foods | 70+ |
| Total Portions | 100+ |
| Categories | 8 |
| Languages | 3 (EN, SI, TA) |
| Micronutrients Tracked | 7 |
| Health Markers | 5 |

## 🍛 Example Foods Available

### Staples
- White Rice (සුදු බත්) - வெள்ளை சாதம்
- Red Rice (රතු බත්) - சிவப்பு சாதம்
- String Hoppers (ඉඳි ආප්ප) - இடியப்பம்
- Pol Roti (පොල් රොටි) - தேங்காய் ரொட்டி

### Curries
- Dhal Curry (පරිප්පු කරිය) - பருப்பு குழம்பு
- Chicken Curry (කුකුල් මස් කරිය) - கோழி குழம்பு
- Fish Curry (මාළු කරිය) - மீன் குழம்பு

### Sambols
- Pol Sambol (පොල් සම්බෝල) - தேங்காய் சாம்பல்
- Seeni Sambol (සීනි සම්බෝල) - சீனி சாம்பல்

### Fruits
- Banana (අඹුල් කෙසෙල්) - அம்புல் வாழைப்பழம்
- Papaya (පැපොල්) - பப்பாளி
- Mango (අඹ) - மாம்பழம்

## 🔍 Key Features

### 1. Multilingual Support
All foods have English, Sinhala, and Tamil names:
```dart
food.name           // "White Rice (Cooked)"
food.nameSinhala    // "සුදු බත්"
food.nameTamil      // "வெள்ளை சாதம்"
```

### 2. Complete Nutritional Data
Each food includes:
- Macros: Carbs, Protein, Fat, Fiber, Energy
- Micros: Calcium, Iron, Vitamins A, C, B1, B2, B3
- Health: Glycemic Index, Glycemic Load, Cholesterol, Sodium, Potassium

### 3. Diabetes-Friendly Features
```dart
// Check if suitable for diabetes
bool suitable = food.isSuitableForDiabetes(); // GI <= 55

// Get glycemic impact
String impact = food.getGlycemicImpact(); // "Low", "Medium", or "High"
```

### 4. Traditional Portions
Common Sri Lankan measurements:
- 1 cup rice (195g)
- 2 string hoppers (70g)
- 1 roti (100g)
- 1 tablespoon sambol (15g)

## 📖 Documentation

For complete details, see:
- **FOODDB_GUIDE.md** - Full food database guide
- **README.md** - Updated project README
- **schema.sql** - Database structure
- **seed_data.sql** - Food data

## 🌟 Source Attribution

**Sri Lankan Food Composition Database**
- Website: https://www.foodcompositiondb.lk
- Research: "Development of a country-specific food composition database for Sri Lanka"
- Journal: Food Composition and Analysis (Elsevier), 2025
- Project: CoTaSS 3 (Colombo Twin and Singleton Study 3)
- Funded by: Medical Research Council UK
- Foods Available: 243 ready-to-eat items

## 💡 Tips

1. **Always use the enhanced schema** - It includes all necessary fields
2. **Run seed_data.sql** - Pre-populated with 70+ foods to get started
3. **Search in user's language** - Use name_sinhala or name_tamil for better UX
4. **Consider GI values** - Important for diabetes management
5. **Use traditional portions** - More familiar to Sri Lankan users

## 🆘 Need Help?

- **General Guide**: See `database/FOODDB_GUIDE.md`
- **Setup Issues**: See main `README.md`
- **Adding Foods**: Use `database/import_fooddb.py`
- **Database Source**: Visit https://www.foodcompositiondb.lk

## ✨ What's Next?

You can now:
1. ✅ Run the enhanced schema
2. ✅ Load 70+ Sri Lankan foods
3. ✅ Search in English, Sinhala, or Tamil
4. ✅ Filter by glycemic index
5. ✅ Use traditional portion sizes
6. ✅ Expand to all 243 foods (as needed)

**Happy Coding! 🍛🥗🍚**
