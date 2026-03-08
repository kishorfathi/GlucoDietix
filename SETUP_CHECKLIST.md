# ✅ SETUP CHECKLIST - Print This!

**GlucoDietix with Sri Lankan Food Database - Setup Tracker**

---

## 📋 PART 1: SUPABASE DATABASE

### ☐ Step 1.1: Create Supabase Project
- [ ] Go to https://app.supabase.com
- [ ] Login/Sign up
- [ ] Click "New Project"
- [ ] Fill in details (save password!)
- [ ] Wait for project creation (2-3 min)

### ☐ Step 1.2: Load Schema
- [ ] Click "SQL Editor" (left sidebar)
- [ ] Click "New Query"
- [ ] Copy content from: `database/schema.sql`
- [ ] Paste in SQL Editor
- [ ] Click "Run"
- [ ] See: ✓ "Success. No rows returned"

### ☐ Step 1.3: Load Food Data
- [ ] Click "New Query" again
- [ ] Copy content from: `database/seed_data.sql`
- [ ] Paste in SQL Editor
- [ ] Click "Run"
- [ ] See: Results showing 70+ foods

### ☐ Step 1.4: Get Credentials (Optional - already in config)
- [ ] Click "Settings" → "API"
- [ ] Copy "Project URL"
- [ ] Copy "anon public" key
- [ ] Save somewhere safe

---

## 📱 PART 2: FLUTTER APP

### ☐ Step 2.1: Navigate to Project
```powershell
cd C:\Users\kishor\Desktop\FinalResearchGlucoDietix\GlucoDietix
```
- [ ] Opened terminal in VS Code
- [ ] Navigated to GlucoDietix folder
- [ ] Verified: `Test-Path pubspec.yaml` returns True

### ☐ Step 2.2: Install Dependencies
```powershell
flutter pub get
```
- [ ] Ran command
- [ ] Saw: "Got dependencies!"

### ☐ Step 2.3: Verify Config (Already Set!)
- [ ] Opened `lib/config/supabase_config.dart`
- [ ] Confirmed supabaseUrl is set
- [ ] Confirmed supabaseAnonKey is set
- [ ] (If needed, updated with Step 1.4 credentials)

### ☐ Step 2.4: Connect Device
**Choose one:**
- [ ] Android phone connected (USB debugging on)
- [ ] Android emulator running
- [ ] Windows desktop enabled

```powershell
flutter devices
```
- [ ] Ran command
- [ ] See at least one device listed

### ☐ Step 2.5: Run App
```powershell
flutter run
```
- [ ] Ran command
- [ ] Waited 2-3 minutes (first build)
- [ ] App installed on device
- [ ] App launched successfully!

---

## 🧪 PART 3: TESTING

### ☐ Test 3.1: Create Account
- [ ] Opened app
- [ ] Clicked "Register"
- [ ] Entered email and password
- [ ] Successfully registered
- [ ] Logged in

### ☐ Test 3.2: Set Profile
- [ ] Opened profile screen
- [ ] Selected health preferences
- [ ] Clicked "Save Profile"
- [ ] Profile saved successfully

### ☐ Test 3.3: Search Foods
- [ ] Searched "rice"
- [ ] Saw: White Rice, Red Rice, Kiri Bath
- [ ] Searched "hopper"
- [ ] Saw: String Hoppers, Plain Hopper, Egg Hopper
- [ ] Tried Sinhala search (optional)
- [ ] Tried Tamil search (optional)

### ☐ Test 3.4: Build Meal
- [ ] Added White Rice (1 cup)
- [ ] Added Dhal Curry (1/2 cup)
- [ ] Added Pol Sambol (1 tablespoon)
- [ ] Clicked "Calculate Results"
- [ ] Saw nutrition breakdown
- [ ] Saw OK/Not OK feedback
- [ ] Saw recommendations (if any)

### ☐ Test 3.5: Check Multilingual
- [ ] Verified foods show English names
- [ ] Verified Sinhala names display (සිංහල)
- [ ] Verified Tamil names display (தமிழ்)

### ☐ Test 3.6: Check GI Values
- [ ] Found a food with GI value
- [ ] Verified diabetes-friendly indicator
- [ ] Checked low GI foods (≤55)

---

## ✅ VERIFICATION

### Database Check
```sql
-- Run in Supabase SQL Editor
SELECT COUNT(*) FROM foods;
-- Expected: 70+
```
- [ ] Foods count is 70+

```sql
SELECT COUNT(*) FROM portions;
-- Expected: 100+
```
- [ ] Portions count is 100+

```sql
SELECT COUNT(DISTINCT category) FROM foods;
-- Expected: 8
```
- [ ] Categories count is 8

### App Check
- [ ] App compiles without errors
- [ ] App runs on device
- [ ] Can register/login
- [ ] Can search foods
- [ ] Can add foods to meal
- [ ] Can see calculations
- [ ] Multilingual names show
- [ ] GI values visible

---

## 🎉 SUCCESS!

**If all boxes are checked, you have:**

✅ Working Supabase database with schema
✅ 70+ Sri Lankan foods loaded
✅ 100+ traditional portion sizes
✅ Multilingual support (EN, SI, TA)
✅ Complete nutritional data
✅ Glycemic Index values
✅ Working Flutter app
✅ App connected to database
✅ All features functional

---

## 📞 IF STUCK

**Quick Fixes:**
```powershell
# Clean rebuild
flutter clean
flutter pub get
flutter run

# Check devices
flutter devices

# Verify database
# Go to Supabase → SQL Editor → Run:
SELECT COUNT(*) FROM foods;
```

**Documentation:**
- Quick Start: `QUICK_START.md`
- Full Setup: `SETUP_GUIDE.md`
- Food Database: `database/FOODDB_GUIDE.md`
- Diabetes Guide: `database/DIABETES_FOOD_GUIDE.md`
- Main Docs: `README.md`

---

## ⏱️ TIME TRACKER

**Estimated Times:**
- Part 1 (Supabase): 5-7 minutes
- Part 2 (Flutter): 3-5 minutes
- Part 3 (Testing): 3-5 minutes
- **Total: 11-17 minutes**

**Your actual time:**
- Started: ____________
- Finished: ____________
- Total: ____________

---

## 📝 NOTES

**Issues encountered:**
_____________________________________
_____________________________________
_____________________________________

**Solutions:**
_____________________________________
_____________________________________
_____________________________________

**Custom changes:**
_____________________________________
_____________________________________
_____________________________________

---

**Version:** 1.0.0 | **Date:** March 8, 2026
**Database:** Sri Lankan Food Composition DB v1.0
**Source:** https://www.foodcompositiondb.lk

**🍛 සුභ පැතුම්! 🥗 வாழ்த்துக்கள்! 🎉 Good Luck!**
