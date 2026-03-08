# 🚀 QUICK START - GlucoDietix with Sri Lankan Food Database

## ⚡ 5-Minute Setup Guide

**Your app is already configured! Follow these steps to load the database and run:**

---

## ✅ STEP 1: Load Database Schema (2 minutes)

1. **Go to:** https://app.supabase.com
2. **Login** and select your project
3. **Click** "SQL Editor" (left sidebar)
4. **Click** "New Query"
5. **Open file:** `database/schema.sql` in VS Code
6. **Copy ALL content** (Ctrl+A, then Ctrl+C)
7. **Paste** into Supabase SQL editor (Ctrl+V)
8. **Click** "Run" button (bottom right)
9. **Wait** for: ✅ "Success. No rows returned"

**✅ Database structure created!**

**Note:** If you've run this before and get policy errors, that's OK! The schema is now safe to re-run multiple times. It will update existing structures without errors.

**If you want to start completely fresh:**
- Run `database/cleanup.sql` first
- Then run `database/schema.sql`

---

## ✅ STEP 2: Load Sri Lankan Food Data (2 minutes)

1. **In SQL Editor**, click "New Query"
2. **Open file:** `database/seed_data.sql` in VS Code
3. **Copy ALL content** (Ctrl+A, then Ctrl+C)
4. **Paste** into Supabase SQL editor (Ctrl+V)
5. **Click** "Run" button
6. **Wait** ~30 seconds
7. **See results** showing:
   ```
   Total Foods: 70+
   Total Portions: 100+
   Categories: 8
   ```

**✅ 70+ Sri Lankan foods loaded!**

**What you now have:**
- Rice varieties (White, Red, Kiri Bath)
- Hoppers (String, Plain, Egg)
- Curries (Dhal, Chicken, Fish, Vegetable)
- Sambols (Pol, Seeni, Lunumiris)
- Mallums (Gotukola, Mukunuwenna)
- Snacks (Wade, Samosa, Cutlet)
- Fruits, Desserts, Beverages
- All with Sinhala (සිංහල) & Tamil (தமிழ்) names!

---

## ✅ STEP 3: Install Dependencies (30 seconds)

**Open Terminal in VS Code** and run:

```powershell
cd C:\Users\kishor\Desktop\FinalResearchGlucoDietix\GlucoDietix
flutter pub get
```

**Wait for:** "Got dependencies!" ✅

---

## ✅ STEP 4: Verify Supabase Connection (30 seconds)

**Your credentials are already set!**

To verify, check this file:
```
lib/config/supabase_config.dart
```

You should see:
```dart
static const String supabaseUrl = 'https://hondqqvhuzcxajehzrlo.supabase.co';
static const String supabaseAnonKey = 'eyJhbGci...';
```

**If different project**, update with your credentials from:
Supabase → Settings → API

**✅ Credentials configured!**

---

## ✅ STEP 5: Connect Device (30 seconds)

**Choose ONE option:**

### Option A: Android Phone
1. Go to Settings → About Phone
2. Tap "Build Number" 7 times
3. Settings → Developer Options → Enable "USB Debugging"
4. Connect via USB cable
5. Approve prompt on phone

### Option B: Android Emulator
1. Open Android Studio
2. Click "Device Manager"
3. Start an emulator
4. Wait for it to boot

### Option C: Windows Desktop
```powershell
flutter config --enable-windows-desktop
```

**Verify:**
```powershell
flutter devices
```
Should see at least one device ✅

---

## ✅ STEP 6: RUN THE APP! 🚀

```powershell
flutter run
```

**What happens:**
- First build: 2-3 minutes ⏳
- App installs automatically
- App launches! 🎉

**✅ APP IS RUNNING!**

---

## 🎮 TEST THE APP (2 minutes)

### 1. Create Account
```
Tap "Register"
Email: test@example.com
Password: test1234
Tap "Sign Up"
```

### 2. Set Profile
```
Choose: Diabetes Yes/No
Choose: Glucose Range
Choose: Cholesterol Concern
Tap "Save Profile"
```

### 3. Search Sri Lankan Foods
**Try these searches:**
- `rice` → See White Rice, Red Rice, Kiri Bath
- `hopper` → See String Hoppers, Plain Hopper, Egg Hopper
- `කරිය` → See curries in Sinhala!
- `சாதம்` → See rice in Tamil!
- `sambol` → See Pol Sambol, Seeni Sambol

### 4. Build a Sample Meal
```
1. Search "rice" → Add "White Rice" → "1 cup"
2. Search "dhal" → Add "Dhal Curry" → "1/2 cup"
3. Search "sambol" → Add "Pol Sambol" → "1 tablespoon"
4. Tap "Calculate Results"
5. See nutrition breakdown!
```

**✅ Everything working!**

---

## 🍛 WHAT'S IN YOUR DATABASE

After setup, you have access to:

### Staples (බාල ආහාර / பிரதான உணவு)
- White Rice, Red Rice, Kiri Bath
- String Hoppers, Plain Hopper, Egg Hopper
- Pol Roti, Gotukola Roti, Plain Roti
- Pittu, Kurakkan Pittu
- White Bread, Brown Bread

### Curries (ව්‍යඤ්ජන / கறிகள்)
- Dhal, Potato, Pumpkin, Jackfruit
- Brinjal, Green Bean, Cabbage, Carrot
- Chicken, Fish, Egg, Dried Fish
- Beef, Pork, Prawn, Crab

### Sambols & Mallums (සම්බෝල / சாம்பல்)
- Pol Sambol, Seeni Sambol, Lunumiris, Katta Sambol
- Gotukola Sambol, Gotukola Mallum, Mukunuwenna Mallum

### Snacks (කෑම වර්ග / சிற்றுண்டிகள்)
- Wade, Samosa, Cutlet, Rolls
- Kokis, Aluwa

### Fruits (පලතුරු / பழங்கள்)
- Banana, Papaya, Mango, Pineapple
- Watermelon, Guava, Wood Apple, King Coconut

### Desserts & Beverages
- Watalappan, Kiri Peni, Kavum
- Plain Tea, Milk Tea, Faluda

**Total: 70+ foods with complete nutrition data!**

---

## 🔧 TROUBLESHOOTING

### Problem: "Invalid API credentials"
**Solution:**
- Check `lib/config/supabase_config.dart`
- Verify you used **anon public** key (not service_role)
- Remove any extra spaces

### Problem: "No foods found"
**Solution:**
- Re-run `database/seed_data.sql` in Supabase
- Check: `SELECT COUNT(*) FROM foods;` should be 70+

### Problem: Build fails
**Solution:**
```powershell
flutter clean
flutter pub get
flutter run
```

### Problem: No device found
**Solution:**
- Android: Check USB debugging enabled
- Emulator: Make sure it's running
- Windows: Run `flutter config --enable-windows-desktop`

### Problem: Sinhala/Tamil shows as boxes
**Solution:**
- This is normal on some devices
- Most modern phones display correctly
- App still works fine

---

## 📚 ADDITIONAL GUIDES

For more detailed information:

1. **`SETUP_GUIDE.md`** - Complete step-by-step setup (20 pages!)
2. **`database/FOODDB_GUIDE.md`** - Food database reference
3. **`database/DIABETES_FOOD_GUIDE.md`** - Diabetes meal planning
4. **`README.md`** - Full project documentation

---

## 🎯 QUICK COMMANDS

```powershell
# Navigate to project
cd C:\Users\kishor\Desktop\FinalResearchGlucoDietix\GlucoDietix

# Install dependencies
flutter pub get

# Check devices
flutter devices

# Run app
flutter run

# Clean build (if errors)
flutter clean
flutter pub get
flutter run

# Build release APK
flutter build apk
```

---

## ✅ SUCCESS CHECKLIST

After completing this guide:

- [x] Supabase database loaded with schema
- [x] 70+ Sri Lankan foods in database
- [x] 100+ portions with Sri Lankan measurements
- [x] App credentials configured
- [x] Dependencies installed
- [x] Device connected
- [x] App running successfully
- [x] Can search foods in 3 languages
- [x] Can build and calculate meals
- [x] Can see GI values and recommendations

---

## 🎉 CONGRATULATIONS!

You now have a fully working **GlucoDietix app** with:

✅ **70+ Sri Lankan foods** (White Rice, Hoppers, Curries, Sambols...)
✅ **Multilingual** (English, සිංහල, தமிழ்)
✅ **Complete nutrition** (Macros, micros, vitamins, GI values)
✅ **Traditional portions** (1 cup rice, 2 hoppers, 1 tablespoon sambol)
✅ **Diabetes features** (Glycemic Index, carb tracking, recommendations)
✅ **Personalized** (Profile-based suggestions)

---

## 📱 APP FEATURES

- ✅ Search foods by name (any language)
- ✅ Filter by category (Staples, Curries, etc.)
- ✅ Find low-GI foods for diabetes
- ✅ Select traditional portion sizes
- ✅ Build complete meals
- ✅ Get real-time calculations
- ✅ Receive personalized recommendations
- ✅ Track carbs, protein, fat, fiber, calories
- ✅ See vitamin and mineral content
- ✅ Check glycemic index values

---

## 🚀 NEXT STEPS

1. **Explore the database** - Try searching different foods
2. **Build sample meals** - Traditional breakfast, rice & curry
3. **Check GI values** - Find diabetes-friendly options
4. **Read the guides** - Learn about meal planning
5. **Customize** - Add your own favorite foods

---

## 🆘 NEED MORE HELP?

**For detailed explanations:**
- See `SETUP_GUIDE.md` (comprehensive 20-page guide)

**For food database:**
- See `database/FOODDB_GUIDE.md`

**For diabetes planning:**
- See `database/DIABETES_FOOD_GUIDE.md`

**For technical details:**
- See `README.md`

---

**Total Setup Time:** ~5 minutes
**Database Source:** https://www.foodcompositiondb.lk
**Foods Available:** 70+ (expandable to 243)

**🍛 සුභ පැතුම්!** (Good luck!)
**🥗 வாழ்த்துக்கள்!** (Congratulations!)

---

**Last Updated:** March 8, 2026 | **Version:** 1.0.0
2. Click "Insert row" manually and add a test food

### Phone not detected

1. Unplug and replug USB cable
2. On phone, tap "Transfer files" (not "Charge only")
3. Run: `flutter devices` again

### App crashes immediately

1. Check internet connection (app needs internet)
2. Verify Supabase credentials are correct
3. Check terminal for error message

---

## 🎓 WHAT YOU JUST BUILT

You now have a fully functional app with:
- ✅ User registration & login (Supabase Auth)
- ✅ User profiles with health data
- ✅ Sri Lankan food database
- ✅ Meal builder with portion selection
- ✅ Smart carb calculator with recommendations
- ✅ Camera integration for plate scanning
- ✅ AR view integration (WebVR ready)

**Total Time: ~20 minutes** ⚡

---

## 📚 NEXT: Read the Full README

For troubleshooting, customization, and advanced features, see: [README.md](README.md)

---

**You did it! 🎉 Happy coding!**
