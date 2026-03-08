# 🚀 COMPLETE SETUP GUIDE - GlucoDietix with Sri Lankan Food Database

**Follow these steps exactly to get your app running with the Sri Lankan Food Database!**

---

## ✅ PREREQUISITES CHECKLIST

Before starting, make sure you have:

- [ ] Flutter SDK installed (`flutter --version` to check)
- [ ] A Supabase account (free - sign up at https://supabase.com)
- [ ] Android device/emulator OR iOS device/simulator
- [ ] Internet connection
- [ ] 15-20 minutes of time

---

## 📋 PART 1: SUPABASE SETUP (10 minutes)

### Step 1: Create Your Supabase Project

1. **Go to** https://supabase.com
2. **Click** "Sign in" (or "Sign up" if you don't have an account)
3. **Click** "New Project" button (green button)
4. **Fill in the details:**
   ```
   Name: glucodietix
   Database Password: [Create a strong password - SAVE THIS!]
   Region: [Choose closest to Sri Lanka - Singapore/India]
   Pricing Plan: Free
   ```
5. **Click** "Create new project"
6. **Wait** 2-3 minutes while Supabase creates your database

---

### Step 2: Load the Database Schema

1. **In Supabase Dashboard**, look at the left sidebar
2. **Click** on **"SQL Editor"** icon (looks like </> )
3. **Click** "New Query" button (top right)
4. **Open this file in VS Code:**
   ```
   database/schema.sql
   ```
5. **Select ALL** the content (Ctrl+A)
6. **Copy** it (Ctrl+C)
7. **Go back to Supabase** SQL Editor
8. **Paste** the content (Ctrl+V)
9. **Click** "Run" button (bottom right)
10. **Wait** for success message: ✓ "Success. No rows returned"

**✅ You now have the database structure ready!**

---

### Step 3: Load the Sri Lankan Food Data

1. **Still in Supabase SQL Editor**, click "New Query" again
2. **Open this file in VS Code:**
   ```
   database/seed_data.sql
   ```
3. **Select ALL** the content (Ctrl+A)
4. **Copy** it (Ctrl+C)
5. **Go back to Supabase** SQL Editor
6. **Paste** the content (Ctrl+V)
7. **Click** "Run" button
8. **Wait** ~30 seconds (it's a big file)
9. **Look for the verification results** at the bottom showing:
   ```
   Total Foods: 70+
   Total Portions: 100+
   Categories: 8
   ```

**✅ You now have 70+ Sri Lankan foods loaded!**

---

### Step 4: Verify the Data (Optional but Recommended)

1. **Click "New Query"** in SQL Editor
2. **Run this simple check:**
   ```sql
   SELECT COUNT(*) as total_foods FROM foods;
   ```
3. **You should see:** total_foods = 70 or more

4. **Check a sample food:**
   ```sql
   SELECT name, name_sinhala, name_tamil, category, energy_kcal, glycemic_index
   FROM foods 
   WHERE name = 'White Rice (Cooked)';
   ```
5. **You should see:** Full details of white rice in all 3 languages

**✅ Database is working perfectly!**

---

### Step 5: Get Your Supabase Credentials

**IMPORTANT: You'll need these to connect your app!**

1. **In Supabase Dashboard**, click **"Settings"** (gear icon, bottom left)
2. **Click** "API" in the left menu
3. **You'll see two important things:**

   **A) Project URL**
   ```
   Example: https://abcdefghijk.supabase.co
   
   👉 COPY THIS - You'll need it!
   ```

   **B) Project API keys**
   ```
   anon public key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.ey...
   
   👉 COPY THE "anon public" KEY (the long one) - You'll need it!
   ```

   **⚠️ IMPORTANT:** Copy the **anon public** key, NOT the service_role key!

4. **Save these somewhere safe** - Notepad, text file, etc.

**✅ You have your credentials!**

---

## 📱 PART 2: FLUTTER APP SETUP (5 minutes)

### Step 6: Navigate to Your Project

1. **Open Terminal/PowerShell** in VS Code
2. **Navigate to the GlucoDietix folder:**
   ```powershell
   cd C:\Users\kishor\Desktop\FinalResearchGlucoDietix\GlucoDietix
   ```
3. **Verify you're in the right place:**
   ```powershell
   Test-Path pubspec.yaml
   ```
   👉 Should return: **True**

---

### Step 7: Install Dependencies

**In the terminal**, run:
```powershell
flutter pub get
```

**Wait** for it to download all packages. You should see:
```
Running "flutter pub get" in GlucoDietix...
Got dependencies!
```

**✅ All Flutter packages installed!**

---

### Step 8: Configure Supabase Credentials

**CRITICAL STEP - Don't skip this!**

1. **Open this file in VS Code:**
   ```
   lib/config/supabase_config.dart
   ```

2. **Find these lines** (around line 5-6):
   ```dart
   const supabaseUrl = 'YOUR_SUPABASE_URL';
   const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

3. **Replace with YOUR credentials** from Step 5:
   ```dart
   const supabaseUrl = 'https://abcdefghijk.supabase.co';  // YOUR URL
   const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.ey...';  // YOUR KEY
   ```

4. **Save the file** (Ctrl+S)

**✅ App is now connected to your database!**

---

### Step 9: Connect Your Device

**Choose ONE option:**

**Option A: Android Device (Physical Phone)**
1. Enable USB Debugging on your phone:
   - Settings → About Phone → Tap "Build Number" 7 times
   - Settings → Developer Options → Enable "USB Debugging"
2. Connect phone to computer via USB
3. Accept any prompts on your phone
4. Run: `flutter devices` to verify

**Option B: Android Emulator**
1. Open Android Studio
2. Click "Device Manager" (phone icon)
3. Create/Start an emulator
4. Wait for it to boot up
5. Run: `flutter devices` to verify

**Option C: Windows Desktop**
```powershell
flutter config --enable-windows-desktop
```

**Verify device:**
```powershell
flutter devices
```
You should see at least one device listed.

**✅ Device ready!**

---

### Step 10: Run the App! 🎉

**In the terminal**, run:
```powershell
flutter run
```

**What happens:**
1. App compiles (1-3 minutes first time)
2. App installs on device
3. App launches automatically

**You should see:**
- Login/Register screen
- Beautiful Sri Lankan food app interface!

**✅ APP IS RUNNING!**

---

## 🎮 PART 3: TESTING THE APP (5 minutes)

### Test 1: Create Account

1. **Click** "Register" button
2. **Enter:**
   ```
   Email: test@example.com
   Password: test1234
   ```
3. **Click** "Sign Up"
4. **You should be** logged in!

---

### Test 2: Set Up Profile

1. **You'll see** the Profile screen
2. **Select your health info:**
   ```
   Diabetes: Yes/No
   Glucose Range: Normal/High/Low
   Cholesterol Concern: Yes/No
   ```
3. **Click** "Save Profile"

---

### Test 3: Search Sri Lankan Foods

1. **Click** "Build Meal" or "Search Foods"
2. **Try searching:**
   ```
   - "rice" → See White Rice, Red Rice, Kiri Bath
   - "hopper" → See String Hoppers, Plain Hopper, Egg Hopper
   - "කරිය" → See curries in Sinhala!
   - "சாதம்" → See rice items in Tamil!
   ```
3. **You should see** foods with:
   - ✅ English, Sinhala, Tamil names
   - ✅ Nutritional info
   - ✅ Glycemic Index values

---

### Test 4: Build a Meal

1. **Search** for "rice"
2. **Select** "White Rice (Cooked)"
3. **Choose portion:** "1 cup" (195g)
4. **Add to meal**
5. **Repeat** with:
   - "Dhal Curry" → "1/2 cup"
   - "Pol Sambol" → "1 tablespoon"
6. **Click** "Calculate Results"
7. **You should see:**
   - ✅ Total carbs, protein, fat
   - ✅ Total calories
   - ✅ Diabetes feedback (OK/Not OK)
   - ✅ Recommendations if needed

**✅ App is fully working!**

---

## 🔧 TROUBLESHOOTING

### Problem: "Invalid API credentials"

**Solution:**
1. Go to `lib/config/supabase_config.dart`
2. Check you copied the **anon public** key (not service_role)
3. Check for any extra spaces or quotes
4. Make sure URL starts with `https://`

---

### Problem: "No foods found" when searching

**Solution:**
1. Go back to Supabase SQL Editor
2. Run: `SELECT COUNT(*) FROM foods;`
3. If result is 0, re-run `database/seed_data.sql`

---

### Problem: App won't compile

**Solution:**
```powershell
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

---

### Problem: "Could not find device"

**Solution:**
```powershell
# Check devices
flutter devices

# If none found:
# - For Android: Check USB debugging is on
# - For Emulator: Make sure it's running
# - For Windows: Run flutter config --enable-windows-desktop
```

---

### Problem: Sinhala/Tamil text shows as boxes □□□

**Solution:**
This is usually fine - it means your device doesn't have those fonts. The app will still work, and most Android/iOS devices show them correctly.

---

## 📊 WHAT'S IN YOUR DATABASE NOW?

After completing setup, you have:

| Item | Count | Details |
|------|-------|---------|
| **Foods** | 70+ | Sri Lankan foods with full nutrition data |
| **Portions** | 100+ | Traditional Sri Lankan measurements |
| **Languages** | 3 | English, Sinhala (සිංහල), Tamil (தமிழ்) |
| **Categories** | 8 | Staples, Curries, Sambols, Mallums, Snacks, Fruits, Desserts, Beverages |
| **Nutrition Fields** | 20+ | Macros, micros, vitamins, minerals, GI values |

---

## 🍛 USING THE APP

### Features Available:

1. **Search Foods**
   - By name (English/Sinhala/Tamil)
   - By category
   - By GI value (diabetes-friendly)

2. **Build Meals**
   - Add multiple foods
   - Select portion sizes
   - See real-time calculations

3. **Get Recommendations**
   - Diabetes-friendly feedback
   - Cholesterol guidance
   - Portion adjustments

4. **View Nutrition**
   - Carbs, protein, fat, fiber
   - Calories
   - Vitamins & minerals
   - Glycemic Index

---

## 📚 HELPFUL GUIDES

After setup, check these guides:

1. **`database/FOODDB_GUIDE.md`**
   - Complete food database reference
   - How to add more foods
   - Search examples

2. **`database/DIABETES_FOOD_GUIDE.md`**
   - Diabetes-friendly food choices
   - Glycemic Index explained
   - Meal planning tips

3. **`database/INTEGRATION_SUMMARY.md`**
   - Technical details
   - Database statistics
   - Integration overview

4. **`README.md`**
   - Full project documentation
   - Feature list
   - Technical details

---

## 🎯 QUICK COMMAND REFERENCE

```powershell
# Navigate to project
cd C:\Users\kishor\Desktop\FinalResearchGlucoDietix\GlucoDietix

# Check if Flutter is ready
flutter doctor

# Install dependencies
flutter pub get

# Check connected devices
flutter devices

# Run the app
flutter run

# Clean build (if errors)
flutter clean
flutter pub get
flutter run

# Build release APK (for sharing)
flutter build apk

# Build Windows app
flutter build windows
```

---

## 🌟 NEXT STEPS AFTER SETUP

1. **Explore the food database**
   - Search for your favorite Sri Lankan foods
   - Check GI values for diabetes management

2. **Build sample meals**
   - Traditional Sri Lankan breakfast
   - Rice and curry meal
   - Snack combinations

3. **Add more foods** (Optional)
   - See `database/import_fooddb.py`
   - Follow `FOODDB_GUIDE.md`

4. **Customize the app** (Optional)
   - Modify colors in theme
   - Add more features
   - Contribute back!

---

## ✅ SUCCESS CHECKLIST

After completing this guide, you should have:

- [x] Supabase project created
- [x] Database schema loaded
- [x] 70+ Sri Lankan foods in database
- [x] 100+ portions available
- [x] App configured with credentials
- [x] App running on device
- [x] Able to search foods in 3 languages
- [x] Able to build and calculate meals
- [x] Able to see GI values and recommendations

---

## 🆘 STILL HAVING ISSUES?

1. **Check the error message carefully**
2. **Review the troubleshooting section above**
3. **Make sure all steps were followed exactly**
4. **Try the "clean build" commands**
5. **Check your internet connection**
6. **Verify Supabase credentials are correct**

**Common mistakes:**
- ❌ Using service_role key instead of anon public key
- ❌ Not running seed_data.sql
- ❌ Forgetting to save supabase_config.dart
- ❌ No device connected

---

## 🎉 CONGRATULATIONS!

If you've reached this point, you now have a **fully functional GlucoDietix app** with:

✅ Complete Sri Lankan food database (70+ foods)
✅ Multilingual support (English, Sinhala, Tamil)
✅ Diabetes-friendly features with GI values
✅ Traditional Sri Lankan portion sizes
✅ Real-time nutrition calculations
✅ Personalized health recommendations

**Enjoy using your app!**

**🍛 සුබ පැතුම්! (Good luck!)**
**🥗 வாழ்த்துக்கள்! (Congratulations!)**

---

## 📞 RESOURCES

- **Supabase Dashboard**: https://app.supabase.com
- **Flutter Documentation**: https://flutter.dev/docs
- **Food Database Source**: https://www.foodcompositiondb.lk
- **Project Files**:
  - Schema: `database/schema.sql`
  - Data: `database/seed_data.sql`
  - Config: `lib/config/supabase_config.dart`

---

**Last Updated**: March 8, 2026
**App Version**: 1.0.0
**Database Version**: Sri Lankan Food Composition DB v1.0
