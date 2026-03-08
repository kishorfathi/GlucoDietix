# 🔧 TROUBLESHOOTING GUIDE

**Common issues and solutions for GlucoDietix setup**

---

## 🗄️ SUPABASE DATABASE ISSUES

### Issue: "Success. No rows returned" after running schema.sql ✅
**Status:** This is CORRECT! It means the schema was created successfully.
**Action:** Continue to next step (load seed_data.sql)

---

### Issue: "relation 'foods' already exists"
**Cause:** You've already run the schema before
**Solution:**
```sql
-- Option 1: Drop and recreate
DROP TABLE IF EXISTS portions CASCADE;
DROP TABLE IF EXISTS foods CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;

-- Then re-run the entire schema.sql file
```

**OR**

```sql
-- Option 2: Just load the data
-- Skip schema.sql and go straight to seed_data.sql
```

---

### Issue: "No foods showing" after seed_data.sql
**Diagnosis:**
```sql
-- Check if foods were loaded
SELECT COUNT(*) FROM foods;
```

**If count is 0:**
1. Re-run `seed_data.sql` completely
2. Make sure you copied the ENTIRE file
3. Check for SQL errors in the output

**If count is 70+:**
- Foods are loaded correctly!
- Problem is in the app, not database

---

### Issue: "permission denied for table foods"
**Cause:** Row Level Security (RLS) policies not set up
**Solution:**
```sql
-- Enable RLS
ALTER TABLE foods ENABLE ROW LEVEL SECURITY;

-- Create read policy for everyone
CREATE POLICY "Foods are viewable by everyone"
  ON foods FOR SELECT
  USING (true);

-- Do the same for portions
ALTER TABLE portions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Portions are viewable by everyone"
  ON portions FOR SELECT
  USING (true);
```

---

### Issue: Can't find SQL Editor in Supabase
**Location:** Left sidebar → Look for icon that looks like `</>`
**Alternative:** Click "Database" → "SQL Editor"

---

## 📱 FLUTTER APP ISSUES

### Issue: "flutter: command not found"
**Cause:** Flutter not installed or not in PATH
**Solution:**
```powershell
# Check if Flutter is installed
where flutter

# If not found, download from:
# https://docs.flutter.dev/get-started/install/windows

# After install, verify:
flutter --version
```

---

### Issue: "pubspec.yaml not found"
**Cause:** Wrong directory
**Solution:**
```powershell
# Navigate to correct directory
cd C:\Users\kishor\Desktop\FinalResearchGlucoDietix\GlucoDietix

# Verify you're in the right place
Test-Path pubspec.yaml
# Should return: True

# If False, you're in the wrong directory
```

---

### Issue: "flutter pub get" fails
**Common errors and solutions:**

**Error: "version solving failed"**
```powershell
# Clear cache
flutter pub cache clean
flutter pub get
```

**Error: "Could not resolve dependencies"**
```powershell
# Update Flutter
flutter upgrade
flutter pub get
```

**Error: "pubspec.yaml has errors"**
- Open `pubspec.yaml`
- Check indentation (must use spaces, not tabs)
- Ensure all dependencies are properly formatted

---

### Issue: "Invalid API credentials" or "Invalid JWT"
**Cause:** Wrong Supabase credentials or formatting issues

**Solution 1: Verify credentials**
1. Go to Supabase Dashboard → Settings → API
2. Make sure you copied the **anon public** key
   - ✅ Starts with: `eyJhbGci...`
   - ❌ NOT the service_role key!
3. Copy the **Project URL**
   - ✅ Format: `https://yourproject.supabase.co`

**Solution 2: Check config file**
```dart
// In lib/config/supabase_config.dart
// Make sure format is EXACTLY like this:

static const String supabaseUrl = 'https://hondqqvhuzcxajehzrlo.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

// Common mistakes:
// ❌ Extra spaces: ' https://... '
// ❌ Missing quotes: https://...
// ❌ Wrong quotes: "https://..." instead of 'https://...'
// ❌ Missing semicolon at end
```

**Solution 3: Restart app**
```powershell
# Stop the app (Ctrl+C in terminal)
# Run again
flutter run
```

---

### Issue: "No devices found"
**Diagnosis:**
```powershell
flutter devices
```

**If empty list:**

**For Android Phone:**
1. Check USB cable is connected properly
2. Check Developer Options is enabled
3. Check USB Debugging is ON
4. Unplug and replug cable
5. Accept "Allow USB Debugging" on phone

**For Android Emulator:**
1. Open Android Studio
2. Click Device Manager
3. Click Play button on an emulator
4. Wait for it to fully boot (2-3 min)
5. Run `flutter devices` again

**For Windows Desktop:**
```powershell
flutter config --enable-windows-desktop
flutter devices
```

---

### Issue: "Gradle build failed" (Android)
**Solution 1: Clear build cache**
```powershell
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

**Solution 2: Check Java version**
```powershell
java --version
# Should be Java 11 or higher
```

**Solution 3: Update Gradle**
```powershell
cd android
./gradlew wrapper --gradle-version=7.5
cd ..
flutter run
```

---

### Issue: "Could not find or load main class org.gradle.wrapper.GradleWrapperMain"
**Solution:**
```powershell
cd android
# Download gradle wrapper
powershell -Command "Invoke-WebRequest -Uri 'https://services.gradle.org/distributions/gradle-7.5-bin.zip' -OutFile 'gradle.zip'"
# Extract it
Expand-Archive gradle.zip -DestinationPath .
cd ..
flutter run
```

---

### Issue: App builds but crashes on startup
**Check these:**

**1. Supabase initialization**
```dart
// In main.dart, make sure you have:
await Supabase.initialize(
  url: SupabaseConfig.supabaseUrl,
  anonKey: SupabaseConfig.supabaseAnonKey,
);
```

**2. Check console for errors**
- Look at the terminal output when app crashes
- Copy the error message
- Search for it in the code

**3. Network permissions** (Android)
```xml
<!-- In android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## 🔍 DATA & SEARCH ISSUES

### Issue: "No foods found" when searching
**Diagnosis:**
```dart
// In Supabase SQL Editor:
SELECT COUNT(*) FROM foods;
```

**If 0:** Re-load seed_data.sql

**If 70+:** 

**Check 1: Search implementation**
- Try searching with exact name: "White Rice (Cooked)"
- Try category search: category = "Staples"

**Check 2: RLS Policies**
```sql
-- Make sure this policy exists:
SELECT * FROM pg_policies WHERE tablename = 'foods';

-- If empty, run:
CREATE POLICY "Foods are viewable by everyone"
  ON foods FOR SELECT
  USING (true);
```

---

### Issue: Sinhala/Tamil text shows as boxes (□□□)
**Status:** This is NORMAL on some devices

**Why it happens:**
- Device doesn't have Sinhala/Tamil fonts installed
- Emulators often don't have these fonts

**Is it a problem?**
- ❌ No! The app still works perfectly
- ✅ Most modern Android/iOS devices show them correctly
- ✅ Database still contains the correct text

**To test:**
```sql
-- In Supabase SQL Editor:
SELECT name, name_sinhala, name_tamil 
FROM foods 
WHERE name = 'White Rice (Cooked)';

-- If you see the Sinhala/Tamil text here, it's stored correctly!
```

---

### Issue: GI (Glycemic Index) values are NULL
**Check:**
```sql
SELECT name, glycemic_index 
FROM foods 
WHERE glycemic_index IS NOT NULL;
```

**If empty:**
- Re-run `seed_data.sql`
- Make sure you used the UPDATED version from this integration

**If showing values:**
- Values are in database
- Issue is in app display code

---

## 🎨 UI/DISPLAY ISSUES

### Issue: App looks different than expected
**Possible causes:**
1. Running in debug mode (has debug banner)
2. Different screen size
3. Theme not loading

**Solutions:**
```powershell
# Build release version to see final look
flutter build apk --release

# Or run in profile mode
flutter run --profile
```

---

### Issue: Images not loading
**For food images:**
- Current version doesn't have food images
- Only scanned plate images (camera feature)

**For camera/scan feature:**
```xml
<!-- Make sure AndroidManifest.xml has: -->
<uses-permission android:name="android.permission.CAMERA"/>
```

---

## 🔐 AUTHENTICATION ISSUES

### Issue: Can't register new account
**Check 1: Email confirmation**
- Supabase → Authentication → Settings
- Check if "Enable email confirmations" is OFF for testing

**Check 2: Password requirements**
- Minimum 6 characters
- Try a simple password for testing: `test1234`

**Check 3: Email format**
- Must be valid format: `user@example.com`

---

### Issue: Can't login
**Solutions:**
1. Make sure you registered first
2. Check email/password are correct
3. Try "Forgot Password" flow

**Reset in Supabase:**
- Authentication → Users
- Find your user
- Click "..." → Reset password

---

### Issue: "User already registered" error
**Cause:** Email already in database

**Solution 1:** Login with that email

**Solution 2:** Use different email

**Solution 3:** Delete user from Supabase
- Authentication → Users
- Find and delete user
- Try registering again

---

## 💾 DATABASE CONNECTION ISSUES

### Issue: "Failed to fetch" or network errors
**Check:**
1. Internet connection is working
2. Firewall isn't blocking Supabase
3. Supabase project is running (check dashboard)

**Solution:**
```powershell
# Test connection
curl https://hondqqvhuzcxajehzrlo.supabase.co/rest/v1/

# Should return something, not timeout
```

---

### Issue: "Too many requests" error
**Cause:** Exceeded free tier limits

**Check limits:**
- Supabase Dashboard → Settings → Usage
- Free tier: 500MB database, 2GB bandwidth/month

**Solution:**
- Wait for limits to reset (monthly)
- Upgrade to paid plan
- Optimize queries

---

## 📊 CALCULATION/LOGIC ISSUES

### Issue: Nutrition calculations seem wrong
**Debug:**
```dart
// Check the raw data
SELECT name, carbs_100g, protein_100g, fat_100g, energy_kcal
FROM foods
WHERE name = 'White Rice (Cooked)';

// Expected results:
// carbs_100g: 28.2
// protein_100g: 2.7
// fat_100g: 0.3
// energy_kcal: 130
```

**Formula check:**
```
For 195g (1 cup) of White Rice:
carbs = 28.2 × (195/100) = 54.99g
protein = 2.7 × (195/100) = 5.27g
```

---

### Issue: "OK/Not OK" feedback always shows "Not OK"
**Check profile settings:**
- Profile → Glucose Range
- If "High" → target is 45g carbs
- If "Normal/Low" → target is 60g carbs

**Check meal:**
- Add up total carbs from all foods
- If > target → "Not OK"
- If ≤ target → "OK"

---

## 🛠️ GENERAL DEBUGGING

### Enable Debug Logs
```dart
// In main.dart
void main() {
  // Add before runApp
  debugPrint('App starting...');
  
  runApp(MyApp());
}
```

### Check Flutter Doctor
```powershell
flutter doctor -v

# Should show:
# ✓ Flutter
# ✓ Android toolchain
# ✓ Chrome (for web)
# ✓ VS Code
```

### Clear Everything and Start Fresh
```powershell
# Nuclear option - if nothing else works
flutter clean
cd android
./gradlew clean
cd ..
flutter pub cache clean
flutter pub get
flutter run
```

---

## 📞 STILL STUCK?

### Collect Information
1. **Error message** (exact text)
2. **When it happens** (during what step)
3. **Flutter version:** `flutter --version`
4. **Device:** Physical phone/Emulator/Windows
5. **Supabase project status:** Dashboard → Health

### Check Documentation
- `SETUP_GUIDE.md` - Detailed setup
- `QUICK_START.md` - Quick reference
- `README.md` - Full documentation
- `database/FOODDB_GUIDE.md` - Database info

### Common Solutions Summary
```powershell
# 90% of issues solved by:
flutter clean
flutter pub get
flutter run

# OR

# Re-run database scripts in Supabase
# (schema.sql + seed_data.sql)

# OR

# Check credentials in:
# lib/config/supabase_config.dart
```

---

## ✅ VERIFICATION CHECKLIST

**Before reporting an issue, verify:**
- [ ] Ran `flutter doctor` - no errors
- [ ] Ran `flutter pub get` - successful
- [ ] Database has 70+ foods (`SELECT COUNT(*) FROM foods;`)
- [ ] Credentials are correct in `supabase_config.dart`
- [ ] Using **anon public** key, not service_role
- [ ] Device is connected (`flutter devices`)
- [ ] Internet connection is working
- [ ] Tried `flutter clean` + rebuild

---

**Last Updated:** March 8, 2026
**Version:** 1.0.0
**For:** GlucoDietix with Sri Lankan Food Database
