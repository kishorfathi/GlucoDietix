# GlucoDietix - Complete Guide

A Flutter app for managing diet with glucose and cholesterol tracking using Supabase.

---

## 📋 CHECKLIST - FOLLOW THESE STEPS

- [ ] Step 1: Install Flutter SDK (if not already installed)
- [ ] Step 2: Create Supabase account and project
- [ ] Step 3: Run SQL schema in Supabase (Enhanced for Sri Lankan foods)
- [ ] Step 4: Run SQL seed data in Supabase (70+ Sri Lankan foods loaded)
- [ ] Step 5: Get Supabase URL and anon key
- [ ] Step 6: Navigate to project directory
- [ ] Step 7: Run `flutter pub get`
- [ ] Step 8: Update Supabase credentials in config file
- [ ] Step 9: Connect Android device or start emulator
- [ ] Step 10: Run `flutter run`

---

## Web Real ML Setup

For real ML food detection on Chrome/web, configure Google Vision API and run with `--dart-define`.

See: [GOOGLE_VISION_SETUP.md](GOOGLE_VISION_SETUP.md)

---

## 📂 FOLDER STRUCTURE

```
glucodietix/
├── android/
│   └── app/
│       └── src/
│           └── main/
│               └── AndroidManifest.xml (camera permissions)
├── database/
│   ├── schema.sql (Enhanced database schema for Sri Lankan foods)
│   ├── seed_data.sql (70+ Sri Lankan foods with nutritional data)
│   ├── FOODDB_GUIDE.md (Complete food database guide)
│   └── import_fooddb.py (Python script for importing more foods)
├── lib/
│   ├── main.dart (app entry point)
│   ├── config/
│   │   └── supabase_config.dart (PASTE YOUR CREDENTIALS HERE)
│   ├── models/
│   │   ├── food.dart
│   │   ├── portion.dart
│   │   ├── user_profile.dart
│   │   └── meal_item.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── meal_provider.dart
│   │   └── user_profile_provider.dart
│   ├── services/
│   │   └── supabase_service.dart
│   ├── widgets/
│   │   ├── auth_gate.dart
│   │   └── loading_indicator.dart
│   └── screens/
│       ├── auth/
│       │   ├── login_screen.dart
│       │   └── register_screen.dart
│       ├── profile/
│       │   └── profile_screen.dart
│       ├── foods/
│       │   ├── food_search_screen.dart
│       │   └── portion_selection_screen.dart
│       ├── meal/
│       │   ├── meal_builder_screen.dart
│       │   └── results_screen.dart
│       └── scan/
│           └── scan_plate_screen.dart
└── pubspec.yaml
```

---

## 🚀 STEP-BY-STEP SETUP INSTRUCTIONS

### Step 1: Prerequisites

Ensure Flutter is installed:
```bash
flutter --version
```

If not installed, visit: https://docs.flutter.dev/get-started/install

### Step 2: Create Supabase Project

1. Go to https://supabase.com
2. Sign up or log in
3. Click "New Project"
4. Fill in:
   - Project name: glucodietix
   - Database password: (choose a strong password)
   - Region: (choose closest to you)
5. Wait for project to be created (2-3 minutes)

### Step 3: Run SQL Schema

1. In Supabase dashboard, click "SQL Editor" in left sidebar
2. Click "New Query"
3. Copy entire contents of `database/schema.sql`
4. Paste into SQL editor
5. Click "Run" button
6. Verify: You should see "Success. No rows returned"

### Step 4: Run SQL Seed Data

1. In Supabase SQL Editor, click "New Query"
2. Copy entire contents of `database/seed_data.sql`
3. Paste into SQL editor
4. Click "Run" button
5. Verify: You should see results showing **70+ Sri Lankan foods** and **100+ portions**

**What's Loaded:**
- Rice, hoppers, roti, pittu, bread
- Vegetable, meat, and fish curries
- Sambols, mallums, and condiments
- Snacks, fruits, desserts, beverages
- Complete nutritional data including GI values
- Sinhala and Tamil translations

### Step 5: Get Supabase Credentials

1. In Supabase dashboard, click "Settings" (gear icon) in left sidebar
2. Click "API" under Project Settings
3. Copy:
   - **Project URL** (looks like: https://xxxxx.supabase.co)
   - **anon public** key (long string starting with eyJ...)
4. Keep these ready for next step

### Step 6: Configure Your App

1. Open the project in VS Code or your editor
2. Navigate to: `lib/config/supabase_config.dart`
3. Replace the placeholders:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
   ```
   
   With your actual values:
   ```dart
   static const String supabaseUrl = 'https://xxxxx.supabase.co';
   static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
   ```

4. Save the file

### Step 7: Install Dependencies

Open terminal in the project directory and run:
```bash
flutter pub get
```

Wait for all packages to download.

### Step 8: Connect Device or Emulator

**Option A: Physical Device (Recommended)**
1. Enable Developer Options on your Android phone
2. Enable USB Debugging
3. Connect phone to computer via USB
4. Verify connection:
   ```bash
   flutter devices
   ```

**Option B: Android Emulator**
1. Open Android Studio
2. Go to Tools > Device Manager
3. Create or start an emulator
4. Verify:
   ```bash
   flutter devices
   ```

### Step 9: Run the App

```bash
flutter run
```

First run will take 2-5 minutes to build. Subsequent runs are faster.

---

## 🎯 HOW TO USE THE APP

### 1. Register an Account
- Launch app → "Don't have an account? Register"
- Enter email and password (min 6 characters)
- Click "Register"
- Go back to login screen

### 2. Login
- Enter your email and password
- Click "Login"

### 3. Set Up Profile
- Click profile icon (top right)
- Set your health information:
  - Diabetes status
  - Glucose range (low/normal/high)
  - Cholesterol concern
- Click "Save Profile"

### 4. Build a Meal

**Option A: Manual Food Search**
- Click "Add Food"
- Search for foods (e.g., "rice")
- Optionally filter by category
- Click + icon next to food
- Select portion size
- Click "Add to Meal"

**Option B: Scan Plate**
- Click "Scan Plate"
- Take a photo or pick from gallery
- Click "Select Foods Seen in Photo"
- Manually select the foods you see
- Choose portions as in Option A

### 5. View Results
- After adding foods, click "Calculate Nutrients"
- View:
  - OK/Not OK status (based on carbs)
  - Total nutrients
  - Recommendations (if over carb limit)
- Click "View in AR" to see recommended portion (opens browser)

### 6. Logout
- Click logout icon (top right)
- Confirm logout

---

## 🗄️ DATABASE TABLES

### foods
- **Enhanced for Sri Lankan Food Composition Database**
- Contains 70+ ready-to-eat Sri Lankan food items
- Columns include:
  - Basic: id, name, name_sinhala, name_tamil, category, sub_category
  - Macronutrients: carbs_100g, protein_100g, fat_100g, fiber_100g, energy_kcal
  - Micronutrients: calcium_mg, iron_mg, vitamin_a_mcg, vitamin_c_mg, etc.
  - Health markers: glycemic_index, glycemic_load, cholesterol_mg
  - Additional: edible_portion_percent, water_content_percent, is_local, source
- All users can read
- **Source**: [foodcompositiondb.lk](https://www.foodcompositiondb.lk) - 243 foods available

### portions
- Stores standard Sri Lankan serving sizes for each food
- Columns: id, food_id, label, grams
- Links to foods table
- Examples: "1 cup", "2 hoppers", "1 tablespoon"
- All users can read

### user_profiles
- Stores user health information
- Columns: id, diabetes, glucose_range, cholesterol_concern
- Each user can only see/edit their own profile

---

## 🍛 SRI LANKAN FOOD DATABASE INTEGRATION

This app uses the **Sri Lankan Food Composition Database** from [foodcompositiondb.lk](https://www.foodcompositiondb.lk).

### What's Included:
- **70+ Sri Lankan foods** with complete nutritional data
- **Multilingual support**: English, Sinhala (සිංහල), Tamil (தமிழ்)
- **Categories**: Staples, Curries, Sambols, Mallums, Snacks, Fruits, Desserts, Beverages
- **100+ portion sizes**: Traditional Sri Lankan measurements

### Food Categories:
1. **Staples**: Rice, Hoppers, Roti, Pittu, Bread
2. **Curries**: Vegetable, Meat, Fish, Seafood
3. **Sambols**: Pol Sambol, Seeni Sambol, Lunumiris, Katta Sambol
4. **Mallums**: Gotukola, Mukunuwenna, Pol Mallum
5. **Snacks**: Wade, Samosa, Cutlet, Rolls, Kokis
6. **Fruits**: Banana, Papaya, Mango, King Coconut
7. **Desserts**: Watalappan, Kiri Peni, Kavum
8. **Beverages**: Tea, Faluda, Fresh Juices

### Complete Guide:
📖 See `database/FOODDB_GUIDE.md` for:
- Complete food list
- How to add more foods
- Searching in Sinhala/Tamil
- Diabetes-friendly food selection
- Glycemic Index information

### Example Foods:
- **White Rice (Cooked)** - සුදු බත් - வெள்ளை சாதம்
- **String Hoppers** - ඉඳි ආප්ප - இடியப்பம்
- **Pol Sambol** - පොල් සම්බෝල - தேங்காய் சாம்பல்
- **Dhal Curry** - පරිප්පු කරිය - பருப்பு குழம்பு

### Research Citation:
**Published Study**: "Development of a country-specific food composition database for Sri Lanka"
- Journal: Food Composition and Analysis (Elsevier), 2025
- Project: CoTaSS 3, funded by Medical Research Council UK
- Foods: 243 ready-to-eat items commonly consumed in Sri Lanka

---

## ⚙️ NUTRIENT CALCULATION LOGIC

1. **Per Item Calculation:**
   ```
   nutrient = nutrient_100g × grams ÷ 100
   ```

2. **Target Carbs:**
   - If glucose_range == "high": target = 45g
   - Otherwise: target = 60g

3. **Feedback:**
   - totalCarbs > target → "Not OK"
   - totalCarbs ≤ target → "OK"

4. **Recommendation (if Not OK):**
   - Find item with highest carbs
   - Calculate grams to reduce:
     ```
     excessCarbs = totalCarbs - targetCarbs
     gramsToReduce = (excessCarbs ÷ carbsPer100g) × 100
     recommendedGrams = currentGrams - gramsToReduce
     ```
   - Clamp to minimum of 0

---

## 🔧 TROUBLESHOOTING

### Problem: "Invalid API key" or "Invalid JWT"

**Solution:**
1. Go to Supabase dashboard → Settings → API
2. Copy the **anon public** key (not service_role key)
3. Paste in `lib/config/supabase_config.dart`
4. Restart app (hot reload won't work for config changes)

### Problem: "null user" or Authentication not working

**Solution:**
1. Check email confirmation:
   - In Supabase: Authentication → Settings
   - Disable "Enable email confirmations" for testing
2. Verify schema:
   - Run schema.sql again in SQL Editor
3. Check RLS policies:
   - In Supabase: Authentication → Policies
   - Ensure policies are created correctly

### Problem: Camera permission denied

**Solution:**
1. Check `android/app/src/main/AndroidManifest.xml` has camera permissions
2. On device: Settings → Apps → GlucoDietix → Permissions → Enable Camera
3. Reinstall app:
   ```bash
   flutter clean
   flutter run
   ```

### Problem: url_launcher not working

**Solution:**
1. Verify URL format: `https://YOUR_HOST/ar.html?food=rice&grams=100`
2. Replace YOUR_HOST with your actual AR hosting domain
3. For testing, use a public URL or localhost with ngrok

### Problem: "No foods found" in search

**Solution:**
1. Check Supabase:
   - Dashboard → Table Editor → foods
   - Verify data exists
2. Re-run seed data:
   - SQL Editor → paste `database/seed_data.sql` → Run
3. Check RLS policies:
   - Foods table should have SELECT policy for public

### Problem: Build errors

**Solution:**
1. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. Check Flutter version:
   ```bash
   flutter --version
   flutter upgrade
   ```

3. Check for package conflicts:
   - Ensure `pubspec.yaml` matches exactly as provided

### Problem: App crashes on startup

**Solution:**
1. Check logs:
   ```bash
   flutter run --verbose
   ```

2. Common issues:
   - Supabase credentials not configured
   - Internet connection required
   - Android SDK issues

3. Reset:
   ```bash
   flutter clean
   cd android
   gradlew clean
   cd ..
   flutter run
   ```

---

## 📱 ANDROID PERMISSIONS

The following permissions are required (already configured in AndroidManifest.xml):

- **CAMERA**: Take photos of meals
- **INTERNET**: Connect to Supabase
- **READ_EXTERNAL_STORAGE**: Pick images from gallery
- **WRITE_EXTERNAL_STORAGE**: Save captured images

---

## 🔐 SECURITY NOTES

1. **Supabase Keys:**
   - The anon key is safe to expose in client apps
   - Never commit the service_role key
   - Use RLS policies to secure data

2. **User Data:**
   - User profiles are automatically secured by RLS
   - Users can only see/edit their own profile
   - Food data is public (read-only)

3. **Authentication:**
   - Passwords are hashed by Supabase
   - Sessions are managed automatically
   - Tokens are stored securely by supabase_flutter

---

## 🌐 WEBVR PORTION VIEW SETUP (OPTIONAL)

To set up the AR portion view:

1. Create an `ar.html` file with A-Frame or model-viewer
2. Host it on:
   - Vercel
   - Netlify
   - GitHub Pages
   - Or any static hosting
3. Update URL in `lib/screens/meal/results_screen.dart`:
   ```dart
   final url = 'https://YOUR_ACTUAL_DOMAIN/ar.html?food=$slug&grams=${grams.toStringAsFixed(0)}';
   ```

Example ar.html structure:
```html
<!DOCTYPE html>
<html>
<head>
  <script src="https://aframe.io/releases/1.4.0/aframe.min.js"></script>
</head>
<body>
  <a-scene>
    <a-box position="0 1 -3" rotation="0 45 0" color="#4CC3D9"></a-box>
    <a-sky color="#ECECEC"></a-sky>
  </a-scene>
</body>
</html>
```

---

## 🎨 CUSTOMIZATION

### Adding More Foods

1. Go to Supabase → Table Editor → foods
2. Click "Insert row"
3. Fill in:
   - name: Food name
   - category: Category
   - kcal_100g, carbs_100g, protein_100g, fat_100g: Per 100g values
4. Click "Save"

### Adding Portions

1. Go to Supabase → Table Editor → portions
2. Click "Insert row"
3. Fill in:
   - food_id: UUID of the food (from foods table)
   - label: e.g., "1 cup", "1 tablespoon"
   - grams: Weight in grams
4. Click "Save"

### Changing Target Carbs

Edit `lib/screens/meal/results_screen.dart`:
```dart
// Current logic:
double targetCarbs = 60;
if (profileProvider.userProfile!.glucoseRange == 'high') {
  targetCarbs = 45;
}

// Change to your values:
double targetCarbs = 70; // Your new default
if (profileProvider.userProfile!.glucoseRange == 'high') {
  targetCarbs = 50; // Your new high glucose target
}
```

---

## 📚 PACKAGES USED

- **supabase_flutter** (^2.5.0): Supabase client for authentication and database
- **provider** (^6.1.2): State management
- **image_picker** (^1.0.7): Camera and gallery access
- **url_launcher** (^6.2.5): Open AR view in browser

---

## 🐛 KNOWN LIMITATIONS

1. **AR View**: Requires external hosting for ar.html
2. **Food Detection**: Level 1 scan requires manual food selection
3. **Offline Mode**: Requires internet connection for all features
4. **Image Storage**: Scanned images not saved to database

---

## 🔄 NEXT STEPS (BEYOND MVP)

1. Add food images
2. Implement ML food detection for scanned plates
3. Add meal history and tracking
4. Add charts and analytics
5. Add meal recommendations
6. Implement offline mode with local database
7. Add barcode scanning
8. Add social features (share meals)

---

## 📞 SUPPORT

If you encounter issues:

1. Check this troubleshooting guide
2. Verify Supabase credentials
3. Check Flutter doctor: `flutter doctor`
4. Review error logs: `flutter run --verbose`

Common error patterns:
- "Invalid JWT" → Wrong anon key
- "null user" → Not logged in or session expired
- "RLS policy violation" → Check user_profiles policies
- Camera errors → Check permissions

---

## ✅ TESTING CHECKLIST

After setup, test these features:

- [ ] Register new account
- [ ] Login with credentials
- [ ] Logout and login again
- [ ] Update user profile
- [ ] Search foods by name
- [ ] Filter foods by category
- [ ] Add food with portion selection
- [ ] Remove food from meal
- [ ] View results with OK status
- [ ] View results with Not OK status (add high-carb foods)
- [ ] See recommendation for high carb item
- [ ] Take photo with camera
- [ ] Pick image from gallery
- [ ] Navigate from scan to food search

---

## 📄 LICENSE

This is a learning project. Feel free to modify and use as needed.

---

**Built with Flutter 💙 & Supabase 🚀**
